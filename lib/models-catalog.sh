#!/usr/bin/env zsh
# ============================================================
# lib/models-catalog.sh — Curated free model catalog
# Source this or use functions directly.
# ============================================================

# Model catalog: "ollama_name|display_name|size|capabilities|pull_cmd"
declare -a MODEL_CATALOG=(
  # ── Code Models (free, local via Ollama) ─────────────────
  "qwen2.5-coder:7b|Qwen 2.5 Coder 7B|4.7GB|💻 code 🔧 tools|ollama pull qwen2.5-coder:7b"
  "qwen2.5-coder:32b|Qwen 2.5 Coder 32B|19GB|💻 code 🔧 tools 🧠 reason|ollama pull qwen2.5-coder:32b"
  "deepseek-coder-v2:16b|DeepSeek Coder V2 16B|9.1GB|💻 code 🔧 tools|ollama pull deepseek-coder-v2:16b"
  "starcoder2:15b|StarCoder2 15B|8.9GB|💻 code|ollama pull starcoder2:15b"

  # ── Reasoning Models (free, local) ───────────────────────
  "deepseek-r1:8b|DeepSeek R1 8B|4.9GB|🧠 reason 💻 code|ollama pull deepseek-r1:8b"
  "deepseek-r1:32b|DeepSeek R1 32B|19GB|🧠 reason 💻 code|ollama pull deepseek-r1:32b"
  "qwq:32b|QwQ 32B (Thinking)|19GB|🧠 reason 📐 math|ollama pull qwq:32b"

  # ── Vision Models (free, local) ───────────────────────────
  "qwen2.5vl:7b|Qwen 2.5 VL 7B|4.9GB|👁 vision 🔧 tools|ollama pull qwen2.5vl:7b"
  "llava:13b|LLaVA 13B|8.2GB|👁 vision|ollama pull llava:13b"
  "minicpm-v:8b|MiniCPM-V 8B|5.5GB|👁 vision 💻 code|ollama pull minicpm-v:8b"
  "moondream:1.8b|Moondream 1.8B|1.1GB|👁 vision|ollama pull moondream:1.8b"

  # ── General Purpose (free, local) ────────────────────────
  "llama3.2:3b|Llama 3.2 3B|2.0GB|🔧 tools|ollama pull llama3.2:3b"
  "llama3.2:1b|Llama 3.2 1B (Ultra-fast)|1.3GB|🔧 tools|ollama pull llama3.2:1b"
  "llama3.1:8b|Llama 3.1 8B|4.9GB|🔧 tools 💻 code|ollama pull llama3.1:8b"
  "gemma3:4b|Gemma 3 4B|2.5GB|💻 code|ollama pull gemma3:4b"
  "gemma3:12b|Gemma 3 12B|7.4GB|💻 code 🧠 reason|ollama pull gemma3:12b"
  "phi4:14b|Phi-4 14B (Microsoft)|8.9GB|🧠 reason 💻 code 📐 math|ollama pull phi4:14b"
  "mistral:7b|Mistral 7B|4.1GB|🔧 tools 💻 code|ollama pull mistral:7b"
  "mixtral:8x7b|Mixtral 8x7B MoE|26GB|🔧 tools 💻 code|ollama pull mixtral:8x7b"

  # ── Embeddings (free, local) ──────────────────────────────
  "nomic-embed-text|Nomic Embed Text|274MB|🔍 embeddings|ollama pull nomic-embed-text"
  "bge-m3|BGE-M3 Embeddings|1.2GB|🔍 embeddings|ollama pull bge-m3"

  # ── OpenRouter Free Models (needs OPENROUTER_API_KEY) ─────
  "openrouter:google/gemini-flash-1.5:free|Gemini Flash 1.5 (free)|API|💻 code 🔧 tools|openrouter"
  "openrouter:meta-llama/llama-3.1-8b-instruct:free|Llama 3.1 8B Instruct (free)|API|🔧 tools|openrouter"
  "openrouter:deepseek/deepseek-r1:free|DeepSeek R1 (free)|API|🧠 reason 💻 code|openrouter"
  "openrouter:qwen/qwen-2.5-72b-instruct:free|Qwen 2.5 72B Instruct (free)|API|💻 code 🔧 tools|openrouter"
  "openrouter:microsoft/phi-3-mini-128k-instruct:free|Phi-3 Mini 128k (free)|API|💻 code|openrouter"
  "openrouter:mistralai/mistral-7b-instruct:free|Mistral 7B Instruct (free)|API|🔧 tools|openrouter"
)

# ── Helper: print catalog table ───────────────────────────────
print_model_catalog() {
  local filter="${1:-all}"  # all | local | openrouter | vision | code | reason
  printf "\n  %-30s %-8s %-30s %s\n" "Model" "Size" "Capabilities" "Source"
  printf "  %-30s %-8s %-30s %s\n" "$(printf '%.0s─' {1..30})" "$(printf '%.0s─' {1..8})" "$(printf '%.0s─' {1..30})" "──────"

  for entry in "${MODEL_CATALOG[@]}"; do
    IFS='|' read -r id display size caps pull <<< "$entry"
    source="ollama"
    [[ "$id" == openrouter:* ]] && source="openrouter"

    # Filter
    case "$filter" in
      local)      [[ "$source" != "ollama" ]] && continue ;;
      openrouter) [[ "$source" != "openrouter" ]] && continue ;;
      vision)     [[ "$caps" != *"👁"* ]] && continue ;;
      code)       [[ "$caps" != *"💻"* ]] && continue ;;
      reason)     [[ "$caps" != *"🧠"* ]] && continue ;;
      free)       true ;;  # all are free
    esac

    printf "  %-30s %-8s %-30s %s\n" "${display:0:30}" "${size:0:8}" "${caps:0:30}" "$source"
  done
  echo ""
}

# ── Helper: get pull command for a model ─────────────────────
get_pull_cmd() {
  local target_id="$1"
  for entry in "${MODEL_CATALOG[@]}"; do
    IFS='|' read -r id display size caps pull <<< "$entry"
    if [[ "$id" == "$target_id" || "$display" == "$target_id" ]]; then
      echo "$pull"
      return 0
    fi
  done
  # Fallback: assume ollama pull
  echo "ollama pull $target_id"
}
