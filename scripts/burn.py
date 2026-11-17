"""Write an installer ISO to a USB stick, replacing everything on it.

Refuses anything that is not a whole USB or removable disk, and disks with
mounted partitions. Asks for confirmation, writes the image, and verifies the
copy by reading it back.
"""

import argparse
import json
import os
import stat
import subprocess
import sys
from pathlib import Path

VARIANTS = ("graphical", "minimal")


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


def build_iso(flake, variant):
    """Build an installer ISO and return the image file."""
    output = subprocess.run(
        [
            "nix",
            "build",
            "--no-link",
            "--print-out-paths",
            f"{flake}#installer-iso-{variant}",
        ],
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    ).stdout.strip()
    (image,) = Path(output, "iso").glob("*.iso")
    return image


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
    # stick holds the image once this returns.
    subprocess.run(
        [
            "sudo",
            "dd",
            f"if={image}",
            f"of={device}",
            "bs=4M",
            "conv=fsync",
            "oflag=direct",
            "status=progress",
        ],
        check=True,
    )
    subprocess.run(["sync"], check=True)


def verify(image, device, size):
    result = subprocess.run(
        ["sudo", "cmp", f"--bytes={size}", "--", str(image), str(device)]
    )
    return result.returncode == 0


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
        help="graphical (default) or minimal to build that installer, or an image file",
    )
    parser.add_argument(
        "--flake",
        default=".",
        help="the flake to build the installer from (default: the current directory)",
    )
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    device = args.device.resolve()

    try:
        check_device(device)
        image = (
            build_iso(args.flake, args.iso) if args.iso in VARIANTS else Path(args.iso)
        )
        if not image.is_file():
            raise Refusal(f"{image} is not a file")
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

    write(image, device)
    print("Verifying...")
    if not verify(image, device, size):
        print(f"The copy on {device} does not match the image.", file=sys.stderr)
        return 1
    print(f"Done: {device} holds the image and can be removed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
