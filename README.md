# NixOS — HUAWEI MateBook D16 2024 (MCLF-XX)

`nixos-unstable` (26.11 geliştirme dalı) + flake + Home Manager + plasma-manager.
Yapılandırma bu makineye özel: donanım bilgileri çalışan sistemden okunarak yazıldı.

## Hedef sistem

| | |
|---|---|
| Makine | HUAWEI MCLF-XX (MateBook D16 2024, SKU C170, BIOS 1.13) |
| CPU | Intel Core i5-12450H (Alder Lake-P, 8C/12T, `intel_pstate`) |
| GPU | Intel UHD Graphics, Alder Lake-P GT1 — `8086:46a3` |
| RAM | 8 GiB (takas bölümü yok → zram) |
| Disk | WD PC SN740 512 GB NVMe (`/dev/nvme0n1`) |
| Wi-Fi / BT | Intel AX201 (`iwlwifi` / `btusb`) |
| Ses | Alder Lake-P HDA + SOF DSP (`sof-hda-dsp`, Conexant codec) |
| Kanal | `nixos-unstable` → `stateVersion = "26.11"` |
| Önyükleyici | **systemd-boot** (GRUB değil) |
| Giriş yöneticisi | **Plasma Login Manager** (SDDM değil) |
| Masaüstü | Plasma 6 / Wayland |

## Disk düzeni

UUID değil, **label** kullanılıyor:

| Bölüm | Boyut | FS | Label | Bağlama |
|---|---|---|---|---|
| `/dev/nvme0n1p1` | 2 GiB | vfat (ESP) | `BOOT` | `/boot` |
| `/dev/nvme0n1p2` | kalan (~475 GiB) | ext4 | `nixos` | `/` |

Manual'ın önerisi: *"It is recommended that you assign a unique symbolic label to
the file system using the option `-L label`, since this makes the file system
configuration independent from device changes."*

## Dizin yapısı

```
nixos-config/
├── flake.nix                    # inputs: nixpkgs-unstable, home-manager, plasma-manager
├── hosts/
│   └── matebook/
│       ├── default.nix          # hostname + stateVersion, modülleri toplar
│       └── hardware.nix         # elle yazılmış donanım profili (label'lı fileSystems)
└── modules/
    ├── nixos/                   # sistem seviyesi modüller
    │   ├── default.nix          # hepsini import eder
    │   ├── boot.nix             # systemd-boot
    │   ├── nix.nix              # flakes, gc, optimise, registry
    │   ├── locale.nix           # tr_TR.UTF-8, Europe/Istanbul, trq / xkb tr
    │   ├── network.nix          # NetworkManager, firewall, avahi, homeserver hosts
    │   ├── audio.nix            # PipeWire + rtkit
    │   ├── graphics.nix         # Intel Gen12: intel-media-driver, vpl-gpu-rt
    │   ├── firmware.nix         # redistributable firmware + fwupd
    │   ├── bluetooth.nix        # AX201 BT
    │   ├── power.nix            # power-profiles-daemon, thermald, logind, zram, oomd
    │   ├── huawei.nix           # huawei-wmi: pil şarj eşikleri, fn-lock
    │   ├── desktop.nix          # Plasma 6 + plasma-login-manager
    │   ├── fonts.nix
    │   ├── packages.nix         # sistem araçları, fstrim, smartd
    │   ├── storage.nix          # homeserver NFS/SSHFS (yorumlu örnek)
    │   ├── users.nix            # kullanıcı can
    │   └── home-manager.nix     # HM'i NixOS modülü olarak bağlar
    └── home/                    # kullanıcı seviyesi modüller
        ├── default.nix
        ├── packages.nix
        ├── shell.nix            # bash + direnv
        ├── git.nix
        └── plasma.nix           # plasma-manager (programs.plasma)
```

Modül eklemek için: dosyayı `modules/nixos/` altına koy, `modules/nixos/default.nix`
içindeki `imports` listesine bir satır ekle. Başka hiçbir yeri değiştirmen gerekmez.

## Kurulum

> **UYARI:** Aşağıdaki adımlar `/dev/nvme0n1` diskini tamamen siler — mevcut Arch
> kurulumu (btrfs `archlinux` bölümü) dahil. Önce yedek al.

USB'deki NixOS minimal ISO ile UEFI modunda başlat, sonra `sudo -i`.

### 1. Ağ

Kablolu bağlantı otomatik gelir. Wi-Fi için ISO'daki `wpa_cli` ya da `nmtui` kullan.

### 2. Bölümleme (GPT, 2 GiB ESP + kalanı ext4)

```bash
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 2049MiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart root ext4 2049MiB 100%
```

### 3. Biçimlendirme — label'lar `hardware.nix` ile birebir aynı olmalı

```bash
mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
mkfs.ext4 -L nixos     /dev/nvme0n1p2
```

`BOOT` ve `nixos` yazımı önemli: FAT label'ları büyük harfe çevrilir, ext4
label'ı büyük/küçük harf duyarlıdır.

### 4. Bağlama

```bash
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount -o umask=077 /dev/disk/by-label/BOOT /mnt/boot
```

Kontrol: `lsblk -o NAME,FSTYPE,LABEL,MOUNTPOINT` çıktısında label'lar görünmeli.

### 5. Yapılandırmayı yerine koy

`nixos-generate-config` çalıştırmaya gerek yok — `hardware.nix` elle yazıldı ve
üretilen dosyanın yerine geçiyor.

```bash
nix-shell -p git
git clone <bu-depo> /mnt/etc/nixos      # ya da USB'den kopyala
```

Flake'ler yalnızca git tarafından izlenen dosyaları görür; depo yeni ise:

```bash
cd /mnt/etc/nixos
git init && git add -A
```

### 6. Kurulum

```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
nixos-install --flake /mnt/etc/nixos#matebook
```

İlk çalıştırmada `flake.lock` üretilir. Kurulum bitince:

```bash
reboot
```

### 7. İlk açılış

- Kullanıcı: `can`, geçici parola: `nixos` (`users.nix` içindeki `initialPassword`).
- Hemen değiştir: `passwd`
- Yapılandırmayı ev dizinine taşı (alias'lar `~/nixos-config` bekliyor):
  ```bash
  sudo cp -r /etc/nixos ~/nixos-config && sudo chown -R can:users ~/nixos-config
  ```

## Günlük kullanım

```bash
rebuild        # sudo nixos-rebuild switch --flake ~/nixos-config#matebook
rebuild-test   # kalıcı olmayan deneme
rebuild-boot   # bir sonraki açılışta geçerli
update         # nix flake update --flake ~/nixos-config
```

Alias'lar `modules/home/shell.nix` içinde tanımlı. Değişiklik yapmadan önce
`nixos-rebuild dry-build --flake .#matebook` ile derlemeyi denemek iyi bir alışkanlık.

## Kurulum sonrası doğrulama

```bash
bootctl status                      # systemd-boot yüklü mü, ESP /boot mu
findmnt /boot /                     # label ile bağlanmış mı
systemctl status plasma-login-manager
vainfo                              # iHD sürücüsü (VA-API)
intel_gpu_top                       # GPU
zramctl                             # zram takas
cat /sys/devices/platform/huawei-wmi/charge_control_thresholds   # 70 80
systemctl status power-profiles-daemon thermald
```

## Verilen kararlar ve gerekçeleri

- **systemd-boot** — Manual: *"The recommended option is systemd-boot."*
  `grub.enable = false` açıkça yazıldı, `editor = false` ile boot menüsünden
  `init=/bin/sh` ile root olunması engellendi.
- **plasma-login-manager** — Wiki'nin KDE sayfasındaki
  `services.displayManager.plasma-login-manager.enable`. SDDM etkinleştirilmedi.
- **Wayland** — Plasma 6 varsayılan olarak Wayland'de çalışır, bu yüzden
  `defaultSession` ayarlanmadı; X11'e dönmek için `desktop.nix` içinde yorumlu satır var.
- **power-profiles-daemon, TLP değil** — Plasma'nın pil eklentisi doğrudan PPD ile
  konuşuyor; ikisi aynı ayarları yönettiği için birlikte çalıştırılmamalı.
- **zram + systemd-oomd** — 8 GiB RAM ve takas bölümü olmayan bir düzende
  wiki'nin önerdiği kombinasyon. Hazırda bekletme (hibernate) bu düzende mümkün değil.
- **`i915.enable_guc` yok** — Bu donanımda kernel zaten `adlp_guc` + `tgl_huc`
  yükleyip GuC submission'ı açıyor (dmesg ile doğrulandı), parametre gereksiz.
- **`i915.force_probe` yok** — `8086:46a3` çekirdek tarafından parametresiz tanınıyor.

## Kaynaklar

Yapılandırma yalnızca NixOS'un kendi kaynaklarına dayanıyor:

- [NixOS Manual (stable)](https://nixos.org/manual/nixos/stable/) — bölümleme,
  label kullanımı, UEFI kurulumu, systemd-boot önerisi
- [NixOS Wiki — Flakes](https://wiki.nixos.org/wiki/Flakes)
- [NixOS Wiki — Home Manager](https://wiki.nixos.org/wiki/Home_Manager)
- [NixOS Wiki — KDE](https://wiki.nixos.org/wiki/KDE)
- [NixOS Wiki — Intel Graphics](https://wiki.nixos.org/wiki/Intel_Graphics)
- [NixOS Wiki — PipeWire](https://wiki.nixos.org/wiki/PipeWire)
- [NixOS Wiki — Bluetooth](https://wiki.nixos.org/wiki/Bluetooth)
- [NixOS Wiki — Laptop](https://wiki.nixos.org/wiki/Laptop)
- [NixOS Wiki — Swap](https://wiki.nixos.org/wiki/Swap)
- [NixOS Wiki — Storage optimization](https://wiki.nixos.org/wiki/Storage_optimization)
- [NixOS Wiki — Fwupd](https://wiki.nixos.org/wiki/Fwupd)

**İstisna:** `plasma-manager`, NixOS Wiki'nin KDE sayfasının açıkça belirttiği gibi
bir topluluk projesi ve nixpkgs'in parçası değil; seçenekleri için resmi NixOS
belgesi yok. Bu yüzden `modules/home/plasma.nix` bilinçli olarak dar tutuldu.
Genişletmek için `nix run github:nix-community/plasma-manager` (rc2nix) ile mevcut
Plasma ayarlarını Nix'e dökebilirsin.
