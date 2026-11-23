"""Download mail with mbsync, and report fetches that fail.

`mail-fetch fetch` runs mbsync for every account, download-only, and retries a
failed run a few times before failing itself. The retries happen here rather
than through systemd's Restart=, because systemd triggers OnFailure= after
every failed attempt, including ones it retries. This way the service fails,
and notifies, only once all attempts have failed. The first attempts often
fail at login, before the network is up.

`mail-fetch notify-failure` runs from the fetch service's OnFailure=. It sends
a desktop notification with the last errors of the failed fetch, at most once
per login: it leaves a marker in the runtime directory, which is removed when
the user's last session ends.
"""

import argparse
import os
import subprocess
import sys
import time
from pathlib import Path

ATTEMPTS = 4
# Seconds between two attempts.
RETRY_DELAY = 60

# These switches override the configuration file: only pull changes, and only
# create, remove, or expunge on this machine. Whatever the file says, nothing
# is changed on the servers.
MBSYNC = [
    "mbsync",
    "--all",
    "--pull",
    "--create-near",
    "--remove-near",
    "--expunge-near",
]

# Starts this program's own log lines, which the notification leaves out.
LOG_PREFIX = "mail-fetch: "
# Lines of mbsync's output shown in the notification.
ERROR_LINES = 3
# How long a notification stays on screen, in milliseconds; 0 keeps it until
# it is dismissed. Without one, COSMIC shows it for 3 seconds.
NOTIFY_TIMEOUT = 0
MARKER_NAME = "mail-fetch-failure-notified"


def log(message: str) -> None:
    # Flushed, so that it appears in the journal in order with mbsync's output.
    print(LOG_PREFIX + message, flush=True)


def fetch() -> int:
    for attempt in range(1, ATTEMPTS + 1):
        if subprocess.run(MBSYNC).returncode == 0:
            return 0
        if attempt < ATTEMPTS:
            log(f"attempt {attempt} of {ATTEMPTS} failed; retrying in a minute.")
            time.sleep(RETRY_DELAY)
    log(f"all {ATTEMPTS} attempts failed.")
    return 1


def last_errors() -> str:
    """The last lines mbsync wrote during the failed fetch, if any."""
    # Set by systemd for units started through OnFailure=.
    invocation = os.environ.get("MONITOR_INVOCATION_ID")
    if not invocation:
        return ""
    try:
        result = subprocess.run(
            [
                "journalctl",
                "--user",
                f"_SYSTEMD_INVOCATION_ID={invocation}",
                "--output=cat",
                "--no-pager",
            ],
            capture_output=True,
            text=True,
            check=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return ""
    lines = [
        line
        for line in result.stdout.splitlines()
        if line.strip() and not line.startswith(LOG_PREFIX)
    ]
    return "\n".join(lines[-ERROR_LINES:])


def notify_failure() -> int:
    marker = Path(os.environ["XDG_RUNTIME_DIR"]) / MARKER_NAME
    try:
        # Fails if the marker exists, so only one notification per login.
        marker.touch(exist_ok=False)
    except FileExistsError:
        return 0

    hint = (
        "Details: journalctl --user -u mail-fetch. "
        "No further notices until the next login."
    )
    body = "\n\n".join(part for part in (last_errors(), hint) if part)
    try:
        subprocess.run(
            [
                "notify-send",
                "--app-name=mail-fetch",
                f"--expire-time={NOTIFY_TIMEOUT}",
                "Mail could not be fetched",
                body,
            ],
            check=True,
        )
    except (OSError, subprocess.CalledProcessError):
        # Not notified after all, so let the next failure try again.
        marker.unlink(missing_ok=True)
        raise
    return 0


def main() -> int:
    # Named explicitly: the Nix wrapper would show as .mail-fetch-wrapped.
    parser = argparse.ArgumentParser(
        prog="mail-fetch", description=__doc__.splitlines()[0]
    )
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("fetch", help="download mail, retrying on failure")
    commands.add_parser("notify-failure", help="report a failed fetch, once per login")
    arguments = parser.parse_args()

    if arguments.command == "fetch":
        return fetch()
    return notify_failure()


if __name__ == "__main__":
    sys.exit(main())
