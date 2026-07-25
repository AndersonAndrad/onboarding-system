#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# Mac Clean
#
# Comandos:
#   ./mac-clean.sh report
#   ./mac-clean.sh analyze
#   ./mac-clean.sh doctor
#   ./mac-clean.sh clean
#   ./mac-clean.sh deep
#   ./mac-clean.sh schedule
#   ./mac-clean.sh unschedule
#   ./mac-clean.sh help
#
# O comando padrão é "report".
# ============================================================

COMMAND="${1:-report}"

CACHE_DAYS="${CACHE_DAYS:-14}"
LOG_DAYS="${LOG_DAYS:-14}"
TRASH_DAYS="${TRASH_DAYS:-7}"
DERIVED_DATA_DAYS="${DERIVED_DATA_DAYS:-7}"
XCODE_ARCHIVE_DAYS="${XCODE_ARCHIVE_DAYS:-30}"

SCRIPT_NAME="mac-clean.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_NAME}"

INSTALL_DIR="$HOME/.local/bin"
INSTALL_PATH="$INSTALL_DIR/mac-clean.sh"

LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$LAUNCH_AGENT_DIR/com.anderson.mac-clean.plist"

LOG_DIR="$HOME/Library/Logs/mac-clean"
STDOUT_LOG="$LOG_DIR/stdout.log"
STDERR_LOG="$LOG_DIR/stderr.log"

BOLD=$'\033[1m'
DIM=$'\033[2m'
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BLUE=$'\033[34m'
CYAN=$'\033[36m'
RESET=$'\033[0m'

# ============================================================
# Funções utilitárias
# ============================================================

title() {
  echo
  echo "${BOLD}${BLUE}============================================================${RESET}"
  echo "${BOLD}${BLUE}$1${RESET}"
  echo "${BOLD}${BLUE}============================================================${RESET}"
}

section() {
  echo
  echo "${BOLD}${CYAN}$1${RESET}"
}

success() {
  echo "${GREEN}✔ $1${RESET}"
}

warning() {
  echo "${YELLOW}⚠ $1${RESET}"
}

error() {
  echo "${RED}✖ $1${RESET}" >&2
}

info() {
  echo "${BLUE}• $1${RESET}"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

disk_free() {
  df -h / | awk 'NR == 2 {print $4}'
}

disk_used() {
  df -h / | awk 'NR == 2 {print $3}'
}

disk_capacity() {
  df -h / | awk 'NR == 2 {print $2}'
}

disk_percent() {
  df -h / | awk 'NR == 2 {print $5}'
}

human_size() {
  local path="$1"

  if [[ -e "$path" ]]; then
    du -sh "$path" 2>/dev/null | awk '{print $1}'
  else
    echo "0B"
  fi
}

size_in_kb() {
  local path="$1"

  if [[ -e "$path" ]]; then
    du -sk "$path" 2>/dev/null | awk '{print $1}'
  else
    echo "0"
  fi
}

kb_to_human() {
  local kb="${1:-0}"

  awk -v kb="$kb" '
    function human(x) {
      if (x >= 1048576) {
        return sprintf("%.1f TB", x / 1048576)
      }

      if (x >= 1024) {
        return sprintf("%.1f GB", x / 1024)
      }

      return sprintf("%.1f MB", x)
    }

    BEGIN {
      print human(kb)
    }
  '
}

show_item() {
  local label="$1"
  local path="$2"

  printf "%-40s %10s  %s\n" \
    "$label" \
    "$(human_size "$path")" \
    "$path"
}

safe_find_delete_old_items() {
  local path="$1"
  local days="$2"

  [[ -d "$path" ]] || return 0

  find "$path" \
    -mindepth 1 \
    -maxdepth 1 \
    -mtime "+$days" \
    -exec rm -rf -- {} + \
    2>/dev/null || true
}

confirm() {
  local message="$1"
  local answer

  read -r -p "$message [s/N]: " answer

  case "$answer" in
    s|S|sim|SIM|Sim)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

show_disk_summary() {
  printf "%-20s %s\n" "Capacidade:" "$(disk_capacity)"
  printf "%-20s %s\n" "Usado:" "$(disk_used)"
  printf "%-20s %s\n" "Livre:" "$(disk_free)"
  printf "%-20s %s\n" "Percentual usado:" "$(disk_percent)"
}

# ============================================================
# Relatório
# ============================================================

report() {
  title "Mac Clean — relatório"

  section "Armazenamento"
  show_disk_summary

  section "Caches e ferramentas"

  show_item "Caches do usuário" "$HOME/Library/Caches"
  show_item "Logs do usuário" "$HOME/Library/Logs"

  show_item \
    "Xcode DerivedData" \
    "$HOME/Library/Developer/Xcode/DerivedData"

  show_item \
    "Xcode Archives" \
    "$HOME/Library/Developer/Xcode/Archives"

  show_item \
    "Simuladores iOS" \
    "$HOME/Library/Developer/CoreSimulator"

  show_item \
    "Device Support do Xcode" \
    "$HOME/Library/Developer/Xcode/iOS DeviceSupport"

  show_item \
    "Swift Package Manager" \
    "$HOME/Library/Caches/org.swift.swiftpm"

  show_item \
    "CocoaPods" \
    "$HOME/Library/Caches/CocoaPods"

  show_item "npm" "$HOME/.npm"
  show_item "Yarn" "$HOME/Library/Caches/Yarn"
  show_item "pnpm" "$HOME/Library/pnpm/store"
  show_item "Bun" "$HOME/.bun/install/cache"

  show_item "Gradle" "$HOME/.gradle/caches"
  show_item "Android" "$HOME/.android"
  show_item "Android SDK" "$HOME/Library/Android/sdk"

  show_item "Homebrew" "$HOME/Library/Caches/Homebrew"
  show_item "Carthage" "$HOME/Library/Caches/org.carthage.CarthageKit"

  show_item \
    "Application Support" \
    "$HOME/Library/Application Support"

  show_item \
    "Containers do macOS" \
    "$HOME/Library/Containers"

  show_item \
    "Group Containers" \
    "$HOME/Library/Group Containers"

  show_item \
    "Mail Downloads" \
    "$HOME/Library/Containers/com.apple.mail/Data/Library/Mail Downloads"

  show_item \
    "Anexos do Messages" \
    "$HOME/Library/Messages/Attachments"

  show_item \
    "Caches do Chrome" \
    "$HOME/Library/Caches/Google/Chrome"

  show_item \
    "Caches do Chromium" \
    "$HOME/Library/Caches/Chromium"

  show_item \
    "Caches do VS Code" \
    "$HOME/Library/Application Support/Code/Cache"

  show_item \
    "VS Code CachedData" \
    "$HOME/Library/Application Support/Code/CachedData"

  show_item \
    "Caches do Cursor" \
    "$HOME/Library/Application Support/Cursor/Cache"

  show_item \
    "Cursor CachedData" \
    "$HOME/Library/Application Support/Cursor/CachedData"

  show_item "Lixeira" "$HOME/.Trash"
  show_item "Downloads" "$HOME/Downloads"

  if command_exists docker && docker info >/dev/null 2>&1; then
    section "Docker"
    docker system df || true
  else
    section "Docker"
    echo "Docker não está instalado ou não está em execução."
  fi

  section "Snapshots locais do Time Machine"

  if command_exists tmutil; then
    tmutil listlocalsnapshots / 2>/dev/null ||
      echo "Nenhum snapshot local encontrado."
  else
    echo "tmutil não está disponível."
  fi

  echo
  info "Nenhum arquivo foi apagado."
}

# ============================================================
# Análise
# ============================================================

analyze_home_directories() {
  section "Maiores diretórios da sua pasta pessoal"

  du -xhd 1 "$HOME" 2>/dev/null |
    sort -hr |
    head -n 25 ||
    true
}

analyze_library_directories() {
  section "Maiores diretórios em ~/Library"

  du -xhd 1 "$HOME/Library" 2>/dev/null |
    sort -hr |
    head -n 30 ||
    true
}

analyze_application_support() {
  local path="$HOME/Library/Application Support"

  [[ -d "$path" ]] || return 0

  section "Maiores diretórios em Application Support"

  du -xhd 1 "$path" 2>/dev/null |
    sort -hr |
    head -n 30 ||
    true
}

analyze_containers() {
  local path="$HOME/Library/Containers"

  [[ -d "$path" ]] || return 0

  section "Maiores containers do macOS"

  du -xhd 1 "$path" 2>/dev/null |
    sort -hr |
    head -n 25 ||
    true
}

analyze_group_containers() {
  local path="$HOME/Library/Group Containers"

  [[ -d "$path" ]] || return 0

  section "Maiores Group Containers"

  du -xhd 1 "$path" 2>/dev/null |
    sort -hr |
    head -n 25 ||
    true
}

analyze_large_files() {
  section "Maiores arquivos acima de 500 MB"

  find "$HOME" \
    -xdev \
    -type f \
    -size +500M \
    -print0 \
    2>/dev/null |
    xargs -0 du -h 2>/dev/null |
    sort -hr |
    head -n 30 ||
    true
}

analyze_downloads() {
  local path="$HOME/Downloads"

  [[ -d "$path" ]] || return 0

  section "Maiores itens em Downloads"

  du -xhd 1 "$path" 2>/dev/null |
    sort -hr |
    head -n 20 ||
    true
}

analyze_developer_folders() {
  section "Pastas de desenvolvimento ocultas"

  local directories=(
    "$HOME/.docker"
    "$HOME/.npm"
    "$HOME/.pnpm-store"
    "$HOME/.gradle"
    "$HOME/.android"
    "$HOME/.cache"
    "$HOME/.bun"
    "$HOME/.cargo"
    "$HOME/.rustup"
    "$HOME/.m2"
    "$HOME/.ivy2"
    "$HOME/.nuget"
    "$HOME/.vscode"
  )

  local path

  for path in "${directories[@]}"; do
    show_item "$(basename "$path")" "$path"
  done
}

analyze() {
  title "Mac Clean — análise completa"

  section "Armazenamento"
  show_disk_summary

  analyze_home_directories
  analyze_library_directories
  analyze_application_support
  analyze_containers
  analyze_group_containers
  analyze_developer_folders
  analyze_downloads
  analyze_large_files

  section "Análise do volume de dados"

  echo "Para analisar todo o volume do macOS, execute:"
  echo
  echo "  sudo du -xhd 1 /System/Volumes/Data | sort -hr"
  echo
  echo "Esse comando exige senha de administrador."
}

# ============================================================
# Doctor
# ============================================================

doctor_check_path() {
  local label="$1"
  local path="$2"
  local warning_kb="$3"
  local critical_kb="$4"

  local current_kb
  current_kb="$(size_in_kb "$path")"

  if (( current_kb >= critical_kb )); then
    printf "${RED}🔴 %-32s %10s${RESET}\n" \
      "$label" \
      "$(kb_to_human "$current_kb")"

    return 2
  fi

  if (( current_kb >= warning_kb )); then
    printf "${YELLOW}🟡 %-32s %10s${RESET}\n" \
      "$label" \
      "$(kb_to_human "$current_kb")"

    return 1
  fi

  printf "${GREEN}🟢 %-32s %10s${RESET}\n" \
    "$label" \
    "$(kb_to_human "$current_kb")"

  return 0
}

doctor() {
  title "Mac Clean — doctor"

  section "Armazenamento"
  show_disk_summary

  section "Diagnóstico"

  local estimated_reclaim_kb=0
  local current_kb

  doctor_check_path \
    "Caches do usuário" \
    "$HOME/Library/Caches" \
    $((5 * 1024 * 1024)) \
    $((10 * 1024 * 1024)) ||
    true

  doctor_check_path \
    "Yarn" \
    "$HOME/Library/Caches/Yarn" \
    $((1 * 1024 * 1024)) \
    $((4 * 1024 * 1024)) ||
    true

  doctor_check_path \
    "npm" \
    "$HOME/.npm" \
    $((1 * 1024 * 1024)) \
    $((3 * 1024 * 1024)) ||
    true

  doctor_check_path \
    "pnpm" \
    "$HOME/Library/pnpm/store" \
    $((1 * 1024 * 1024)) \
    $((5 * 1024 * 1024)) ||
    true

  doctor_check_path \
    "Homebrew" \
    "$HOME/Library/Caches/Homebrew" \
    $((1 * 1024 * 1024)) \
    $((3 * 1024 * 1024)) ||
    true

  doctor_check_path \
    "Xcode DerivedData" \
    "$HOME/Library/Developer/Xcode/DerivedData" \
    $((2 * 1024 * 1024)) \
    $((10 * 1024 * 1024)) ||
    true

  doctor_check_path \
    "Simuladores iOS" \
    "$HOME/Library/Developer/CoreSimulator" \
    $((5 * 1024 * 1024)) \
    $((20 * 1024 * 1024)) ||
    true

  doctor_check_path \
    "Gradle" \
    "$HOME/.gradle/caches" \
    $((2 * 1024 * 1024)) \
    $((10 * 1024 * 1024)) ||
    true

  doctor_check_path \
    "Lixeira" \
    "$HOME/.Trash" \
    $((1 * 1024 * 1024)) \
    $((5 * 1024 * 1024)) ||
    true

  local reclaimable_paths=(
    "$HOME/Library/Caches"
    "$HOME/.npm/_cacache"
    "$HOME/Library/Caches/Yarn"
    "$HOME/Library/pnpm/store"
    "$HOME/Library/Caches/Homebrew"
    "$HOME/Library/Developer/Xcode/DerivedData"
    "$HOME/.gradle/caches"
    "$HOME/.Trash"
  )

  local path

  for path in "${reclaimable_paths[@]}"; do
    current_kb="$(size_in_kb "$path")"
    estimated_reclaim_kb=$((estimated_reclaim_kb + current_kb))
  done

  if command_exists docker && docker info >/dev/null 2>&1; then
    section "Docker"
    docker system df || true
  fi

  section "Estimativa"

  echo "Espaço potencial em caches analisados:"
  echo "${BOLD}$(kb_to_human "$estimated_reclaim_kb")${RESET}"
  echo
  warning "Essa é uma estimativa bruta, não significa que todo esse espaço será recuperado."

  section "Recomendações"

  echo "1. Execute a limpeza segura:"
  echo "   ./mac-clean.sh clean"
  echo
  echo "2. Depois execute novamente:"
  echo "   ./mac-clean.sh doctor"
  echo
  echo "3. Use o modo deep apenas quando quiser limpar caches completos."
}

# ============================================================
# Limpeza segura
# ============================================================

clean_browser_caches() {
  safe_find_delete_old_items \
    "$HOME/Library/Caches/Google/Chrome" \
    "$CACHE_DAYS"

  safe_find_delete_old_items \
    "$HOME/Library/Caches/Chromium" \
    "$CACHE_DAYS"
}

clean_editor_caches() {
  safe_find_delete_old_items \
    "$HOME/Library/Application Support/Code/Cache" \
    "$CACHE_DAYS"

  safe_find_delete_old_items \
    "$HOME/Library/Application Support/Code/CachedData" \
    "$CACHE_DAYS"

  safe_find_delete_old_items \
    "$HOME/Library/Application Support/Code/Service Worker/CacheStorage" \
    "$CACHE_DAYS"

  safe_find_delete_old_items \
    "$HOME/Library/Application Support/Cursor/Cache" \
    "$CACHE_DAYS"

  safe_find_delete_old_items \
    "$HOME/Library/Application Support/Cursor/CachedData" \
    "$CACHE_DAYS"

  safe_find_delete_old_items \
    "$HOME/Library/Application Support/Cursor/Service Worker/CacheStorage" \
    "$CACHE_DAYS"
}

clean_xcode_safe() {
  safe_find_delete_old_items \
    "$HOME/Library/Developer/Xcode/DerivedData" \
    "$DERIVED_DATA_DAYS"

  safe_find_delete_old_items \
    "$HOME/Library/Developer/Xcode/Archives" \
    "$XCODE_ARCHIVE_DAYS"

  if command_exists xcrun; then
    xcrun simctl delete unavailable >/dev/null 2>&1 || true
  fi
}

clean_package_managers_safe() {
  safe_find_delete_old_items \
    "$HOME/.npm/_cacache" \
    "$CACHE_DAYS"

  safe_find_delete_old_items \
    "$HOME/Library/Caches/Yarn" \
    "$CACHE_DAYS"

  safe_find_delete_old_items \
    "$HOME/.gradle/caches" \
    "$CACHE_DAYS"

  safe_find_delete_old_items \
    "$HOME/Library/Caches/Homebrew" \
    "$CACHE_DAYS"

  safe_find_delete_old_items \
    "$HOME/Library/Caches/CocoaPods" \
    "$CACHE_DAYS"

  safe_find_delete_old_items \
    "$HOME/Library/Caches/org.swift.swiftpm" \
    "$CACHE_DAYS"

  if command_exists brew; then
    brew cleanup --prune="$CACHE_DAYS" >/dev/null 2>&1 || true
  fi

  if command_exists npm; then
    npm cache verify >/dev/null 2>&1 || true
  fi
}

clean() {
  title "Mac Clean — limpeza segura"

  section "Antes"
  show_disk_summary

  section "Executando limpeza"

  info "Limpando caches antigos do usuário..."
  safe_find_delete_old_items "$HOME/Library/Caches" "$CACHE_DAYS"

  info "Limpando logs antigos..."
  safe_find_delete_old_items "$HOME/Library/Logs" "$LOG_DAYS"

  info "Limpando itens antigos da lixeira..."
  safe_find_delete_old_items "$HOME/.Trash" "$TRASH_DAYS"

  info "Limpando caches do Xcode..."
  clean_xcode_safe

  info "Limpando caches de gerenciadores de pacotes..."
  clean_package_managers_safe

  info "Limpando caches de navegadores..."
  clean_browser_caches

  info "Limpando caches de editores..."
  clean_editor_caches

  section "Depois"
  show_disk_summary

  success "Limpeza segura concluída."
}

# ============================================================
# Limpeza profunda
# ============================================================

deep() {
  title "Mac Clean — limpeza profunda"

  warning "Esse modo limpa caches completos e recursos Docker não utilizados."
  warning "Volumes Docker não são removidos automaticamente."

  if ! confirm "Deseja continuar?"; then
    info "Operação cancelada."
    exit 0
  fi

  section "Antes"
  show_disk_summary

  section "Limpeza segura"
  clean

  section "Caches completos"

  if command_exists yarn; then
    info "Limpando cache completo do Yarn..."
    yarn cache clean || true
  elif command_exists corepack; then
    info "Tentando limpar o Yarn via Corepack..."
    corepack yarn cache clean || true
  fi

  if command_exists npm; then
    info "Limpando cache completo do npm..."
    npm cache clean --force || true
  fi

  if command_exists pnpm; then
    info "Removendo pacotes não utilizados do pnpm..."
    pnpm store prune || true
  fi

  if command_exists brew; then
    info "Executando limpeza profunda do Homebrew..."
    brew cleanup -s || true
  fi

  if command_exists docker && docker info >/dev/null 2>&1; then
    section "Docker"

    docker system df || true

    if confirm "Limpar imagens, containers, redes e cache Docker não utilizados?"; then
      docker system prune -af || true
      docker builder prune -af || true
    fi

    echo
    warning "Os volumes Docker continuam preservados."

    docker volume ls -qf dangling=true |
      while IFS= read -r volume; do
        [[ -n "$volume" ]] &&
          echo "Volume Docker não utilizado: $volume"
      done
  fi

  section "Depois"
  show_disk_summary

  success "Limpeza profunda concluída."
}

# ============================================================
# Agendamento
# ============================================================

schedule() {
  title "Mac Clean — agendamento"

  mkdir -p "$INSTALL_DIR"
  mkdir -p "$LAUNCH_AGENT_DIR"
  mkdir -p "$LOG_DIR"

  cp "$SCRIPT_PATH" "$INSTALL_PATH"
  chmod +x "$INSTALL_PATH"

  cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC
  "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.anderson.mac-clean</string>

  <key>ProgramArguments</key>
  <array>
    <string>${INSTALL_PATH}</string>
    <string>clean</string>
  </array>

  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key>
    <integer>7</integer>

    <key>Hour</key>
    <integer>11</integer>

    <key>Minute</key>
    <integer>0</integer>
  </dict>

  <key>StandardOutPath</key>
  <string>${STDOUT_LOG}</string>

  <key>StandardErrorPath</key>
  <string>${STDERR_LOG}</string>
</dict>
</plist>
EOF

  launchctl bootout \
    "gui/$(id -u)" \
    "$PLIST_PATH" \
    >/dev/null 2>&1 ||
    true

  launchctl bootstrap \
    "gui/$(id -u)" \
    "$PLIST_PATH"

  success "Limpeza segura agendada para sábado às 11h."
  info "Script instalado em: $INSTALL_PATH"
  info "Configuração: $PLIST_PATH"
  info "Logs: $LOG_DIR"
}

unschedule() {
  title "Mac Clean — remover agendamento"

  launchctl bootout \
    "gui/$(id -u)" \
    "$PLIST_PATH" \
    >/dev/null 2>&1 ||
    true

  rm -f "$PLIST_PATH"
  rm -f "$INSTALL_PATH"

  success "Agendamento removido."
}

# ============================================================
# Ajuda
# ============================================================

help_command() {
  cat <<EOF
${BOLD}Mac Clean${RESET}

Uso:

  ./mac-clean.sh
  ./mac-clean.sh report
  ./mac-clean.sh analyze
  ./mac-clean.sh doctor
  ./mac-clean.sh clean
  ./mac-clean.sh deep
  ./mac-clean.sh schedule
  ./mac-clean.sh unschedule
  ./mac-clean.sh help

Comandos:

  report
      Mostra os principais diretórios, caches, Docker e snapshots.
      Não apaga nada.

  analyze
      Lista os maiores diretórios e arquivos do usuário.
      Não apaga nada.

  doctor
      Analisa os principais caches e mostra recomendações.
      Não apaga nada.

  clean
      Executa uma limpeza segura de caches e logs antigos.

  deep
      Limpa caches completos do npm, Yarn, pnpm, Homebrew e
      recursos Docker não utilizados. Solicita confirmação.

  schedule
      Agenda a limpeza segura para sábado às 11h.

  unschedule
      Remove o agendamento semanal.

Variáveis opcionais:

  CACHE_DAYS=14
  LOG_DAYS=14
  TRASH_DAYS=7
  DERIVED_DATA_DAYS=7
  XCODE_ARCHIVE_DAYS=30

Exemplo:

  CACHE_DAYS=30 ./mac-clean.sh clean
EOF
}

# ============================================================
# Execução
# ============================================================

case "$COMMAND" in
  report)
    report
    ;;

  analyze)
    analyze
    ;;

  doctor)
    doctor
    ;;

  clean)
    clean
    ;;

  deep)
    deep
    ;;

  schedule)
    schedule
    ;;

  unschedule)
    unschedule
    ;;

  help|--help|-h)
    help_command
    ;;

  *)
    error "Comando inválido: $COMMAND"
    echo
    help_command
    exit 1
    ;;
esac