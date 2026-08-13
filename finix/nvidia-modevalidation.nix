# The Asus VG279R monitor connected here only accepts EDID-provided modes
# ("continuous frequency modes not allowed"). Xorg/nvidia's mode validation
# still walks its full standard VESA mode table before falling back to EDID
# modes, and hangs/dies partway through that walk on this monitor
# (reproduced identically with both the open and closed nvidia kernel
# module -- it's the shared closed-source X11 driver code, not the .ko).
#
# Tried and didn't help: `Option "ModeValidation" "NoVesaModes"`, `Option
# "ModeValidation" "NoExtendedGpuCapabilitiesCheck"` -- both were seemingly
# ignored (no change in the Xorg log). What actually worked: skip the whole
# search by pinning a single explicit mode.
#
# If you hit the same hang on different hardware, swap 1920x1080 for your
# monitor's real native resolution.
{ ... }:
{
  environment.etc."X11/xorg.conf.d/01-nvidia-modevalidation.conf".text = ''
    Section "Screen"
      Identifier "Screen-nvidia[0]"
      SubSection "Display"
        Modes "1920x1080"
      EndSubSection
    EndSection
  '';
}
