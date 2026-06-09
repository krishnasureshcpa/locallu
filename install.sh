#!/usr/bin/env zsh
# ============================================================
# locallu — install.sh
# One-command setup: deps check → alias injection → verify
# Usage: zsh install.sh
# ============================================================
set -e
BOLD=$'\e[1m'; GREEN=$'\e[32m'; CYAN=$'\e[36m'; YELLOW=$'\e[33m'; RED=$'\e[31m'; RESET=$'\e[0m'
PINK=$'\e[35m'

ok()   { echo "${GREEN}✓${RESET} $*"; }
log()  { echo "${CYAN}→${RESET} $*"; }
warn() { echo "${YELLOW}⚠${RESET} $*"; }
die()  { echo "${RED}✗${RESET} $*"; exit 1; }

SCRIPT_DIR="${0:A:h}"  # absolute path of this script's directory

echo ""
echo "${PINK}${BOLD}"
echo "  ██╗      ██████╗  ██████╗ █████╗ ██╗     ██╗     ██╗   ██╗"
echo "  ██║     ██╔═══██╗██╔════╝██╔══██╗██║     ██║     ██║   ██║"
echo "  ██║     ██║   ██║██║     ███████║██║     ██║     ██║   ██║"
echo "  ██║     ██║   ██║██║     ██╔══██║██║     ██║     ██║   ██║"
echo "  ███████╗╚██████╔╝╚██████╗██║  ██║███████╗███████╗╚██████╔╝"
echo "  ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ "
echo "${RESET}"
echo "  ${BOLD}Universal Local Model Launcher — Install${RESET}"
echo ""

# ── 1. Check required tools ───────────────────────────────────
log "Checking dependencies..."

if ! command -v zsh &>/dev/null; then
  die "zsh not found — install via: brew install zsh"
fi
ok "zsh: $(zsh --version | head -1)"

# Ollama (recommended)
if command -v ollama &>/dev/null; then
  ok "Ollama: $(ollama --version 2>/dev/null || echo installed)"
else
  warn "Ollama not found. Install for local models:"
  echo "  brew install ollama  OR  https://ollama.com/download"
  echo ""
fi

# llmfit (optional)
if command -v llmfit &>/dev/null; then
  ok "llmfit: found"
else
  warn "llmfit not found (optional). Install: pip install llmfit"
fi

# ── 2. Make locallu.sh executable ────────────────────────────
log "Setting permissions..."
chmod +x "$SCRIPT_DIR/locallu.sh"
ok "locallu.sh is executable"

# ── 3. Install aliases into ~/.zshrc ─────────────────────────
ZSHRC="$HOME/.zshrc"
BLOCK_MARKER="# ── locallu aliases"

if grep -q "$BLOCK_MARKER" "$ZSHRC" 2>/dev/null; then
  warn "locallu aliases already in ~/.zshrc — skipping"
else
  log "Adding aliases to ~/.zshrc..."
  # Backup first
  cp "$ZSHRC" "${ZSHRC}.bak-locallu-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true

  cat >> "$ZSHRC" << ALIASBLOCK

$BLOCK_MARKER ─────────────────────────────────────
export LOCALLU_HOME="$SCRIPT_DIR"
export LOCAL_MODELS_DIR="\${LOCAL_MODELS_DIR:-\$HOME/MasterBase/local-models}"
alias locallu="zsh \$LOCALLU_HOME/locallu.sh"
alias llu="locallu"
# ── end locallu aliases ────────────────────────────────────
ALIASBLOCK

  ok "Aliases added to ~/.zshrc"
  echo "  Run: ${BOLD}source ~/.zshrc${RESET} to activate now"
fi

# ── 4. Check local GGUF models ───────────────────────────────
LOCAL_MODELS="${LOCAL_MODELS_DIR:-$HOME/MasterBase/local-models}"
if [[ -d "$LOCAL_MODELS" ]]; then
  GGUF_COUNT=$(find "$LOCAL_MODELS" -name "*.gguf" -o -name "*.bin" 2>/dev/null | wc -l | tr -d ' ')
  ok "Local models dir: $LOCAL_MODELS ($GGUF_COUNT GGUF files found)"
else
  warn "Local models dir not found: $LOCAL_MODELS"
  echo "  Create with: mkdir -p $LOCAL_MODELS"
fi

# ── 5. Quick self-test ────────────────────────────────────────
log "Running self-test..."
if zsh "$SCRIPT_DIR/locallu.sh" --list-agents 2>/dev/null | grep -q "Claude"; then
  ok "locallu self-test passed"
else
  warn "Self-test output unexpected — but install may still work"
fi

# ── Done ─────────────────────────────────────────────────────
echo ""
echo "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${GREEN}${BOLD}  locallu installed successfully!${RESET}"
echo "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo "  ${BOLD}Activate:${RESET}  source ~/.zshrc"
echo "  ${BOLD}Launch:${RESET}    locallu   or   llu"
echo "  ${BOLD}Pull model:${RESET} locallu --pull llama3.2"
echo ""
