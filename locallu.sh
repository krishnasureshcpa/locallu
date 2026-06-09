#!/usr/bin/env zsh
# ============================================================
#  locallu — Universal Local Model Launcher
#  First-principles design: minimal inputs → maximum capability
#  Author: Krishna (MasterBase) • 2026-06-08
#  GitHub: github.com/krishnasureshcpa/locallu
# ============================================================
# Usage: locallu [--agent <name>] [--model <name>] [--cap <cap,...>]
#        locallu --list-models
#        locallu --list-agents
#        locallu --pull <model>   # download via Ollama
# ============================================================

set -euo pipefail

# ── Palette ──────────────────────────────────────────────────
BOLD=$'\e[1m'; DIM=$'\e[2m'; RESET=$'\e[0m'
C0=$'\e[38;5;213m'  # pink/magenta — brand accent
C1=$'\e[38;5;81m'   # cyan — headings
C2=$'\e[38;5;154m'  # green — ok
C3=$'\e[38;5;220m'  # yellow — warn/prompt
C4=$'\e[38;5;203m'  # red — error
BG=$'\e[48;5;235m'  # dark bg for banners

# ── Paths ────────────────────────────────────────────────────
LOCALLU_HOME="${LOCALLU_HOME:-$HOME/MasterBase/locallu}"
LOCAL_MODELS_DIR="${LOCAL_MODELS_DIR:-$HOME/MasterBase/local-models}"
LLMFIT_BIN="$(command -v llmfit 2>/dev/null || echo '')"
OLLAMA_BIN="$(command -v ollama 2>/dev/null || echo '')"

# ── Banner ───────────────────────────────────────────────────
banner() {
  clear
  echo ""
  echo "${BG}${C0}${BOLD}  ██╗      ██████╗  ██████╗ █████╗ ██╗     ██╗     ██╗   ██╗  ${RESET}"
  echo "${BG}${C0}${BOLD}  ██║     ██╔═══██╗██╔════╝██╔══██╗██║     ██║     ██║   ██║  ${RESET}"
  echo "${BG}${C0}${BOLD}  ██║     ██║   ██║██║     ███████║██║     ██║     ██║   ██║  ${RESET}"
  echo "${BG}${C0}${BOLD}  ██║     ██║   ██║██║     ██╔══██║██║     ██║     ██║   ██║  ${RESET}"
  echo "${BG}${C0}${BOLD}  ███████╗╚██████╔╝╚██████╗██║  ██║███████╗███████╗╚██████╔╝  ${RESET}"
  echo "${BG}${C0}${BOLD}  ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝   ${RESET}"
  echo ""
  echo "${C1}${BOLD}  Universal Local Model Launcher${RESET}  ${DIM}by Krishna · MasterBase${RESET}"
  echo "${DIM}  ─────────────────────────────────────────────────────────${RESET}"
  echo ""
}

# ── Helpers ──────────────────────────────────────────────────
ok()    { echo "  ${C2}✓${RESET} $*"; }
warn()  { echo "  ${C3}⚠${RESET} $*"; }
err()   { echo "  ${C4}✗${RESET} $*"; }
prompt(){ printf "  ${C3}?${RESET} ${BOLD}$1${RESET}: "; }
pick()  { printf "  ${C0}›${RESET} "; }

numbered_menu() {
  local title=$1; shift
  local items=("$@")
  echo ""
  echo "  ${C1}${BOLD}$title${RESET}"
  echo "  ${DIM}───────────────────────────────${RESET}"
  local i=1
  for item in "${items[@]}"; do
    printf "  ${C0}[%2d]${RESET}  %s\n" $i "$item"
    ((i++))
  done
  echo ""
}

# ── Discover models ──────────────────────────────────────────
discover_ollama_models() {
  if [[ -z "$OLLAMA_BIN" ]]; then echo ""; return; fi
  ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' | grep -v '^$' || echo ""
}

discover_local_gguf_models() {
  find "$LOCAL_MODELS_DIR" -name "*.gguf" -o -name "*.bin" 2>/dev/null | \
    awk -F'/' '{print $NF}' | sort || echo ""
}

discover_llmfit_models() {
  if [[ -z "$LLMFIT_BIN" ]]; then echo ""; return; fi
  llmfit list 2>/dev/null | grep -v "^#" || echo ""
}

# Model capability detection
detect_capabilities() {
  local model=$1
  local caps=()
  # vision: models with vision/vl/multimodal in name
  [[ "$model" =~ (vision|vl|llava|bakllava|moondream|multimodal|qwen.*vl|minicpm|phi.*v) ]] && caps+=("👁  Vision / Image understanding")
  # tool calling
  [[ "$model" =~ (qwen|llama3|mistral|hermes|functionary|nexus|gorilla|tool) ]] && caps+=("🔧 Tool calling / Function use")
  # code
  [[ "$model" =~ (code|coder|starcoder|deepseek.*code|qwen.*coder|phi.*code) ]] && caps+=("💻 Code generation")
  # reasoning
  [[ "$model" =~ (r1|reasoner|thinking|o1|opus|qwq) ]] && caps+=("🧠 Extended reasoning / Chain-of-thought")
  # embedding
  [[ "$model" =~ (embed|nomic|bge|e5|gte|all-mini) ]] && caps+=("🔍 Embeddings / Semantic search")
  # math
  [[ "$model" =~ (math|wizard|numina) ]] && caps+=("📐 Math / STEM")

  [[ ${#caps[@]} -eq 0 ]] && caps+=("💬 Text generation")
  echo "${caps[@]}"
}

# ── Agent definitions ─────────────────────────────────────────
AGENTS=(
  "Claude Code (CLI)"
  "Codex (CLI)"
  "Ollama Chat (CLI)"
  "Open WebUI (Browser)"
  "LM Studio (App)"
  "llmfit (CLI)"
  "Continue.dev (VS Code)"
  "Aider (CLI — pair programmer)"
  "Shell REPL (raw llama.cpp)"
)

AGENT_COMMANDS=(
  "claude"
  "codex --profile local --model {MODEL}"
  "ollama run {MODEL}"
  "open http://localhost:3000"
  "open -a 'LM Studio'"
  "llmfit run {MODEL}"
  "code ."
  "aider --model ollama/{MODEL}"
  "{LLAMA_CPP} -m {MODEL_PATH} -ngl 99 --chat-format llama-3"
)

# ── Main interactive flow ─────────────────────────────────────
main() {
  # Parse args
  local ARG_AGENT="" ARG_MODEL="" ARG_CAPS=() DO_LIST_MODELS=0 DO_LIST_AGENTS=0 PULL_MODEL=""
  while [[ $# -gt 0 ]]; do
    case $1 in
      --agent)   ARG_AGENT="$2"; shift 2 ;;
      --model)   ARG_MODEL="$2"; shift 2 ;;
      --cap)     ARG_CAPS=("${(@s:,:)2}"); shift 2 ;;
      --list-models) DO_LIST_MODELS=1; shift ;;
      --list-agents) DO_LIST_AGENTS=1; shift ;;
      --pull)    PULL_MODEL="$2"; shift 2 ;;
      --help|-h) usage; exit 0 ;;
      *) shift ;;
    esac
  done

  # Quick commands
  if (( DO_LIST_MODELS )); then
    echo "${C1}${BOLD}Ollama models:${RESET}"; discover_ollama_models
    echo "${C1}${BOLD}GGUF models:${RESET}";   discover_local_gguf_models
    [[ -n "$LLMFIT_BIN" ]] && { echo "${C1}${BOLD}llmfit models:${RESET}"; discover_llmfit_models; }
    exit 0
  fi

  if (( DO_LIST_AGENTS )); then
    for i in {1..${#AGENTS[@]}}; do echo "  [$i] ${AGENTS[$i]}"; done
    exit 0
  fi

  if [[ -n "$PULL_MODEL" ]]; then
    pull_model "$PULL_MODEL"; exit 0
  fi

  # ── Interactive flow ─────────────────────────────────────────
  banner

  # Step 1: Pick agent
  local chosen_agent=""
  if [[ -n "$ARG_AGENT" ]]; then
    chosen_agent="$ARG_AGENT"
    ok "Agent pre-selected: $chosen_agent"
  else
    numbered_menu "Which AI agent do you want to use?" "${AGENTS[@]}"
    pick; read -r agent_idx
    if [[ "$agent_idx" =~ ^[0-9]+$ ]] && (( agent_idx >= 1 && agent_idx <= ${#AGENTS[@]} )); then
      chosen_agent="${AGENTS[$agent_idx]}"
    else
      err "Invalid selection."; exit 1
    fi
  fi
  echo ""
  ok "Agent: ${BOLD}$chosen_agent${RESET}"

  # Step 2: Collect available models
  echo ""
  echo "  ${C1}${BOLD}Scanning local models...${RESET}"
  local -a all_models=()

  # Ollama models
  local ollama_models=($(discover_ollama_models))
  [[ ${#ollama_models[@]} -gt 0 ]] && all_models+=("${ollama_models[@]}")

  # GGUF models from local-models dir
  local gguf_models=($(discover_local_gguf_models))
  [[ ${#gguf_models[@]} -gt 0 ]] && all_models+=("${gguf_models[@]}")

  # llmfit
  local llmfit_models=($(discover_llmfit_models))
  [[ ${#llmfit_models[@]} -gt 0 ]] && all_models+=("${llmfit_models[@]}")

  # Always offer to download
  all_models+=("[ Download a new model from Ollama Hub ]")
  all_models+=("[ Enter custom model path / name ]")

  local chosen_model=""
  if [[ -n "$ARG_MODEL" ]]; then
    chosen_model="$ARG_MODEL"
    ok "Model pre-selected: $chosen_model"
  else
    numbered_menu "Which local model?" "${all_models[@]}"
    pick; read -r model_idx
    if [[ "$model_idx" =~ ^[0-9]+$ ]] && (( model_idx >= 1 && model_idx <= ${#all_models[@]} )); then
      chosen_model="${all_models[$model_idx]}"
    else
      err "Invalid selection."; exit 1
    fi

    # Handle special options
    if [[ "$chosen_model" == *"Download"* ]]; then
      echo ""
      prompt "Enter model name to pull (e.g. qwen2.5-coder:7b, llama3.2, phi4)"; read -r chosen_model
      pull_model "$chosen_model"
    elif [[ "$chosen_model" == *"Enter custom"* ]]; then
      echo ""
      prompt "Enter model path or name"; read -r chosen_model
    fi
  fi

  echo ""
  ok "Model: ${BOLD}$chosen_model${RESET}"

  # Step 3: Capabilities
  local caps_str=$(detect_capabilities "$chosen_model")
  echo ""
  echo "  ${C1}${BOLD}Detected capabilities:${RESET}"
  for cap in ${(s: :)caps_str}; do
    echo "    $cap"
  done

  # Step 4: Extra tools / options
  echo ""
  echo "  ${C1}${BOLD}Additional options${RESET}"
  echo "  ${DIM}───────────────────────────────${RESET}"
  echo "  ${C0}[1]${RESET}  Enable web search (Ollama + search plugin)"
  echo "  ${C0}[2]${RESET}  Enable tool calling / MCP"
  echo "  ${C0}[3]${RESET}  Enable vision input (if model supports it)"
  echo "  ${C0}[4]${RESET}  Enable code interpreter (sandboxed exec)"
  echo "  ${C0}[5]${RESET}  No extras — just launch"
  echo ""
  pick; read -r extras
  echo ""

  # Step 5: Confirm and launch
  echo ""
  echo "  ${DIM}─────────────────────────────────────────${RESET}"
  echo "  ${C0}${BOLD}Ready to launch${RESET}"
  echo "  ${DIM}─────────────────────────────────────────${RESET}"
  echo "  Agent : ${BOLD}$chosen_agent${RESET}"
  echo "  Model : ${BOLD}$chosen_model${RESET}"
  [[ -n "$caps_str" ]] && echo "  Caps  : $caps_str"
  echo ""
  prompt "Launch now? [Y/n]"; read -r confirm
  [[ "${confirm:-y}" =~ ^[Nn] ]] && { echo "  Aborted."; exit 0; }

  # Step 6: Launch
  launch_agent "$chosen_agent" "$chosen_model"
}

# ── Launch ────────────────────────────────────────────────────
launch_agent() {
  local agent=$1 model=$2
  echo ""
  ok "Launching ${BOLD}$agent${RESET} with ${BOLD}$model${RESET}..."
  sleep 0.5

  case "$agent" in
    "Claude Code (CLI)")
      export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
      # Claude Code can use Ollama via openrouter or direct
      # Point it at Ollama for local model
      if command -v claude &>/dev/null; then
        claude
      else
        err "claude not installed. Run: npm install -g @anthropic-ai/claude-code"
        exit 1
      fi
      ;;

    "Codex (CLI)")
      if command -v codex &>/dev/null; then
        codex --profile local --model "$model"
      else
        err "codex not installed. Run the Codex install script."
        exit 1
      fi
      ;;

    "Ollama Chat (CLI)")
      if [[ -n "$OLLAMA_BIN" ]]; then
        ollama run "$model"
      else
        err "ollama not installed: https://ollama.com/download"; exit 1
      fi
      ;;

    "Open WebUI (Browser)")
      # Start Open WebUI if not running
      if ! curl -sf http://localhost:3000 &>/dev/null; then
        warn "Open WebUI not running. Attempting to start via Docker..."
        if command -v docker &>/dev/null; then
          docker run -d -p 3000:8080 \
            --add-host=host.docker.internal:host-gateway \
            -v open-webui:/app/backend/data \
            --name open-webui --restart always \
            ghcr.io/open-webui/open-webui:main
          sleep 3
        else
          warn "Docker not available. Install Open WebUI: https://openwebui.com"
        fi
      fi
      open "http://localhost:3000"
      ok "Opened Open WebUI in browser"
      ;;

    "LM Studio (App)")
      open -a "LM Studio" 2>/dev/null || {
        warn "LM Studio not installed: https://lmstudio.ai"
      }
      ;;

    "llmfit (CLI)")
      if [[ -n "$LLMFIT_BIN" ]]; then
        llmfit run "$model"
      else
        warn "llmfit not installed. Installing..."
        pip install llmfit --break-system-packages 2>/dev/null || \
        pip3 install llmfit 2>/dev/null || \
        err "Could not install llmfit. Try: pip3 install llmfit"
        exit 1
      fi
      ;;

    "Continue.dev (VS Code)")
      code . 2>/dev/null || open -a "Visual Studio Code" .
      ok "VS Code opened — configure Continue.dev to use ollama/$model"
      ;;

    "Aider (CLI — pair programmer)")
      if command -v aider &>/dev/null; then
        aider --model "ollama/$model"
      else
        warn "aider not installed. Installing..."
        pip install aider-chat --break-system-packages 2>/dev/null
        aider --model "ollama/$model"
      fi
      ;;

    "Shell REPL (raw llama.cpp)")
      # Find llama.cpp binary
      local llama_bin
      llama_bin=$(command -v llama-cli 2>/dev/null || \
                  command -v llama.cpp 2>/dev/null || \
                  find /usr/local /opt/homebrew ~/MasterBase -name "llama-cli" -type f 2>/dev/null | head -1 || \
                  echo "")
      if [[ -z "$llama_bin" ]]; then
        err "llama.cpp not found. Install: brew install llama.cpp"
        exit 1
      fi
      # Find model file
      local model_path
      model_path=$(find "$LOCAL_MODELS_DIR" -name "*${model}*" \( -name "*.gguf" -o -name "*.bin" \) 2>/dev/null | head -1 || echo "$model")
      "$llama_bin" -m "$model_path" -ngl 99 --chat-format llama-3 -i
      ;;
  esac
}

# ── Pull model ────────────────────────────────────────────────
pull_model() {
  local model=$1
  echo ""
  echo "  ${C1}${BOLD}Pulling model: $model${RESET}"
  echo ""
  if [[ -z "$OLLAMA_BIN" ]]; then
    err "Ollama not installed. Install: https://ollama.com/download"
    exit 1
  fi
  ollama pull "$model"
  ok "Model pulled: $model"
  echo "  Launch with: locallu --model $model"
}

# ── Usage ─────────────────────────────────────────────────────
usage() {
cat << 'USAGE'
locallu — Universal Local Model Launcher

USAGE
  locallu                           # interactive (recommended)
  locallu --agent "Codex (CLI)" --model qwen2.5-coder:7b
  locallu --list-models             # show all local models
  locallu --list-agents             # show all supported agents
  locallu --pull <model>            # download model via Ollama

EXAMPLES
  locallu                           # fully interactive wizard
  llu                               # same (short alias)
  locallu --pull llama3.2           # download Llama 3.2
  locallu --pull qwen2.5-coder:7b   # download Qwen 2.5 Coder
  locallu --model gemma4:e4b        # skip to model selection

FREE MODELS (via locallu → Ollama)
  qwen2.5-coder:7b   llama3.2   phi4   gemma3   deepseek-r1:8b
  mistral:7b         qwq        tinyllama   nomic-embed-text

USAGE
}

# ── Entry ─────────────────────────────────────────────────────
main "$@"
