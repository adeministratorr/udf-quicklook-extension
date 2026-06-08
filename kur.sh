#!/usr/bin/env bash
# kur.sh — UDF QuickLook + Görüntüleyici uygulamasını kaynaktan derleyip kurar.
# Yalnızca Xcode Command Line Tools yeterlidir (tam Xcode GEREKMEZ); betik gerekirse
# onu kendisi kurar. İki şekilde çalışır:
#   curl -fsSL https://raw.githubusercontent.com/saidsurucu/udf-quicklook-extension/main/kur.sh | bash
#   ya da depo içinde:  ./kur.sh
set -euo pipefail

REPO_URL="https://github.com/saidsurucu/udf-quicklook-extension.git"
CLONE_DIR="$HOME/udf-quicklook-extension"
APP="UDFViewer.app"
DEST="/Applications/$APP"

if [ -t 1 ]; then
  BOLD=$'\033[1m'; GRN=$'\033[32m'; YLW=$'\033[33m'; RED=$'\033[31m'; BLU=$'\033[34m'; RST=$'\033[0m'
else BOLD=""; GRN=""; YLW=""; RED=""; BLU=""; RST=""; fi
say()  { printf '%s\n' "${BLU}›${RST} $*"; }
ok()   { printf '%s\n' "${GRN}✓${RST} $*"; }
warn() { printf '%s\n' "${YLW}!${RST} $*"; }
die()  { printf '%s\n' "${RED}✗ $*${RST}" >&2; exit 1; }
step() { printf '\n%s\n' "${BOLD}== $* ==${RST}"; }

[ "$(uname -s)" = "Darwin" ] || die "Bu betik yalnızca macOS içindir."

# --- Xcode Command Line Tools (git, swift, codesign) — gerekirse kur ---
ensure_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    ok "Komut satırı araçları zaten kurulu"
    return
  fi
  warn "Komut satırı araçları yok; kurulum penceresi açılıyor…"
  xcode-select --install >/dev/null 2>&1 || true
  say "Açılan pencerede ${BOLD}\"Yükle\"${RST}ye basıp bitmesini bekleyin."
  say "Kurulum tamamlanınca betik kendiliğinden devam edecek…"
  until xcode-select -p >/dev/null 2>&1; do printf '.'; sleep 5; done
  printf '\n'; ok "Komut satırı araçları kuruldu"
}

# --- Bootstrap: depo içinde değilsek indir ve oradaki kur.sh'yi çalıştır ---
SRC="${BASH_SOURCE[0]:-}"; SCRIPT_DIR=""
if [ -n "$SRC" ] && [ -f "$SRC" ]; then SCRIPT_DIR="$(cd "$(dirname "$SRC")" && pwd)"; fi
if [ -z "$SCRIPT_DIR" ] || [ ! -f "$SCRIPT_DIR/Package.swift" ]; then
  step "Geliştirici araçları (bir kez)"
  ensure_clt
  step "Kaynak kodun indirilmesi"
  command -v git >/dev/null 2>&1 || die "git bulunamadı (komut satırı araçları eksik olabilir)."
  if [ -d "$CLONE_DIR/.git" ]; then
    git -C "$CLONE_DIR" pull --ff-only --quiet || warn "Güncelleme atlandı; mevcut sürümle devam."
  else
    [ -e "$CLONE_DIR" ] && die "$CLONE_DIR var ama git deposu değil. Taşıyın/silin."
    git clone --depth 1 "$REPO_URL" "$CLONE_DIR" --quiet
  fi
  ok "Kaynak kod hazır"
  exec bash "$CLONE_DIR/kur.sh"
fi
cd "$SCRIPT_DIR"

# --- Geliştirici araçları ---
step "Geliştirici araçları denetimi"
ensure_clt
command -v swift >/dev/null 2>&1 || die "swift bulunamadı (komut satırı araçları eksik olabilir)."
ok "swift bulundu: $(swift --version 2>/dev/null | head -1)"

# --- Derleme (SwiftPM + elle paketleme + ad-hoc imza) ---
step "Derleme (birkaç dakika sürebilir)"
bash "$SCRIPT_DIR/scripts/build.sh"
BUILT="$SCRIPT_DIR/build/$APP"
[ -d "$BUILT" ] || die "Uygulama üretilemedi: $BUILT"
ok "Derlendi: $BUILT"

# --- Applications'a kurulum ---
step "Applications'a kurulum"
osascript -e 'tell application "UDFViewer" to quit' >/dev/null 2>&1 || true
if [ -e "$DEST" ]; then rm -rf "$DEST" 2>/dev/null || sudo rm -rf "$DEST"; fi
# ditto preserves code signatures + bundle symlinks (cp -R can corrupt them)
if ditto "$BUILT" "$DEST" 2>/dev/null; then ok "Kuruldu: $DEST"
else warn "/Applications yazılamadı; yönetici izniyle…"; sudo ditto "$BUILT" "$DEST"; ok "Kuruldu: $DEST"; fi

# --- Derleme kopyasını temizle (yoksa LaunchServices build/ içindeki kopyayı
#     /Applications yerine kaydedebilir ve eski sürüm gösterilir) ---
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
"$LSREGISTER" -u "$BUILT" 2>/dev/null || true
rm -rf "$SCRIPT_DIR/build" 2>/dev/null || true

# --- QuickLook eklentilerini kaydet ve etkinleştir ---
step "QuickLook eklentilerinin kaydı"
"$LSREGISTER" -f "$DEST" || true
pluginkit -a "$DEST/Contents/PlugIns/QuickLookPreview.appex" 2>/dev/null || true
pluginkit -a "$DEST/Contents/PlugIns/QuickLookThumbnail.appex" 2>/dev/null || true
pluginkit -e use -i com.uyapudf.viewer.QuickLookPreview 2>/dev/null || true
pluginkit -e use -i com.uyapudf.viewer.QuickLookThumbnail 2>/dev/null || true
# Eski sürümü güncellerken çalışan eklenti süreçlerini durdur ki yeni ikili yüklensin
pkill -9 -f "QuickLookPreview" 2>/dev/null || true
pkill -9 -f "QuickLookThumbnail" 2>/dev/null || true
killall -9 quicklookd "com.apple.quicklook.ThumbnailsAgent" 2>/dev/null || true
open -g "$DEST" 2>/dev/null || true
qlmanage -r >/dev/null 2>&1 || true
qlmanage -r cache >/dev/null 2>&1 || true
ok "Eklentiler kaydedildi"

printf '\n'
ok "${BOLD}BİTTİ.${RST} Artık bir .udf dosyasına Finder'da ${BOLD}boşluk (space)${RST} tuşuyla önizleme açabilir,"
say "çift tıklayarak görüntüleyebilir, görüntüleyicideki ${BOLD}\"UYAP Editöründe Aç\"${RST} düğmesiyle editöre geçebilirsiniz."
warn "Önizleme görünmezse: Sistem Ayarları → Genel → Giriş Öğeleri ve Uzantılar → Hızlı Bakış → \"UDFViewer\" işaretli olmalı."
