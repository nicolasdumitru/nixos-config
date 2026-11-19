"""Log what powers up the NVIDIA GPU and what keeps it on.

Sends a desktop notification, while on battery, when:
- something wakes the GPU (at most once per program every few minutes);
- the GPU stays on longer than an idle wake-up keeps it on;
- a program keeps waking it, which a program using the GPU for real does not
  do: it wakes it once and keeps it busy.

The kernel reports power management requests for a device through trace
events, together with the process that made them: `rpm_resume` for each
wake-up request, and `rpm_usage` each time a process takes or releases a hold
that keeps the device on. The monitor sleeps on the wake-up requests, so it
costs nothing while the GPU is off, and it never queries the GPU itself (which
would wake it). While the GPU is on, it also follows the holds, and checks
every two seconds whether the GPU has powered down again.

Kernel threads have no command line to tell them apart, so for those the
monitor also logs the kernel functions that made the request.
"""

import os
import re
import select
import subprocess
import sys
import time
from collections import defaultdict, deque
from dataclasses import dataclass, field
from pathlib import Path

TRACING = Path(os.environ.get("GPU_MONITOR_TRACING", "/sys/kernel/tracing"))
PCI = Path(os.environ.get("GPU_MONITOR_PCI", "/sys/bus/pci/devices"))
POWER = Path(os.environ.get("GPU_MONITOR_POWER", "/sys/class/power_supply"))
RUNTIME = Path(os.environ.get("GPU_MONITOR_RUNTIME", "/run/user"))
PROC = Path(os.environ.get("GPU_MONITOR_PROC", "/proc"))

INSTANCE = TRACING / "instances" / "gpu-monitor"
EVENTS = INSTANCE / "events" / "rpm"

# Seconds between two checks of whether the GPU is still on.
POLL_INTERVAL = 2
# Seconds without a request after which a burst of requests is over.
BURST_QUIET = 1
# Requests within one check interval above which following them would cost
# more than it is worth; the GPU is plainly in heavy use by then.
FLOOD = 5000
# Processes listed when the GPU powers down.
SUMMARY_SIZE = 8
# Kernel functions logged for a request from a kernel thread.
STACK_DEPTH = 16

# Seconds the GPU stays on after a brief use: the driver keeps it on for
# about 22 seconds after the last request.
LONG_ON = 60
# A program that wakes the GPU this many times within the window keeps waking
# it, rather than using it.
REPEAT_WAKES = 3
REPEAT_WINDOW = 600
# Seconds before the same notification is sent again for the same program.
WAKE_COOLDOWN = 600
REPEAT_COOLDOWN = 1800

# How long a notification stays on screen, in milliseconds; 0 keeps it until
# it is dismissed. Without one, COSMIC shows it for 3 seconds.
NOTIFY_TIMEOUT = 15000

# Ends every notification, which names programs only: process IDs and
# command lines are in the log.
LOG_HINT = (
    "Process IDs and command lines are in the log. "
    "To see it, run: journalctl -u gpu-monitor -e"
)

# Kernel functions behind expected wake-ups, which are only logged.
KNOWN_KERNEL_CAUSES = {
    # The firmware tells the NVIDIA driver about every change of the battery
    # level (and other platform power events), and the driver wakes the GPU
    # to pass it on to nvidia-powerd for Dynamic Boost.
    "rm_acpi_nvpcf_notify": "firmware power event (battery level changed)",
}

# Set in /proc/<pid>/stat for kernel threads.
PF_KTHREAD = 0x00200000

# A trace line looks like:
#   nvidia-smi-12345 [003] ..... 123.456: rpm_resume: 0000:65:00.0 flags-4 ...
# and a stack trace, recorded after a `rpm_resume` line, like:
#   kworker/3:1-219 [003] ..... 123.456: <stack trace>
#    => rpm_resume
#    => __pm_runtime_resume
TRACE_LINE = re.compile(
    r"^\s*(?P<comm>.+)-(?P<pid>\d+)\s+\[\d+\].*rpm_(?:resume|usage): "
)
STACK_START = re.compile(r"^\s*.+-\d+\s+\[\d+\].*: <stack trace>")
STACK_FRAME = re.compile(r"^\s*=> (?P<function>[^+\s]+)")


def log(message):
    print(message, flush=True)


def read(path):
    return path.read_text().strip()


def find_devices():
    """NVIDIA display controllers and the other functions of the same card.

    The card's HDMI audio device counts too: waking it powers the card up.
    """
    devices = []
    for device in sorted(PCI.iterdir()):
        is_nvidia = read(device / "vendor") == "0x10de"
        if is_nvidia and read(device / "class").startswith("0x03"):
            card = device.name.rsplit(".", 1)[0]
            devices += sorted(PCI.glob(f"{card}.*"))
    return devices


def gpu_awake(devices):
    return any(
        read(device / "power" / "runtime_status") != "suspended" for device in devices
    )


def on_battery():
    for supply in POWER.iterdir():
        if read(supply / "type") == "Battery":
            continue
        online = supply / "online"
        if online.exists() and read(online) == "1":
            return False
    return True


def is_kernel_thread(comm, pid):
    try:
        stat = (PROC / pid / "stat").read_text()
    except OSError:
        # Gone already; kernel workers are the ones that come and go.
        return comm.startswith("kworker/")
    flags = int(stat.rsplit(")", 1)[1].split()[6])
    return bool(flags & PF_KTHREAD)


def command_line(pid):
    try:
        raw = (PROC / pid / "cmdline").read_bytes()
    except OSError:
        return []
    # The arguments are separated by null bytes, which a notification's text
    # cannot contain.
    return [arg for arg in raw.decode(errors="replace").split("\0") if arg]


def program_name(pid, args, comm):
    """The program's name, from its executable rather than its arguments.

    Chromium and Electron programs rewrite their command line into a single
    argument containing spaces, so the first argument is not a path.
    """
    try:
        name = (PROC / pid / "exe").readlink().name
    except OSError:
        name = Path(args[0].split()[0]).name if args else comm
    # Nix wraps programs as `.name-wrapped`.
    if name.startswith(".") and name.endswith("-wrapped"):
        name = name[1 : -len("-wrapped")]
    return name


@dataclass
class Requester:
    """A process that asked for the GPU while it was on, or to turn it on."""

    comm: str
    pid: str
    kernel: bool
    # The program, the same across its runs: what repeated wake-ups count.
    program: str
    description: str
    requests: int = 0
    last: float = 0.0
    # Distinct chains of kernel functions that made the requests.
    stacks: list = field(default_factory=list)

    @classmethod
    def identify(cls, comm, pid):
        kernel = is_kernel_thread(comm, pid)
        args = [] if kernel else command_line(pid)
        program = "kernel" if kernel else program_name(pid, args, comm)
        description = f"{comm} (pid {pid})"
        if args:
            description += ": " + " ".join(" ".join(args).split())[:200]
        return cls(comm, pid, kernel, program, description)


class Requesters:
    """The processes seen in the trace since the GPU was last off."""

    def __init__(self):
        self.by_process = {}
        self.first = None
        self.last_added = None
        # The requester whose stack trace is being read, if any.
        self.stack_of = None
        self.stack = []

    def add(self, line):
        """Record a trace line; return the requester if it is a new one."""
        if self.stack_of is not None:
            frame = STACK_FRAME.match(line)
            if frame:
                if len(self.stack) < STACK_DEPTH:
                    self.stack.append(frame["function"])
                return None
            self.end_stack()

        if STACK_START.match(line):
            # Belongs to the request just before it.
            self.stack_of = self.last_added
            self.stack = []
            return None

        match = TRACE_LINE.match(line)
        if not match:
            return None
        key = (match["comm"], match["pid"])
        requester = self.by_process.get(key)
        is_new = requester is None
        if is_new:
            requester = Requester.identify(*key)
            self.by_process[key] = requester
            if self.first is None:
                self.first = requester
        requester.requests += 1
        requester.last = time.monotonic()
        self.last_added = requester
        return requester if is_new else None

    def end_stack(self):
        requester = self.stack_of
        stack = tuple(self.stack)
        if requester and requester.kernel and stack and stack not in requester.stacks:
            requester.stacks.append(stack)
        self.stack_of = None

    def known_cause(self):
        """What made the first request, if it is an expected kernel request."""
        self.end_stack()
        if self.first is None or not self.first.kernel:
            return None
        for stack in self.first.stacks:
            for function, cause in KNOWN_KERNEL_CAUSES.items():
                if function in stack:
                    return cause
        return None

    def names(self):
        return "; ".join(r.description for r in self.by_process.values())

    def programs(self, recent_first=False):
        """The programs that made requests, named for a notification."""
        requesters = list(self.by_process.values())
        if recent_first:
            requesters.sort(key=lambda r: -r.last)
        names = []
        for requester in requesters:
            name = "the kernel" if requester.kernel else requester.program
            if name not in names:
                names.append(name)
        # The kernel also carries out the programs' requests; it is worth
        # naming only when no program asked.
        if len(names) > 1 and "the kernel" in names:
            names.remove("the kernel")
        if not names:
            return "an unknown program"
        if len(names) == 1:
            return names[0]
        return ", ".join(names[:-1]) + " and " + names[-1]

    def summary(self, now):
        """The most recent requesters first: they are what kept the GPU on."""
        recent = sorted(self.by_process.values(), key=lambda r: -r.last)
        parts = [
            f"{r.description} [{r.requests} requests, "
            f"last {now - r.last:.0f}s before]"
            for r in recent[:SUMMARY_SIZE]
        ]
        if len(recent) > SUMMARY_SIZE:
            parts.append(f"and {len(recent) - SUMMARY_SIZE} more")
        return "; ".join(parts)

    def kernel_stacks(self):
        """Each distinct chain of kernel functions, innermost first."""
        self.end_stack()
        seen = set()
        for requester in self.by_process.values():
            for stack in requester.stacks:
                if stack not in seen:
                    seen.add(stack)
                    yield requester, stack


class Notifier:
    """Sends desktop notifications to every logged-in user."""

    def __init__(self):
        self.last = {}

    def send(self, kind, program, cooldown, title, body):
        """Notify, unless this was sent for this program within `cooldown`."""
        now = time.monotonic()
        last = self.last.get((kind, program))
        if last is not None and now - last < cooldown:
            log(f"not notifying ({kind}, {program}): sent {now - last:.0f}s ago")
            return
        body = f"{body}\n\n{LOG_HINT}"
        self.last[(kind, program)] = now
        for bus in RUNTIME.glob("*/bus"):
            if not bus.is_socket():
                continue
            owner = bus.stat()
            try:
                subprocess.run(
                    [
                        "notify-send",
                        "--urgency=critical",
                        f"--expire-time={NOTIFY_TIMEOUT}",
                        "--app-name=GPU monitor",
                        "--icon=battery-caution",
                        title,
                        body,
                    ],
                    env={
                        "PATH": os.environ.get("PATH", ""),
                        "DBUS_SESSION_BUS_ADDRESS": f"unix:path={bus}",
                    },
                    user=owner.st_uid,
                    group=owner.st_gid,
                    extra_groups=[],
                    timeout=10,
                    check=False,
                )
            except (OSError, subprocess.SubprocessError, ValueError) as error:
                log(f"could not notify uid {owner.st_uid}: {error}")


class TracePipe:
    """Reads lines from the trace pipe, optionally with a timeout."""

    def __init__(self, path):
        self.fd = os.open(path, os.O_RDONLY)
        self.buffer = b""

    def readline(self, timeout=None):
        """Return the next line, or None if none arrives within `timeout`."""
        while b"\n" not in self.buffer:
            ready, _, _ = select.select([self.fd], [], [], timeout)
            if not ready:
                return None
            chunk = os.read(self.fd, 65536)
            if not chunk:
                raise EOFError("trace pipe closed")
            self.buffer += chunk
        line, self.buffer = self.buffer.split(b"\n", 1)
        return line.decode(errors="replace")

    def drain(self):
        while self.readline(timeout=0.1) is not None:
            pass


class Monitor:
    def __init__(self, devices):
        self.devices = devices
        self.notifier = Notifier()
        # When each program woke the GPU, within the repeat window.
        self.wakes = defaultdict(deque)

        INSTANCE.mkdir(exist_ok=True)
        names = " || ".join(f'name == "{d.name}"' for d in devices)
        self.stack_trigger = f"stacktrace if {names}"
        for event in ("rpm_resume", "rpm_usage"):
            self.trace(event, False)
            (EVENTS / event / "filter").write_text(names)
        self.pipe = TracePipe(INSTANCE / "trace_pipe")

    def trace(self, event, enabled):
        (EVENTS / event / "enable").write_text("1" if enabled else "0")
        if event == "rpm_resume":
            # A trigger fires even while its event is off, so it is set only
            # while the event is on.
            trigger = EVENTS / event / "trigger"
            try:
                trigger.write_text(("" if enabled else "!") + self.stack_trigger)
            except OSError:
                # Already set, or already removed (as when restarting).
                pass

    def wait_for_wakers(self):
        """Sleep until something asks for the GPU; return everything that did.

        Gathers the whole burst of requests that starts the GPU.
        """
        wakers = Requesters()
        line = self.pipe.readline()
        while line is not None:
            wakers.add(line)
            line = self.pipe.readline(timeout=BURST_QUIET)
        return wakers

    def count_wake(self, waker, battery):
        """Note a wake-up by a program; warn if it keeps waking the GPU."""
        now = time.monotonic()
        wakes = self.wakes[waker.program]
        wakes.append(now)
        while now - wakes[0] > REPEAT_WINDOW:
            wakes.popleft()
        if len(wakes) < REPEAT_WAKES:
            return
        minutes = (now - wakes[0]) / 60
        log(
            f"{waker.program} keeps waking the GPU: {len(wakes)} times in "
            f"{minutes:.0f} min; last: {waker.description}"
        )
        if battery:
            self.notifier.send(
                "repeat",
                waker.program,
                REPEAT_COOLDOWN,
                f"{waker.program} keeps waking the discrete GPU",
                f"It woke the GPU {len(wakes)} times in the last "
                f"{max(minutes, 1):.0f} minutes.",
            )

    def follow(self, requesters, wakers, battery, started):
        """Follow the requests until the GPU powers down."""
        following = True
        long_on = False
        while gpu_awake(self.devices):
            deadline = time.monotonic() + POLL_INTERVAL
            seen = 0
            while following and seen <= FLOOD:
                remaining = deadline - time.monotonic()
                line = self.pipe.readline(timeout=max(remaining, 0))
                if line is None:
                    break
                seen += 1
                new = requesters.add(line)
                if new:
                    log(f"GPU also requested by: {new.description}")
            if following and seen > FLOOD:
                following = False
                self.trace("rpm_resume", False)
                self.trace("rpm_usage", False)
                log("GPU in heavy use; not following requests until it is off")
            time.sleep(max(deadline - time.monotonic(), 0))

            if not gpu_awake(self.devices):
                break
            if not battery and on_battery():
                battery = True
                log(f"GPU still on after unplugging; woken by: {wakers}")
                self.notifier.send(
                    "unplugged",
                    "",
                    0,
                    "Discrete GPU on after unplugging",
                    f"In use by {requesters.programs(recent_first=True)}.",
                )
            on_for = time.monotonic() - started
            if not long_on and on_for > LONG_ON:
                long_on = True
                users = requesters.summary(time.monotonic()) or "nothing seen"
                log(f"GPU on for over {LONG_ON}s; requested by: {users}")
                if battery and on_battery():
                    self.notifier.send(
                        "long",
                        "",
                        0,
                        f"Discrete GPU on for over {LONG_ON} seconds on battery",
                        f"In use by {requesters.programs(recent_first=True)}.",
                    )
        if not following:
            self.pipe.drain()

    def run(self):
        log("monitoring " + " ".join(d.name for d in self.devices))
        while True:
            self.trace("rpm_resume", True)
            if gpu_awake(self.devices):
                # On before the monitor could watch for the request, as at
                # boot.
                requesters = Requesters()
                wakers = "unknown (already on)"
            else:
                requesters = self.wait_for_wakers()
                wakers = requesters.names() or "unknown"

            if not gpu_awake(self.devices):
                log(f"wake-up requested but the GPU stayed off; by: {wakers}")
                continue

            started = time.monotonic()
            battery = on_battery()
            supply = "battery" if battery else "mains"
            # The first request is what woke it; the others in the burst
            # often only react to it powering up.
            waker = requesters.first
            known = requesters.known_cause()
            if known:
                log(f"GPU on ({supply}); woken by: {known} ({wakers})")
            else:
                log(f"GPU on ({supply}); woken by: {wakers}")
            if battery and not known:
                program = waker.program if waker else "unknown"
                if waker:
                    woken_by = f"Woken by {requesters.programs()}."
                else:
                    woken_by = (
                        "It was already on when the monitor started, "
                        "so what woke it is unknown."
                    )
                self.notifier.send(
                    "wake",
                    program,
                    WAKE_COOLDOWN,
                    "Discrete GPU woken on battery",
                    woken_by,
                )
            if waker and not waker.kernel:
                self.count_wake(waker, battery)

            self.trace("rpm_usage", True)
            self.follow(requesters, wakers, battery, started)
            self.trace("rpm_usage", False)

            now = time.monotonic()
            summary = requesters.summary(now) or "nothing seen"
            log(f"GPU off after {now - started:.0f}s; requested by: {summary}")
            if not known:
                for requester, stack in requesters.kernel_stacks():
                    log(f"kernel request by {requester.comm}: " + " < ".join(stack))


def main():
    devices = find_devices()
    if not devices:
        log("no NVIDIA GPU found; nothing to monitor")
        return
    Monitor(devices).run()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
