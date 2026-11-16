"""Log what powers up the NVIDIA GPU and what keeps it on.

Sends a desktop notification when the GPU is on while on battery.

The kernel reports power management requests for a device through trace
events, together with the process that made them: `rpm_resume` for each
wake-up request, and `rpm_usage` each time a process takes or releases a hold
that keeps the device on. The monitor sleeps on the wake-up requests, so it
costs nothing while the GPU is off, and it never queries the GPU itself (which
would wake it). While the GPU is on, it also follows the holds, and checks
every two seconds whether the GPU has powered down again.
"""

import os
import re
import select
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path

TRACING = Path(os.environ.get("GPU_MONITOR_TRACING", "/sys/kernel/tracing"))
PCI = Path(os.environ.get("GPU_MONITOR_PCI", "/sys/bus/pci/devices"))
POWER = Path(os.environ.get("GPU_MONITOR_POWER", "/sys/class/power_supply"))
RUNTIME = Path(os.environ.get("GPU_MONITOR_RUNTIME", "/run/user"))

INSTANCE = TRACING / "instances" / "gpu-monitor"
EVENTS = INSTANCE / "events" / "rpm"

# Seconds between two checks of whether the GPU is still on.
POLL_INTERVAL = 2
# Seconds without a request after which a burst of requests is over.
BURST_QUIET = 1
# Seconds between two notifications, so a GPU that keeps waking does not spam.
NOTIFY_COOLDOWN = 300
# Requests within one check interval above which following them would cost
# more than it is worth; the GPU is plainly in heavy use by then.
FLOOD = 5000
# Processes listed when the GPU powers down.
SUMMARY_SIZE = 8

# A trace line looks like:
#   nvidia-smi-12345 [003] ..... 123.456: rpm_resume: 0000:65:00.0 flags-4 ...
TRACE_LINE = re.compile(
    r"^\s*(?P<comm>.+)-(?P<pid>\d+)\s+\[\d+\].*rpm_(?:resume|usage): "
)


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


def describe(comm, pid):
    """Name the process, with its command line if it is still running."""
    try:
        raw = Path(f"/proc/{pid}/cmdline").read_bytes()
    except OSError:
        raw = b""
    cmdline = " ".join(raw.decode(errors="replace").split())
    if cmdline:
        return f"{comm} (pid {pid}): {cmdline[:200]}"
    return f"{comm} (pid {pid})"


@dataclass
class Requester:
    """A process that asked for the GPU while it was on, or to turn it on."""

    description: str
    requests: int = 0
    last: float = 0.0


class Requesters:
    """The processes seen in the trace since the GPU was last off."""

    def __init__(self):
        self.by_process = {}

    def add(self, line):
        """Record a trace line; return the requester if it is a new one."""
        match = TRACE_LINE.match(line)
        if not match:
            return None
        key = (match["comm"], match["pid"])
        requester = self.by_process.get(key)
        is_new = requester is None
        if is_new:
            requester = Requester(describe(*key))
            self.by_process[key] = requester
        requester.requests += 1
        requester.last = time.monotonic()
        return requester if is_new else None

    def names(self):
        return "; ".join(r.description for r in self.by_process.values())

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


class Notifier:
    """Sends a desktop notification to every logged-in user."""

    def __init__(self):
        self.last = None

    def send(self, body):
        now = time.monotonic()
        if self.last is not None and now - self.last < NOTIFY_COOLDOWN:
            return
        self.last = now
        for bus in RUNTIME.glob("*/bus"):
            if not bus.is_socket():
                continue
            owner = bus.stat()
            try:
                subprocess.run(
                    [
                        "notify-send",
                        "--urgency=critical",
                        "--app-name=GPU monitor",
                        "--icon=battery-caution",
                        "Discrete GPU is on while on battery",
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
            except (OSError, subprocess.SubprocessError) as error:
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

        INSTANCE.mkdir(exist_ok=True)
        names = " || ".join(f'name == "{d.name}"' for d in devices)
        for event in ("rpm_resume", "rpm_usage"):
            self.trace(event, False)
            (EVENTS / event / "filter").write_text(names)
        self.pipe = TracePipe(INSTANCE / "trace_pipe")

    def trace(self, event, enabled):
        (EVENTS / event / "enable").write_text("1" if enabled else "0")

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

    def follow(self, requesters, wakers, battery):
        """Follow the requests until the GPU powers down."""
        following = True
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

            if not battery and on_battery() and gpu_awake(self.devices):
                battery = True
                log(f"GPU still on after unplugging; woken by: {wakers}")
                self.notifier.send(f"Still on after unplugging. Woken by: {wakers}")
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
            log(f"GPU on ({supply}); woken by: {wakers}")
            if battery:
                self.notifier.send(f"Woken by: {wakers}")

            self.trace("rpm_usage", True)
            self.follow(requesters, wakers, battery)
            self.trace("rpm_usage", False)

            now = time.monotonic()
            summary = requesters.summary(now) or "nothing seen"
            log(f"GPU off after {now - started:.0f}s; requested by: {summary}")


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
