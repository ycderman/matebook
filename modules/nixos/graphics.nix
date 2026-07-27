# Intel graphics — Alder Lake-P GT1 [UHD Graphics], PCI 8086:46a3 (Gen12).
# https://wiki.nixos.org/wiki/Intel_Graphics
{ pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # 32-bit GL for Steam/Wine

    extraPackages = with pkgs; [
      intel-media-driver # VA-API (iHD) — the wiki's recommendation over intel-vaapi-driver
      vpl-gpu-rt # oneVPL / QuickSync runtime
      intel-compute-runtime # OpenCL + Level Zero
    ];
  };

  # iHD is the modern VA-API backend for Gen12.
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  # No i915.force_probe needed: 8086:46a3 has been supported out of the box
  # since the Alder Lake-P enablement landed upstream, and the running kernel
  # on this machine probes it without any parameter.

  environment.systemPackages = with pkgs; [
    libva-utils # vainfo
    intel-gpu-tools # intel_gpu_top
    glxinfo
    vulkan-tools
  ];
}
