# Audio — PipeWire on the Alder Lake-P SOF DSP (card: sof-hda-dsp).
# https://wiki.nixos.org/wiki/PipeWire
{ ... }:
{
  # rtkit lets PipeWire use the realtime scheduler.
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true;  # enable if JACK clients are ever needed
    wireplumber.enable = true;
  };

  # PipeWire replaces PulseAudio entirely.
  services.pulseaudio.enable = false;

  # The SOF DSP firmware for Alder Lake ships with the linux-firmware set that
  # hardware.enableRedistributableFirmware pulls in (see firmware.nix).
}
