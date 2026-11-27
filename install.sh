#!/usr/bin/env bash
# =============================================================
#  Installer konfiguracji Codex — Linux / macOS
#  Źródło: https://github.com/KwanekDev/codex-config
#  Użycie: bash <(curl -fsSL .../install.sh)
# =============================================================
set -euo pipefail

# --- Lokalizacje -----------------------------------------------------------
REPO_URL="https://raw.githubusercontent.com/KwanekDev/codex-config/main"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Codex config installer"
echo "    CODEX_HOME=$CODEX_HOME"

# --- Wymagania -------------------------------------------------------------
echo "==> Sprawdzam wymagania..."
for cmd in curl git; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "  [BŁĄD] brak narzędzia: $cmd"; exit 1
  else
    echo "  [OK] $cmd"
  fi
done
if ! command -v node >/dev/null 2>&1 || ! command -v npx >/dev/null 2>&1; then
  echo "  [UWAGA] brak Node.js/npm — MCP (github, playwright, context7, notion) nie będą działać do czasu instalacji Node."
fi

# --- Instalacja Codex CLI (jeśli brak) --------------------------------------
if ! command -v codex >/dev/null 2>&1; then
  if [ "${INSTALL_TOOLS:-1}" = "1" ]; then
    echo "==> Brak codex CLI — instaluję (oficjalny instalator)..."
    curl -fsSL https://chatgpt.com/codex/install.sh | sh
  else
    echo "  [UWAGA] brak codex CLI — pomijam (INSTALL_TOOLS=0). Zainstaluj sam: curl -fsSL https://chatgpt.com/codex/install.sh | sh"
  fi
else
  echo "  [OK] codex: $(command -v codex)"
fi

# --- Instalacja opencodex / ocx (jeśli brak) ---------------------------------
if ! command -v ocx >/dev/null 2>&1; then
  if [ "${INSTALL_TOOLS:-1}" = "1" ]; then
    echo "==> Brak opencodex (ocx) — instaluję przez npm..."
    npm install -g @bitkyc08/opencodex || echo "  [UWAGA] instalacja opencodex nie powiodła się (sprawdź Node/npm)."
  else
    echo "  [UWAGA] brak opencodex — pomijam (INSTALL_TOOLS=0)."
  fi
else
  echo "  [OK] ocx: $(command -v ocx)"
fi

# --- Instalacja ChatGPT App (desktop) — jeśl brak -----------------------------
install_chatgpt_app() {
  local arch="$(uname -m)"
  case "$arch" in
    x86_64) local deb_url="https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb"
             local rpm_url="https://persistent.oaistatic.com/codex-app-prod/linux/rpm/latest/chatgpt.x86_64.rpm";;
    aarch64|arm64) local deb_url="https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_arm64.deb"
             local rpm_url="https://persistent.oaistatic.com/codex-app-prod/linux/rpm/latest/chatgpt.aarch64.rpm";;
    *) echo "  [UWAGA] nieobsługiwana architektura ($arch) — zainstaluj ChatGPT App ręcznie."; return 1;;
  esac

  if command -v apt-get >/dev/null 2>&1; then
    echo "==> Pobieram ChatGPT App (.deb)..."
    curl -fsSL "$deb_url" -o /tmp/chatgpt_amd64.deb || { echo "  [BŁĄD] pobieranie nie powiodło się"; return 1; }
    echo "==> Instaluję przez sudo apt (może poprosić o hasło)..."
    sudo apt install -y /tmp/chatgpt_amd64.deb && rm -f /tmp/chatgpt_amd64.deb
  elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
    echo "==> Pobieram ChatGPT App (.rpm)..."
    curl -fsSL "$rpm_url" -o /tmp/chatgpt.rpm || { echo "  [BŁĄD] pobieranie nie powiodło się"; return 1; }
    echo "==> Instaluję przez sudo dnf (może poprosić o hasło)..."
    sudo dnf install -y /tmp/chatgpt.rpm && rm -f /tmp/chatgpt.rpm
  else
    echo "  [UWAGA] brak apt/dnf — zainstaluj ChatGPT App ręcznie: https://chatgpt.com/download"
    return 1
  fi
}

if ! command -v chatgpt >/dev/null 2>&1 && [ ! -x /usr/lib/chatgpt/ChatGPT ]; then
  if [ "${INSTALL_APP:-1}" = "1" ]; then
    install_chatgpt_app
  else
    echo "  [UWAGA] brak ChatGPT App — pomijam (INSTALL_APP=0)."
  fi
else
  echo "  [OK] ChatGPT App: $(command -v chatgpt 2>/dev/null || echo /usr/lib/chatgpt/ChatGPT)"
fi

# --- Pobierz pliki wzorcowe -------------------------------------------------
echo "==> Pobieram wzorce z GitHub..."
for f in config.toml.example AGENTS.md.example hooks.json.example; do
  curl -fsSL "$REPO_URL/$f" -o "$TMP_DIR/$f" || { echo "  [BŁĄD] nie udało się pobrać $f"; exit 1; }
done

# --- Katalog docelowy --------------------------------------------------------
mkdir -p "$CODEX_HOME"

# --- Instalacja config.toml ---------------------------------------------------
echo "==> Instaluję config.toml..."
CFG="$CODEX_HOME/config.toml"
cp "$TMP_DIR/config.toml.example" "$CFG"

# Podstawowe placeholdery
sed -i "s|<CODEX_HOME>|$CODEX_HOME|g" "$CFG"

# Wykryj node_repl (tylko gdy dostępny — z aplikacji Codex/ChatGPT)
NODE_REPL_BIN=""
NODE_REPL_MODULES=""
NODE_REPL_NODE=""
for cand in \
  "/usr/lib/chatgpt/resources/cua_node/bin/node_repl" \
  "$HOME/.config/Codex/cua_node/bin/node_repl" \
  "$HOME/.local/lib/chatgpt/resources/cua_node/bin/node_repl"; do
  if [ -x "$cand" ]; then
    NODE_REPL_BIN="$cand"
    NODE_REPL_NODE="$(dirname "$cand")/node"
    NODE_REPL_MODULES="$(dirname "$cand")/lib/node_modules"
    break
  fi
done

if [ -n "$NODE_REPL_BIN" ]; then
  echo "  [OK] znaleziono node_repl: $NODE_REPL_BIN"
  sed -i "s|<NODE_REPL_BIN>|$NODE_REPL_BIN|g; s|<NODE_REPL_NODE>|$NODE_REPL_NODE|g; s|<NODE_REPL_MODULES>|$NODE_REPL_MODULES|g" "$CFG"
else
  echo "  [INFO] brak node_repl — usuwam sekcję MCP node_repl z config.toml"
  # usuń sekcję [mcp_servers.node_repl] razem z jej env (do następnej sekcji [mcp_servers.)
  awk '
    /^\[mcp_servers\.node_repl\]/ { skip=1; next }
    skip && /^\[mcp_servers\./ { skip=0 }
    skip { next }
    { print }
  ' "$CFG" > "$CFG.tmp" && mv "$CFG.tmp" "$CFG"
fi

# Kodex CLI path (jeśli znany)
CODEX_CLI_PATH="$(command -v codex 2>/dev/null || true)"
if [ -n "$CODEX_CLI_PATH" ]; then
  sed -i "s|<CODEX_CLI_PATH>|$CODEX_CLI_PATH|g" "$CFG"
else
  sed -i "s|<CODEX_CLI_PATH>|codex|g" "$CFG"
fi

echo "  [OK] zapisano $CFG"

# --- Instalacja AGENTS.md ------------------------------------------------------
if [ ! -f "$CODEX_HOME/AGENTS.md" ]; then
  echo "==> Instaluję AGENTS.md (wzorzec)..."
  cp "$TMP_DIR/AGENTS.md.example" "$CODEX_HOME/AGENTS.md"
else
  echo "==> AGENTS.md już istnieje — pomijam (usuń ręcznie, aby zainstalować wzorzec)."
fi

# --- Instalacja hooks.json -------------------------------------------------------
IMPECCABLE_BASH="$HOME/.agents/skills/impeccable/scripts/impeccable"
if [ -x "$IMPECCABLE_BASH" ] && [ ! -f "$CODEX_HOME/hooks.json" ]; then
  echo "==> Instaluję hooks.json (impeccable)..."
  sed "s|<IMPECCABLE_BASH>|$IMPECCABLE_BASH|g" "$TMP_DIR/hooks.json.example" > "$CODEX_HOME/hooks.json"
elif [ ! -f "$CODEX_HOME/hooks.json" ]; then
  echo "==> hooks.json: brak impeccable (lub brak wzorca) — pomijam."
fi

echo ""
echo "==> Gotowe! Zweryfikuj konfigurację:"
echo "    codex doctor"
echo "    cat $CFG"
echo ""
echo "Uwaga: skonfiguruj własny provider/klucz API (patrz README)."
