# Ses — Alder Lake-P SOF DSP üzerinde PipeWire (kart: sof-hda-dsp).
# https://wiki.nixos.org/wiki/PipeWire
{ ... }:
{
  # rtkit, PipeWire'ın gerçek zamanlı zamanlayıcıyı kullanmasına izin verir.
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true;  # JACK istemcisi gerekirse aç
    wireplumber.enable = true;
  };

  # PipeWire, PulseAudio'nun tamamen yerini alıyor.
  services.pulseaudio.enable = false;

  # Alder Lake SOF DSP firmware'i, firmware.nix'teki
  # hardware.enableRedistributableFirmware ile gelen linux-firmware setinde.
}
