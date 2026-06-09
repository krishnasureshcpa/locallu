# locallu

**Universal Local Model Launcher** — first-principles design for running AI agents with local models.

> One command. Pick your agent. Pick your model. It launches.

```
llu
```

---

## Philosophy (First Principles)

Strip everything to the minimum required decision chain:

1. **What agent** do you want to think with?
2. **Which model** should power it?
3. **What capabilities** do you need?
4. **Launch** — immediately.

No YAML configs. No environment wrestling. No manual path hunting. `locallu` discovers models, detects capabilities, wires the connection, and opens the agent — in under 30 seconds.

---

## Supported Agents

| # | Agent | How launched |
|---|-------|-------------|
| 1 | **Claude Code** (CLI) | `claude` |
| 2 | **Codex** (CLI) | `codex --profile local` |
| 3 | **Ollama Chat** (CLI) | `ollama run <model>` |
| 4 | **Open WebUI** (browser) | `http://localhost:3000` |
| 5 | **LM Studio** (app) | native macOS app |
| 6 | **llmfit** (CLI) | `llmfit run <model>` |
| 7 | **Continue.dev** (VS Code) | VS Code extension |
| 8 | **Aider** (pair programmer) | `aider --model ollama/<model>` |
| 9 | **llama.cpp REPL** (raw) | direct binary |

---

## Install

```bash
# Clone
git clone https://github.com/krishnasureshcpa/locallu ~/MasterBase/locallu

# Add alias (already done if you ran deploy-config.sh)
echo 'alias locallu="zsh ~/MasterBase/locallu/locallu.sh"' >> ~/.zshrc
echo 'alias llu=locallu' >> ~/.zshrc
source ~/.zshrc

# Install dependencies (Ollama required for most models)
brew install ollama
ollama serve &  # start in background
```

---

## Usage

```bash
locallu                            # fully interactive wizard
llu                                # short alias

locallu --list-models              # show all discovered local models
locallu --list-agents              # show all supported agents
locallu --pull llama3.2            # download model via Ollama
locallu --pull qwen2.5-coder:7b
locallu --pull deepseek-r1:8b

# Skip steps with flags
locallu --agent "Codex (CLI)" --model qwen2.5-coder:7b
locallu --model gemma4:e4b
```

---

## Local Models (pre-configured)

Models already available in `~/MasterBase/local-models/`:

| Model | Size | Capabilities |
|-------|------|-------------|
| **Qwopus3.6-27B-v2-MTP** | 27B | Code, reasoning, vision (GGUF) |

Models available via Ollama (your system):

| Model | Capabilities |
|-------|-------------|
| qwen2.5vl:7b | Vision + language |
| qwen3.5:397b | Frontier-class reasoning |
| gemma4:e2b / e4b | Google Gemma 4 |
| qwen3-coder | Code specialist |
| minimax-m2.7 | Multimodal |

---

## Model Capability Auto-Detection

locallu inspects the model name and auto-detects:

- 👁 **Vision** — models with `vl`, `vision`, `llava`, `qwen.*vl`
- 🔧 **Tool calling** — `qwen`, `llama3`, `mistral`, `hermes`, `functionary`
- 💻 **Code** — `coder`, `deepseek.*code`, `qwen.*coder`, `starcoder`
- 🧠 **Reasoning** — `r1`, `thinking`, `o1`, `qwq`, `opus`
- 🔍 **Embeddings** — `embed`, `nomic`, `bge`, `e5`
- 📐 **Math** — `math`, `wizard`, `numina`

---

## llmfit Integration

[llmfit](https://github.com/jmorganca/ollama) provides a unified interface for downloading and running models.

```bash
# Install
pip install llmfit

# Use via locallu
locallu  # select "llmfit (CLI)" → pick model
```

---

## Adding the Qwopus 27B GGUF Model

```bash
# Register with Ollama (creates Modelfile pointing to GGUF)
locallu --register-gguf ~/MasterBase/local-models/Qwopus3.6-27B-v2-MTP-GGUF/model.gguf Qwopus3.6-27B

# Or manually
cat > /tmp/Modelfile << 'EOF'
FROM ~/MasterBase/local-models/Qwopus3.6-27B-v2-MTP-GGUF/model.gguf
PARAMETER num_gpu 99
PARAMETER num_ctx 32768
EOF
ollama create Qwopus3.6-27B -f /tmp/Modelfile
ollama run Qwopus3.6-27B
```

---

## Free Model Quick Reference

Zero-cost models accessible right now:

```bash
# Via Ollama (local — zero cost, no API key)
ollama pull llama3.2
ollama pull qwen2.5-coder:7b
ollama pull phi4
ollama pull deepseek-r1:8b
ollama pull gemma3:4b

# Via OpenRouter (free tier with key)
# google/gemini-flash-1.5:free
# deepseek/deepseek-r1:free
# meta-llama/llama-3.1-8b-instruct:free
# qwen/qwen-2.5-72b-instruct:free
```

---

## GitHub

**Repo**: https://github.com/krishnasureshcpa/locallu  
**Author**: Krishna ([@krishnasureshcpa](https://github.com/krishnasureshcpa))  
**License**: MIT
