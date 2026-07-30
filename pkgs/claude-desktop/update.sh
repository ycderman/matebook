#!/usr/bin/env bash
# claude-desktop'ı yeni bir sürüme günceller: URL'deki ${version}'ı değiştirip
# `nix store prefetch-file` ile doğru hash'i otomatik hesaplar ve default.nix'i
# yerinde düzenler. Elle sha256sum hesaplamaya/yapıştırmaya gerek yok.
#
# Kullanım:
#   ./update.sh 1.24013.0
#   ./update.sh                 # sürüm verilmezse yalnızca mevcut sürümün
#                                # hash'ini yeniden doğrular (no-op olması beklenir)
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pkgfile="default.nix"
current_version=$(sed -nE 's/^\s*version = "([^"]+)";/\1/p' "$pkgfile")
new_version="${1:-$current_version}"

url="https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${new_version}_amd64.deb"

echo "claude-desktop: ${current_version} -> ${new_version}" >&2
echo "prefetching: ${url}" >&2

hash=$(nix store prefetch-file --json "$url" | jq -r '.hash')

if [[ -z "$hash" || "$hash" == "null" ]]; then
  echo "hata: hash alınamadı (sürüm ${new_version} için .deb yayınlanmamış olabilir)" >&2
  exit 1
fi

sed -i -E "s/version = \"[^\"]+\";/version = \"${new_version}\";/" "$pkgfile"
sed -i -E "s#hash = \"[^\"]+\";#hash = \"${hash}\";#" "$pkgfile"

echo "güncellendi: version = \"${new_version}\"; hash = \"${hash}\";" >&2
echo "sırada: cd ~/nixos-config && git add pkgs/claude-desktop/default.nix && rebuild" >&2
