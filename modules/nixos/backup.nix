{ config, pkgs, lib, ... }:

# MateBook yedekleri.
#
# Kural: yapılandırma iki yerde durur — Git ve ev sunucusundaki depolama diski.
# Git tarafı elle commit/push ile yürür; bu modül depolama diski tarafını
# otomatikleştirir.
let
  dest = "/mnt/storage/backups/MateBook";
  keep = 8;
in
{
  systemd.services.matebook-backup = {
    description = "Weekly MateBook configuration backup to the home server";

    after = [ "mnt-storage.mount" ];

    path = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.git
      pkgs.util-linux
    ];

    serviceConfig = {
      Type = "oneshot";
      UMask = "0022";
    };

    # Birim /mnt/storage'ı çekip bağlamayı dener. Automount kapıcısı
    # (bkz. storage.nix) tetikleyiciyi düşürmüş olsa bile bu doğrudan
    # mnt-storage.mount birimini çalıştırır.
    unitConfig.RequiresMountsFor = dest;

    script = ''
      set -euo pipefail

      dest=${dest}
      keep=${toString keep}
      ts=$(date +%Y%m%d-%H%M%S)

      # Sunucu kapalıysa /mnt/storage sıradan bir boş dizindir. O durumda
      # yedeği yerel diske yazmak sessiz bir yanılsama olur; hata ver.
      if ! mountpoint -q /mnt/storage; then
        echo "/mnt/storage bagli degil (ev sunucusu kapali olabilir); yedek alinmadi." >&2
        exit 1
      fi
      install -d -m 0755 "$dest"

      # Git bundle tüm dalları ve geçmişi tek dosyada taşır, doğrudan
      # klonlanabilir ve yalnız Git'in izlediğini içerir; paylaşım LAN'a açık
      # olduğu için bu bilinçli bir tercihtir.
      bundle="$dest/nixos-config-$ts.bundle"
      git -c safe.directory=/etc/nixos -C /etc/nixos bundle create "$bundle" --all
      chmod 0644 "$bundle"

      # Son $keep yedeği tut.
      ls -1t "$dest/nixos-config-"* 2>/dev/null \
        | tail -n +$((keep + 1)) | xargs -r rm -f

      echo "Yedek alindi: $bundle ($(stat -c %s "$bundle") bayt)"
    '';
  };

  systemd.timers.matebook-backup = {
    description = "Weekly MateBook configuration backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";

      # Dizüstü yedek saatinde kapalıysa açılışta telafi et.
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
