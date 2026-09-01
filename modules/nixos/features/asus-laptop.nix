{ ... }:

{
  services.asusd.enable = true;

  # Preserve the ROG Zephyrus G16's current state; supergfxd is intentionally disabled.
  services.supergfxd.enable = false;
}
