"""Write an installer ISO to a USB stick, replacing everything on it.

Refuses anything that is not a whole USB or removable disk, and disks with
mounted partitions. Asks for confirmation, writes the image, and verifies the
copy by reading it back. Runs as root, so that the password is asked only once,
before anything happens: `just burn` runs it with sudo.
"""

import argparse
import json
import os
import stat
import subprocess
import sys
from pathlib import Path

VARIANTS = ("graphical", "minimal")

# Bytes read or written at a time.
BLOCK = 4 * 1024 * 1024


class Refusal(Exception):
    """A reason not to write to the device."""


def lsblk(device, *columns, nodeps=False):
    """The lsblk properties of the device and, unless nodeps, its partitions."""
    command = ["lsblk", "--json", "--bytes", "--output", ",".join(columns)]
    if nodeps:
        command.append("--nodeps")
    output = subprocess.run(
        [*command, "--", str(device)], check=True, capture_output=True, text=True
    ).stdout
    return json.loads(output)["blockdevices"]


def flatten(devices):
    for device in devices:
        yield device
        yield from flatten(device.get("children", []))


def is_block_device(path):
    return stat.S_ISBLK(os.stat(path).st_mode)


def check_device(device):
    """Raise a Refusal unless the device is safe to overwrite."""
    if not device.exists() or not is_block_device(device):
        raise Refusal(f"{device} is not a block device")

    (disk,) = lsblk(device, "TYPE", "TRAN", "RM", nodeps=True)
    if disk["type"] != "disk":
        raise Refusal(f"{device} is a {disk['type']}, not a whole disk")
    if disk["tran"] != "usb" and not disk["rm"]:
        raise Refusal(
            f"{device} is neither a USB nor a removable disk; refusing to overwrite it"
        )

    mounted = [
        part["name"]
        for part in flatten(lsblk(device, "NAME", "MOUNTPOINTS"))
        if any(part.get("mountpoints") or [])
    ]
    if mounted:
        raise Refusal(
            f"{device} has mounted partitions ({', '.join(mounted)}); "
            "unmount them first"
        )


def built_iso(variant):
    """The image `just iso` built for the variant, in result-<variant>/iso."""
    images = sorted(Path(f"result-{variant}", "iso").glob("*.iso"))
    if len(images) != 1:
        raise Refusal(
            f"no {variant} installer ISO found in result-{variant}/iso; "
            f"build it first with `just iso {variant}`"
        )
    return images[0]


def describe(device):
    (disk,) = lsblk(device, "MODEL", "SIZE", "TRAN", nodeps=True)
    model = (disk["model"] or "unknown model").strip()
    return f"{model}, {human_size(disk['size'])}, {disk['tran'] or 'removable'}"


def human_size(size):
    for unit in ("B", "KiB", "MiB", "GiB"):
        if size < 1024:
            return f"{size:.1f} {unit}" if unit != "B" else f"{size} B"
        size /= 1024
    return f"{size:.1f} TiB"


def confirm(device):
    answer = input(f"Everything on {device} will be erased. Type 'yes' to continue: ")
    return answer.strip() == "yes"


def write(image, device):
    # Writes straight to the device and flushes it before dd exits, so the
    # stick holds the image once this returns. dd shows the progress.
    subprocess.run(
        [
            "dd",
            f"if={image}",
            f"of={device}",
            f"bs={BLOCK}",
            "conv=fsync",
            "oflag=direct",
            "status=progress",
        ],
        check=True,
    )
    subprocess.run(["sync"], check=True)


def verify(image, device, size):
    """Read the image back from the device and compare it with the file.

    Reads with dd, which shows the progress, bypassing the kernel's cache so
    that what is compared is what the device holds.
    """
    reader = subprocess.Popen(
        [
            "dd",
            f"if={device}",
            f"bs={BLOCK}",
            f"count={size}",
            "iflag=direct,count_bytes",
            "status=progress",
        ],
        stdout=subprocess.PIPE,
    )
    assert reader.stdout is not None
    with reader, image.open("rb") as expected:
        while chunk := reader.stdout.read(BLOCK):
            if chunk != expected.read(len(chunk)):
                reader.terminate()
                return False
        complete = expected.read(1) == b""
    return complete and reader.returncode == 0


def parse_args(argv):
    parser = argparse.ArgumentParser(prog="burn", description=__doc__.splitlines()[0])
    parser.add_argument(
        "device",
        type=Path,
        help="the USB stick; prefer a stable /dev/disk/by-id path",
    )
    parser.add_argument(
        "iso",
        nargs="?",
        default="graphical",
        help=(
            "graphical (default) or minimal for the installer `just iso` built "
            "into result-<variant>/iso, or an image file"
        ),
    )
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    device = args.device.resolve()

    try:
        if os.geteuid() != 0:
            raise Refusal("burn must run as root; use `just burn`")
        check_device(device)
        image = built_iso(args.iso) if args.iso in VARIANTS else Path(args.iso)
        if not image.is_file():
            raise Refusal(f"invalid input: {args.iso}")
        size = image.stat().st_size
        (disk,) = lsblk(device, "SIZE", nodeps=True)
        if size > disk["size"]:
            raise Refusal(f"the image does not fit on {device}")
    except Refusal as refusal:
        print(refusal, file=sys.stderr)
        return 1

    print(f"Image:  {image} ({human_size(size)})")
    print(f"Device: {device} ({describe(device)})")
    if not confirm(device):
        print("Aborted.")
        return 1

    print("Writing...", flush=True)
    write(image, device)
    print("Verifying...", flush=True)
    if not verify(image, device, size):
        print(f"The copy on {device} does not match the image.", file=sys.stderr)
        return 1
    print(f"Done: {device} holds the image and can be removed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
