# NixOS — HUAWEI MateBook D16 2024 (MCLF-XX)

`nixos-unstable` (26.11 geliştirme dalı) + flake + Home Manager + plasma-manager.
Yapılandırma bu makineye özel: donanım bilgileri çalışan sistemden okunarak yazıldı.

```bash
git clone https://github.com/ycderman/matebook.git /mnt/etc/nixos
nixos-install --flake /mnt/etc/nixos#matebook
```

## Hedef sistem

| | |
|---|---|
| Makine | HUAWEI MCLF-XX (MateBook D16 2024, SKU C170, BIOS 1.13) |
| CPU | Intel Core i5-12450H (Alder Lake-P, 8C/12T, `intel_pstate`) |
| GPU | Intel UHD Graphics, Alder Lake-P GT1 — `8086:46a3` |
| RAM | 8 GiB (takas bölümü yok → zram, RAM ile aynı boyutta) |
| Disk | WD PC SN740 512 GB NVMe (`/dev/nvme0n1`) |
| Wi-Fi / BT | Intel AX201 (`iwlwifi` / `btusb`) |
| Ses | Alder Lake-P HDA + SOF DSP (`sof-hda-dsp`, Conexant codec) |
| Thunderbolt | **Yok** (aşağıya bak) |
| Kanal | `nixos-unstable` → `stateVersion = "26.11"` |
| Önyükleyici | **systemd-boot** (GRUB değil) |
| Giriş yöneticisi | **Plasma Login Manager** (SDDM değil) |
| Masaüstü | Plasma 6 / Wayland |

### Thunderbolt var mı? — Hayır

Donanımda kontrol edildi, üç bağımsız kanıt da yok diyor:

- `/sys/bus/thunderbolt/devices` dizini hiç oluşmuyor (Thunderbolt alan adı yok)
- `lspci`'de Thunderbolt NHI denetleyicisi yok. Görünen tek şey
  `00:0d.0 Alder Lake-P Thunderbolt 4 USB Controller [8086:461e]`, ki bu
  Type-C portunu süren **TCSS xHCI (USB) denetleyicisi** — Intel'in isimlendirmesi
  yanıltıcı, Thunderbolt bağlantısı anlamına gelmiyor
- `/sys/class/typec` boş — USB-PD / alternatif mod denetleyicisi görünmüyor

Yani USB-C portu: şarj + DisplayPort + USB 3.2. Bu yüzden `hardware.nix` içindeki
initrd modül listesinden `thunderbolt` çıkarıldı.

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
    │   ├── network.nix          # NetworkManager, firewall, avahi, homeserver
    │   ├── audio.nix            # PipeWire + rtkit
    │   ├── graphics.nix         # Intel Gen12: intel-media-driver, vpl-gpu-rt
    │   ├── firmware.nix         # redistributable firmware + fwupd
    │   ├── bluetooth.nix        # AX201 BT
    │   ├── power.nix            # ppd, thermald, logind (uyku yok), zram, oomd
    │   ├── huawei.nix           # huawei-wmi: pil şarj eşikleri, fn-lock
    │   ├── desktop.nix          # Plasma 6 + plasma-login-manager
    │   ├── firefox.nix          # politikalar, tr dil paketi, eklentiler
    │   ├── fonts.nix
    │   ├── packages.nix         # sistem araçları, nano, fstrim, smartd
    │   ├── storage.nix          # homeserver NFS/SSHFS (yorumlu örnek)
    │   ├── users.nix            # kullanıcı can
    │   └── home-manager.nix     # HM'i NixOS modülü olarak bağlar
    └── home/                    # kullanıcı seviyesi modüller
        ├── default.nix
        ├── packages.nix
        ├── shell.nix            # bash + direnv, EDITOR=nano
        ├── nix-shell-fix.nix    # Türkçe "İ" hatasına karşı nix sarmalayıcıları
        ├── git.nix
        └── plasma.nix           # plasma-manager: panel, powerdevil, kilit kapalı
```

Modül eklemek için: dosyayı `modules/nixos/` altına koy, `modules/nixos/default.nix`
içindeki `imports` listesine bir satır ekle. Başka hiçbir yeri değiştirmen gerekmez.

## `nix-shell -p python3` hatası ve çözümü

Hata:

```
bash: export: `RANLİB=ranlib': not a valid identifier
```

**Sebep.** nixpkgs'in derleme ortamını hazırlayan setup-hook betikleri
`export "${cmd^^}"=...` gibi kabuk içi büyük harfe çevirme kullanıyor.
Büyük/küçük harf dönüşümünü `LC_CTYPE` belirler ve Türkçe locale'de küçük `i`
harfinin büyüğü ASCII `I` değil noktalı `İ`dir. Sonuç: `ranlib` → `RANLİB`, ve
`İ` geçerli bir kabuk değişkeni karakteri olmadığı için `export` patlıyor.
Sandbox'lı derlemelerde görülmez, çünkü orada locale ayarlı değil — yalnızca
senin ortamını devralan `nix-shell` / `nix develop` etkilenir.

Bu makinede birebir doğrulandı:

```
LC_CTYPE=tr_TR.UTF-8  ->  ${v^^} = RANLİB    (hata bu)
LC_CTYPE=C.UTF-8      ->  ${v^^} = RANLIB    (düzgün)
```

**Çözüm** (`modules/home/nix-shell-fix.nix`). **Sistem diline dokunulmuyor** —
`LANG` ve bütün `LC_*` değişkenleri `tr_TR.UTF-8` kalıyor. Bunun yerine yalnızca
ilgili nix komutları, kendi alt süreçlerine `LC_CTYPE=C.UTF-8` verecek şekilde
sarmalanıyor:

```nix
nix-shell-wrapper = pkgs.writeShellScriptBin "nix-shell" ''
  export LC_CTYPE=C.UTF-8
  exec ${nix}/bin/nix-shell "$@"
'';

nix-wrapper = pkgs.writeShellScriptBin "nix" ''
  case "''${1-}" in
    develop|print-dev-env) export LC_CTYPE=C.UTF-8 ;;
  esac
  exec ${nix}/bin/nix "$@"
'';
```

Yani düzeltme tam olarak derleme ortamının içinde kalıyor; senin kabuğun,
Plasma arayüzü, `tr`/`sed` gibi araçlar hepsi Türkçe locale'de çalışmaya devam
ediyor. `nix develop` ve (direnv'in kullandığı) `nix print-dev-env` de aynı hatayı
verdiği için onlar da kapsandı; `nix build`, `nix run`, `nix flake` gibi alt
komutlar hiç dokunulmadan gerçek ikiliye geçiyor.

Sarmalayıcılar kullanıcı profiline (`/etc/profiles/per-user/can/bin`) kuruluyor
ve PATH'te sistem profilinden (`/run/current-system/sw/bin`) önce geldiği için
gerçek ikilileri gölgeliyor — ad çakışması ya da öncelik ayarı gerekmiyor.

Kaldırmak istersen `modules/home/default.nix` içindeki `imports` listesinden
`./nix-shell-fix.nix` satırını sil; o zaman komut bazında elle yapman gerekir:

```bash
LC_CTYPE=C.UTF-8 nix-shell -p python3
```

## Güç davranışı

İstenen: **hiçbir zaman uykuya geçme, kapak kapalıyken çalışmaya devam et,
ekran 10 dakika sonra yalnızca kapansın, kilit hiç olmasın.** İki katmanda:

**Sistem** (`modules/nixos/power.nix` → `services.logind.settings.Login`)

```nix
HandleLidSwitch = "ignore";
HandleLidSwitchExternalPower = "ignore";
HandleLidSwitchDocked = "ignore";
HandlePowerKey = "ignore";   # Plasma kendi oturum ekranını gösterir
IdleAction = "ignore";
```

**Plasma** (`modules/home/plasma.nix` → `powerdevil`, üç profil de aynı)

```nix
autoSuspend.action        = "nothing";
whenLaptopLidClosed       = "doNothing";
turnOffDisplay.idleTimeout = 600;   # saniye = 10 dakika
dimDisplay.enable         = false;
powerButtonAction         = "showLogoutScreen";
```

**Kilit** (`kscreenlocker`): `autoLock`, `lockOnResume`, `lockOnStartup` üçü de
`false`. Açılıştaki Plasma Login Manager girişi bundan bağımsız, o duruyor.

Elle uyku (Plasma menüsünden) hâlâ mümkün — kapatılan yalnızca otomatik uyku.
Pil kritik seviyeye düştüğündeki koruma (`batteryLevels.criticalAction`)
bilerek varsayılanda bırakıldı ki veri kaybı olmasın.

## Firefox

`modules/nixos/firefox.nix`: `languagePacks = [ "tr" ]`, telemetri/Pocket/studies
kapalı, izleme koruması açık. Bildirimsel kurulan eklentiler:

| Eklenti | Kimlik |
|---|---|
| uBlock Origin | `uBlock0@raymondhill.net` |
| Plasma Integration | `plasma-browser-integration@kde.org` |
| Proton Pass | `78272b6fa58f4a1abaac99321d503a20@proton.me` |
| TV+ 1080p (kendi imzalı) | `tvplus-1080p@ycderman` |

Plasma Integration'ın masaüstüyle konuşabilmesi için
`nativeMessagingHosts.packages = [ pkgs.kdePackages.plasma-browser-integration ]`
de eklendi (wiki: yerel mesajlaşma imperatif kurulan Firefox'ta çalışmaz).

**TV+ eklentisi için yapman gereken:** `.xpi` dosyasını depoya koy ve git'e ekle:

```bash
cp tvplus-1080p.xpi ~/nixos-config/modules/nixos/
git -C ~/nixos-config add modules/nixos/tvplus-1080p.xpi
```

Dosya yoksa o girdi hiç üretilmiyor (`lib.optionalAttrs` + `builtins.pathExists`),
yani derleme kırılmaz — dosyayı ekleyip `rebuild` dediğinde eklenti kendiliğinden
gelir. Flake yalnızca git'in izlediği dosyaları gördüğü için `git add` şart.

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
git clone https://github.com/ycderman/matebook.git /mnt/etc/nixos
```

Klonlanan depo zaten bir git deposu olduğu için ek bir şey yapmana gerek yok —
flake'ler yalnızca git'in izlediği dosyaları görür, klonlanan her dosya izleniyor.

Kurulum sırasında yerel bir değişiklik yaparsan (`hardware.nix`'te bir düzeltme
gibi) o dosyayı flake'in görmesi için önce git'e bildirmelisin:

```bash
cd /mnt/etc/nixos
git add -A
```

Depoyu klonlayamıyorsan (Wi-Fi yoksa) yapılandırmayı USB'den `/mnt/etc/nixos`
altına kopyalayıp `git init && git add -A` de diyebilirsin.

### 6. Kurulum öncesi doğrulama (tip ve seçenek kontrolü)

Bu adım **`nixos-install`'dan önce** yapılır ve diske hiçbir şey yazmaz. Amacı,
yanlış yazılmış bir seçenek adını ya da hatalı bir değer tipini kurulum
başlamadan yakalamak. Yapılandırmayı değerlendirmek nixpkgs'i indireceği için
internet bağlantısı gerekiyor.

Önce flake'i kullanılabilir hâle getir:

```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
cd /mnt/etc/nixos
git add -A          # flake yalnızca git'in izlediği dosyaları görür
```

Sonra hafiften ağıra doğru üç kademe. **Sadece ilkini yapsan bile yeter** —
soruların cevabı olan asıl kontrol o.

**1) Yalnızca değerlendirme — en hızlı, hiçbir şey derlemez.** Bütün modülleri
okur, seçenek adlarını ve tiplerini doğrular, sistemin türev (derivation)
tanımını üretip durur:

```bash
nix eval .#nixosConfigurations.matebook.config.system.build.toplevel.drvPath
```

Çıktı `/nix/store/....drv` gibi bir yolsa yapılandırmada tip/seçenek hatası yok.
Bu tek komut `hosts/`, `modules/nixos/`, `modules/home/` ve `plasma.nix`'in
tamamını kapsıyor: Home Manager bir NixOS modülü olarak bağlandığı için
home-manager ve plasma-manager seçenekleri de aynı değerlendirmeye giriyor.

**2) Flake'in tümünü denetle** — çıktıların yapısını ve tüm
`nixosConfigurations`'ı kontrol eder:

```bash
nix flake check --no-build
```

**3) Neyin derleneceğini gör** (yine derlemez, sadece planı yazar):

```bash
nix build --dry-run .#nixosConfigurations.matebook.config.system.build.toplevel
```

Gerçekten derleyip denemek istersen (uzun sürer, ama kurulumdan önce her şeyin
derlendiğini garanti eder):

```bash
nixos-rebuild build --flake /mnt/etc/nixos#matebook
```

#### Hata mesajlarını okumak

| Mesaj | Anlamı | Ne yapmalı |
|---|---|---|
| ``The option `services.foo.bar' does not exist`` | Seçenek adı yanlış, ya da unstable'da yeniden adlandırılmış/kaldırılmış | Doğru adı [search.nixos.org/options](https://search.nixos.org/options?channel=unstable) üzerinden bul |
| `A definition for option '...' is not of type '...'` | Değerin tipi yanlış (ör. sayı beklenen yere metin) | Hata satırındaki dosya/konumu düzelt |
| `attribute 'xyz' missing` | `pkgs.xyz` diye bir paket yok | [search.nixos.org/packages](https://search.nixos.org/packages?channel=unstable) ile doğru adı bul |
| `infinite recursion encountered` | Bir seçenek dolaylı olarak kendini tanımlıyor | Hata izindeki modülde `lib.mkDefault` / `config.` kullanımına bak |
| `error: path '/nix/store/...' does not exist` + `.xpi` | `tvplus-1080p.xpi` git'e eklenmemiş | `git add modules/nixos/tvplus-1080p.xpi` |

Nix hata çıktısı uzun olur; asıl bilgi en **alttaki** birkaç satırdadır. Daha
fazla bağlam için `--show-trace` ekle:

```bash
nix eval --show-trace .#nixosConfigurations.matebook.config.system.build.toplevel.drvPath
```

Kurulumdan sonra da aynı işi `nixos-rebuild dry-build --flake ~/nixos-config#matebook`
yapıyor — her değişiklikten sonra `rebuild` demeden önce alışkanlık hâline getir.

### 7. Kurulum

```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
nixos-install --flake /mnt/etc/nixos#matebook
```

İlk çalıştırmada `flake.lock` üretilir. Kurulum bitince `reboot`.

### 8. İlk açılış

- Kullanıcı: `can`, geçici parola: `nixos` (`users.nix` içindeki `initialPassword`).
- Hemen değiştir: `passwd`
- Yapılandırmayı ev dizinine taşı (alias'lar `~/nixos-config` bekliyor):
  ```bash
  sudo cp -r /etc/nixos ~/nixos-config && sudo chown -R can:$(id -gn) ~/nixos-config
  ```
  `.git` dizini de kopyalandığı için `origin` uzak deposu korunur.

- **Push edebilmek için:** kurulumda depo HTTPS ile klonlanıyor, yani `origin`
  salt okunur. Ayrıca disk sıfırlandığı için eski SSH anahtarların da gitmiş
  olacak. GitHub'a geri gönderebilmek için yeni bir anahtar üret ve ekle:
  ```bash
  ssh-keygen -t ed25519 -C "can@matebook"
  cat ~/.ssh/id_ed25519.pub          # çıktıyı github.com/settings/keys sayfasına ekle
  git -C ~/nixos-config remote set-url origin git@github.com:ycderman/matebook.git
  ```
  Aynı anahtarı homeserver'ın `authorized_keys` dosyasına eklemeyi de unutma.

## Günlük kullanım

```bash
rebuild        # sudo nixos-rebuild switch --flake ~/nixos-config#matebook
rebuild-test   # kalıcı olmayan deneme
rebuild-boot   # bir sonraki açılışta geçerli
update         # nix flake update --flake ~/nixos-config
```

Alias'lar `modules/home/shell.nix` içinde. Değişiklikten sonra
`nixos-rebuild dry-build --flake .#matebook` ile derlemeyi denemek iyi bir alışkanlık.

## Kurulum sonrası doğrulama

```bash
bootctl status                      # systemd-boot yüklü mü, ESP /boot mu
findmnt /boot /                      # label ile bağlanmış mı
systemctl status plasma-login-manager
vainfo                               # iHD sürücüsü (VA-API)
zramctl                              # zram takas — 8 GiB görünmeli
cat /sys/devices/platform/huawei-wmi/charge_control_thresholds   # 70 80
systemctl status power-profiles-daemon thermald
locale                               # hepsi tr_TR.UTF-8 olmalı (LC_CTYPE dahil)
type nix-shell                       # /etc/profiles/per-user/can/bin/nix-shell (sarmalayıcı)
nix-shell -p python3 --run "python3 -V"   # RANLİB hatası gelmemeli
```

Son iki satır birlikte anlamlı: `locale` çıktısında `LC_CTYPE=tr_TR.UTF-8`
görünmesine rağmen `nix-shell` çalışıyorsa, düzeltme doğru yerde — sistem dili
Türkçe kalmış, `C.UTF-8` yalnızca derleme ortamının içine verilmiş demektir.

## Verilen kararlar ve gerekçeleri

- **systemd-boot** — Manual: *"The recommended option is systemd-boot."*
  `grub.enable = false` açıkça yazıldı; `editor = false` ile boot menüsünden
  `init=/bin/sh` ile root olunması engellendi.
- **plasma-login-manager** — Wiki'nin KDE sayfasındaki
  `services.displayManager.plasma-login-manager.enable`. SDDM etkinleştirilmedi.
- **Wayland** — Plasma 6 varsayılan olarak Wayland'de çalışır, bu yüzden
  `defaultSession` ayarlanmadı; X11'e dönmek için `desktop.nix` içinde yorumlu satır var.
- **power-profiles-daemon, TLP değil** — Plasma'nın pil eklentisi doğrudan PPD ile
  konuşuyor; ikisi aynı ayarları yönettiği için birlikte çalıştırılmamalı.
- **zram = RAM** — `memoryPercent = 100`, yani 8 GiB RAM'e 8 GiB zram aygıtı.
  Bu, aygıtın azami boyutu; sıkıştırılmış veri yalnızca kullanıldığı kadar RAM tutar.
  Yanında `systemd.oomd` açık (wiki'nin zram ile birlikte önerdiği kombinasyon).
  Hazırda bekletme bu düzende mümkün değil.
- **`i915.enable_guc` yok** — Bu donanımda kernel zaten `adlp_guc` + `tgl_huc`
  yükleyip GuC submission'ı açıyor (dmesg ile doğrulandı), parametre gereksiz.
- **`i915.force_probe` yok** — `8086:46a3` çekirdek tarafından parametresiz tanınıyor.
- **`thunderbolt` initrd modülü yok** — makinede Thunderbolt/USB4 bulunmuyor
  (yukarıdaki kontrol).
- **Panelde `showdesktop` yok, pager de çıkarıldı** — uygulama menüsünden sonraki
  ilk ikonun Konsole olması için. Masaüstleri arası geçiş `Meta+1..4`.

## Kaynaklar

Yapılandırma NixOS'un kendi kaynaklarına dayanıyor:

- [NixOS Manual (stable)](https://nixos.org/manual/nixos/stable/) — bölümleme,
  label kullanımı, UEFI kurulumu, systemd-boot önerisi
- [NixOS Wiki — Flakes](https://wiki.nixos.org/wiki/Flakes)
- [NixOS Wiki — Home Manager](https://wiki.nixos.org/wiki/Home_Manager)
- [NixOS Wiki — KDE](https://wiki.nixos.org/wiki/KDE)
- [NixOS Wiki — Firefox](https://wiki.nixos.org/wiki/Firefox)
- [NixOS Wiki — Intel Graphics](https://wiki.nixos.org/wiki/Intel_Graphics)
- [NixOS Wiki — PipeWire](https://wiki.nixos.org/wiki/PipeWire)
- [NixOS Wiki — Bluetooth](https://wiki.nixos.org/wiki/Bluetooth)
- [NixOS Wiki — Laptop](https://wiki.nixos.org/wiki/Laptop)
- [NixOS Wiki — Swap](https://wiki.nixos.org/wiki/Swap)
- [NixOS Wiki — Storage optimization](https://wiki.nixos.org/wiki/Storage_optimization)
- [NixOS Wiki — Fwupd](https://wiki.nixos.org/wiki/Fwupd)

**İki istisna, ikisi de bilerek:**

1. `plasma-manager`, NixOS Wiki'nin KDE sayfasının açıkça belirttiği gibi bir
   topluluk projesi ve nixpkgs'in parçası değil; seçenekleri için resmi NixOS
   belgesi yok. Seçenek adlarını uydurmamak için wiki'nin işaret ettiği projenin
   kendi kaynak dosyaları (`modules/powerdevil.nix`, `modules/kscreenlocker.nix`,
   `modules/widgets/icon-tasks.nix`, `examples/home.nix`) okundu.
2. Proton Pass eklentisinin kimliği, `addons.mozilla.org` API'sinden doğrulandı —
   bu bir NixOS konusu değil, eklentinin kendi kimliği.
