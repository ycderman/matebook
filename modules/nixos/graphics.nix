# Intel ekran kartı — Alder Lake-P GT1 [UHD Graphics], PCI 8086:46a3 (Gen12).
# https://wiki.nixos.org/wiki/Intel_Graphics
{ pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam/Wine için 32-bit GL

    extraPackages = with pkgs; [
      intel-media-driver # VA-API (iHD) — wiki bunu intel-vaapi-driver'a tercih ediyor
      vpl-gpu-rt # oneVPL / QuickSync çalışma zamanı
      intel-compute-runtime # OpenCL + Level Zero
    ];
  };

  # Gen12 için modern VA-API arka ucu iHD.
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  # i915.force_probe gerekmiyor: 8086:46a3 çekirdek tarafından hiçbir parametre
  # olmadan tanınıyor (bu makinede doğrulandı).

  environment.systemPackages = with pkgs; [
    libva-utils # vainfo
    intel-gpu-tools # intel_gpu_top
    mesa-demos # glxinfo, glxgears (glxinfo paketi bunun içine taşındı)
    vulkan-tools
  ];
}
