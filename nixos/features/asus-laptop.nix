{ ... }:

{
  services.asusd.enable = true;

  # Preserve Turing's current state; supergfxd is intentionally disabled.
  services.supergfxd.enable = false;
}
