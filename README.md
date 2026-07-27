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
├── flake.lock                   # test edilmiş girdi sürümleri (depoya işlendi)
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

## Doğrulama durumu

Bu yapılandırma gerçek `nix` ile değerlendirildi — tahmin değil, ölçüm:

```
$ nix eval github:ycderman/matebook#nixosConfigurations.matebook.config.system.build.toplevel.drvPath
"/nix/store/p0s0jsxm0qvnz7s6zmwf1fdmqqc2b9rn-nixos-system-matebook-26.11.20260726.624af66.drv"

$ nix build --dry-run github:ycderman/matebook#nixosConfigurations.matebook.config.system.build.toplevel
these 388 derivations will be built            ← hepsi systemd unit / udev kuralı gibi
                                                 önemsiz yapılandırma dosyaları
these 1714 paths will be fetched (4.9 GiB download, 13.0 GiB unpacked)
```

- Sıfır hata, sıfır kullanımdan kaldırma uyarısı.
- Ağır hiçbir paket kaynaktan derlenmiyor; her şey resmi ikili önbellekten geliyor.
- `flake.lock` depoya işlendi, yani kurulumda tam olarak bu sürümler kullanılacak
  (nixpkgs `624af66`, home-manager `cbb7767`, plasma-manager `c551f06`).

Bu doğrulama sırasında bulunup düzeltilen gerçek hatalar:

| Hata | Düzeltme |
|---|---|
| `programs.plasma.workspace.clickItemTo = "click"` geçersiz | `"select"` (geçerli değerler: `open`, `select`) |
| `glxinfo` paketi yeniden adlandırılmış | `mesa-demos` |
| `noto-fonts-emoji` yeniden adlandırılmış | `noto-fonts-color-emoji` |
| `programs.git.{userName,userEmail,extraConfig}` taşınmış | `programs.git.settings` altında |
| `nixfmt-rfc-style` artık gereksiz | `nixfmt` |

Doğrulamanın **kapsamadığı** şey: çalışma zamanı davranışı. Değerlendirme,
`plasma-login-manager`'ın gerçekten açılacağını ya da `huawei-wmi` udev
kuralının pil eşiğini yazacağını kanıtlamaz — onlar ancak kurulumdan sonra
"Kurulum sonrası doğrulama" bölümündeki komutlarla görülür.

---

# Kurulum Kılavuzu

Sıfırdan, adım adım. NixOS'a yeni başlayanlar için her komutun ne yaptığı yazılı.

> **UYARI:** Bu kılavuz `/dev/nvme0n1` diskini **tamamen siler** — mevcut Arch
> kurulumu (btrfs `archlinux` bölümü) ve içindeki her şey gider. Devam etmeden
> önce ev dizinini harici bir diske yedekle:
> ```bash
> rsync -aAXv --exclude={.cache,.local/share/Trash} /home/can/ /mnt/yedek/can/
> ```
> Ayrıca şunları ayrıca not et: Wi-Fi parolaları, SSH özel anahtarları
> (`~/.ssh/`), tarayıcı profili, GPG anahtarları.

## Adım 0 — Hazırlık

**Gerekenler**

- NixOS **minimal ISO** yazılmış bir USB bellek (en az 2 GB)
- İnternet: kurulum sırasında ~5 GB indirilecek, kablolu bağlantı varsa tercih et
- Şarj adaptörü takılı olsun

**ISO'yu USB'ye yazma** (hâlâ Arch'tayken):

```bash
curl -LO https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso
lsblk                                    # USB'nin hangi aygıt olduğunu doğrula
sudo dd if=latest-nixos-minimal-x86_64-linux.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

`of=` hedefini iki kere kontrol et — yanlış aygıt yazarsan diski kaybedersin.

**BIOS ayarları** (açılışta `F2`)

- Secure Boot: **kapalı** (bu yapılandırma imzalı önyükleme kullanmıyor)
- Boot mode: **UEFI** (CSM/Legacy kapalı)
- Boot menu: `F12`

## Adım 1 — ISO'yu başlat ve ortamı hazırla

Açılan menüden ilk seçeneği seç. Kabuğa düşünce root ol:

```bash
sudo -i
```

Türkçe klavye (ISO varsayılan olarak US düzeninde açılır):

```bash
loadkeys trq
```

> Klavye düzenini değiştirmezsen `/` ve `-` gibi karakterler beklediğin tuşta
> olmaz. Değiştirmek istemiyorsan da sorun değil, sadece US düzenine göre yaz.

UEFI modunda açıldığını doğrula — çıktı boşsa **dur**, BIOS'a dönüp CSM'yi kapat:

```bash
ls /sys/firmware/efi && echo "UEFI: TAMAM"
```

## Adım 2 — Ağ bağlantısı

**Kablolu:** otomatik gelir, bir şey yapman gerekmez.

**Wi-Fi:**

```bash
systemctl start wpa_supplicant
wpa_cli
> add_network
0
> set_network 0 ssid "AG_ADI"
> set_network 0 psk "PAROLA"
> enable_network 0
> quit
```

Bağlantıyı test et:

```bash
ping -c3 nixos.org
```

## Adım 3 — Diski doğrula

**Yanlış diski silmemek için** hedefi kesin olarak teyit et:

```bash
lsblk -o NAME,SIZE,MODEL,LABEL
```

Beklenen çıktı: `nvme0n1` — 476.9G — `WD PC SN740 SDDPNQD-512G`. USB belleğin
`sda` veya `sdb` olarak görünecek; ona dokunma.

Eski dosya sistemi imzalarını temizle (disk btrfs'ti, kalıntı imzalar
`blkid`'yi yanıltabilir):

```bash
wipefs -a /dev/nvme0n1
```

## Adım 4 — Bölümleme

2 GiB EFI Sistem Bölümü + kalanın tamamı kök bölüm:

```bash
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 2049MiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart root ext4 2049MiB 100%
```

Satır satır ne yapıyor:

| Komut | Anlamı |
|---|---|
| `mklabel gpt` | GPT bölüm tablosu oluşturur (UEFI için şart) |
| `mkpart ESP fat32 1MiB 2049MiB` | 1 MiB'den 2049 MiB'ye = tam 2 GiB ESP |
| `set 1 esp on` | 1. bölüme ESP bayrağını koyar — **atlanırsa firmware bölümü görmez** |
| `mkpart root ext4 2049MiB 100%` | Diskin geri kalanı kök bölüm |

Kontrol:

```bash
parted /dev/nvme0n1 -- print
```

## Adım 5 — Biçimlendirme (label'lar kritik)

```bash
mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
mkfs.ext4 -L nixos     /dev/nvme0n1p2
```

`hosts/matebook/hardware.nix` dosya sistemlerini **UUID ile değil label ile**
tanımlıyor, bu yüzden label'lar birebir tutmalı:

| Beklenen label | Nerede tanımlı |
|---|---|
| `BOOT` (büyük harf) | `fileSystems."/boot".device = "/dev/disk/by-label/BOOT"` |
| `nixos` (küçük harf) | `fileSystems."/".device = "/dev/disk/by-label/nixos"` |

> `mkfs.fat` label'ın büyük/küçük harfini olduğu gibi saklar (küçük harfte
> sadece uyarı verir). `-n boot` yazarsan `/dev/disk/by-label/BOOT` hiç
> oluşmaz; kurulum sorunsuz biter ama **ilk açılışta sistem acil durum moduna
> düşer.** ext4 de harf duyarlıdır.

Doğrula — iki label da görünmeli:

```bash
lsblk -o NAME,FSTYPE,LABEL
```

## Adım 6 — Bağlama

```bash
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount -o umask=077 /dev/disk/by-label/BOOT /mnt/boot
```

`umask=077`, ESP'yi root dışındaki kullanıcılara kapatır — orada şifrelenmemiş
çekirdek ve initrd duruyor. Kontrol:

```bash
findmnt /mnt /mnt/boot
```

## Adım 7 — Yapılandırmayı klonla

```bash
nix-shell -p git
git clone https://github.com/ycderman/matebook.git /mnt/etc/nixos
cd /mnt/etc/nixos
```

`nixos-generate-config` çalıştırmana **gerek yok**: `hosts/matebook/hardware.nix`
bu makinenin donanımına göre elle yazıldı ve üretilecek dosyanın yerine geçiyor.

Depo git deposu olarak geldiği için flake bütün dosyaları görüyor. Kurulum
sırasında yerel bir düzenleme yaparsan, flake'in görmesi için önce git'e bildir:

```bash
git add -A
```

## Adım 8 — Kurulumdan önce doğrula

Bu adım diske hiçbir şey yazmaz; amacı hatalı bir seçeneği kurulum başlamadan
yakalamak. Önce flake'leri aç:

```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
```

**Asıl kontrol — sadece değerlendirme, hiçbir şey derlemez:**

```bash
nix eval .#nixosConfigurations.matebook.config.system.build.toplevel.drvPath
```

Çıktı `/nix/store/....drv` biçiminde bir yolsa yapılandırma sağlam. Bu tek komut
`hosts/`, `modules/nixos/` ve `modules/home/` dizinlerinin tamamını kapsıyor:
Home Manager bir NixOS modülü olarak bağlandığı için home-manager ve
plasma-manager seçenekleri de aynı değerlendirmeye giriyor.

İsteğe bağlı ek kontroller:

```bash
nix flake check --no-build                    # flake çıktılarının yapısı
nix build --dry-run .#nixosConfigurations.matebook.config.system.build.toplevel
```

### Hata mesajlarını okumak

Nix hata çıktısı uzundur; **asıl bilgi en alttaki birkaç satırdadır.**

| Mesaj | Anlamı | Ne yapmalı |
|---|---|---|
| ``The option `services.foo.bar' does not exist`` | Seçenek adı yanlış ya da yeniden adlandırılmış | [search.nixos.org/options](https://search.nixos.org/options?channel=unstable) |
| `A definition for option '...' is not of type '...'` | Değerin tipi yanlış | Hata satırındaki dosyayı düzelt |
| `attribute 'xyz' missing` | `pkgs.xyz` diye paket yok | [search.nixos.org/packages](https://search.nixos.org/packages?channel=unstable) |
| `'x' has been renamed to/replaced by 'y'` | Paket adı değişmiş | `y` yaz |
| `infinite recursion encountered` | Bir seçenek dolaylı olarak kendini tanımlıyor | İzdeki modülde `config.` kullanımına bak |
| `error: path '/nix/store/...' does not exist` + `.xpi` | `tvplus-1080p.xpi` git'e eklenmemiş | `git add modules/nixos/tvplus-1080p.xpi` |

Daha fazla bağlam için `--show-trace` ekle.

## Adım 9 — Kurulum

```bash
nixos-install --flake .#matebook
```

- `--root` varsayılanı `/mnt`, ayrıca vermene gerek yok.
- Yaklaşık 5 GB indirilecek; kablolu bağlantıda 10-20 dakika sürer.
- **Son adımda root parolası sorulacak — mutlaka bir parola belirle.**
  Yapılandırma root parolasını bilerek tanımlamıyor (bkz. `modules/nixos/users.nix`),
  o yüzden burada verdiğin parola kalıcı; sonraki `rebuild`'lerde geri alınmaz.
  Sistem bir gün acil durum moduna düşerse tek kurtarma yolu bu parola, çünkü
  `boot.loader.systemd-boot.editor = false` çekirdek satırını düzenlemeyi kapatıyor.

Bittiğinde:

```bash
reboot
```

USB belleği çıkarmayı unutma.

## Adım 10 — İlk açılış

Plasma Login Manager açılmalı. Kullanıcı `can`, parola `nixos`.

Sırayla:

```bash
passwd                       # 1. can'in geçici parolasını değiştir
sudo passwd root             # 2. istersen root parolasını da tazele
```

Yapılandırmayı ev dizinine al — kabuk kısayolları `~/nixos-config` bekliyor:

```bash
sudo cp -r /etc/nixos ~/nixos-config
sudo chown -R can:$(id -gn) ~/nixos-config
```

`.git` dizini de kopyalandığı için `origin` korunur. Push edebilmek için yeni
bir SSH anahtarı gerekiyor (eski anahtarların diskle birlikte silindi):

```bash
ssh-keygen -t ed25519 -C "can@matebook"
cat ~/.ssh/id_ed25519.pub        # çıktıyı github.com/settings/keys sayfasına ekle
git -C ~/nixos-config remote set-url origin git@github.com:ycderman/matebook.git
```

Aynı anahtarı homeserver'ın `authorized_keys` dosyasına eklemeyi de unutma.

## Adım 11 — Bir şeyler ters giderse

**Sistem açılmıyor / acil durum moduna düşüyor.** En sık sebebi yanlış disk
label'ı. Boot menüsünde (`systemd-boot`, açılışta boşluk tuşu) önceki kuşağı
seçebilirsin — ama bu ilk kurulumsa önceki kuşak yoktur. O zaman ISO'dan aç,
bölümleri bağla ve label'ları düzelt:

```bash
mount /dev/disk/by-label/nixos /mnt && mount /dev/disk/by-label/BOOT /mnt/boot
# veya label yanlışsa: fatlabel /dev/nvme0n1p1 BOOT
```

**`rebuild` hata veriyor.** Sistem bozulmaz — `nixos-rebuild switch` başarısız
olursa çalışan sistem olduğu gibi kalır. Hatayı düzeltip tekrar dene.

**Kötü bir değişikliği geri almak.** Her `rebuild` yeni bir kuşak oluşturur:

```bash
sudo nixos-rebuild switch --rollback     # bir önceki kuşağa dön
nixos-rebuild list-generations           # kuşakları listele
```

Açılmayan bir kuşak varsa boot menüsünden eski kuşağı seçmen yeterli.

**Kurulumu baştan yapmak.** Adım 4'ten itibaren tekrarla; yapılandırma GitHub'da
durduğu için hiçbir şey kaybolmaz.

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
- **`can` için parolasız sudo** — grup geneli `wheelNeedsPassword = false` yerine
  `security.sudo.extraRules` ile tek kullanıcıya bağlandı; wheel grubunun genel
  kuralı parolalı kaldı. Nixpkgs'te wheel kuralı `mkOrder 600`, kullanıcı
  kuralları varsayılan 1000 ile geldiği için bizimki sudoers'a sonra yazılıyor
  ve son eşleşen kural kazandığından `NOPASSWD` geçerli oluyor.

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
