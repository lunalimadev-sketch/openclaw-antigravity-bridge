# 🛸 OpenClaw × Antigravity Bridge

Conecte seu **OpenClaw Gateway** aos modelos do **Google Antigravity** — incluindo **Claude Opus 4.6 Thinking**, **Claude Sonnet 4.6** e **Gemini 3.1 Pro** — sem custo adicional, usando sua cota do Google Cloud.

```
OpenClaw Gateway → antigravity-claude-proxy (localhost:8080) → Google Antigravity API
```

---

## ✨ Modelos Disponíveis

| Modelo | Proxy ID | Custo |
|--------|----------|-------|
| **Claude Opus 4.6** (thinking) | `claude-opus-4-6-thinking` | 🆓 Quota Google |
| **Claude Sonnet 4.6** (thinking) | `claude-sonnet-4-6-thinking` | 🆓 Quota Google |
| **Claude Sonnet 4.6** | `claude-sonnet-4-6` | 🆓 Quota Google |
| **Gemini 3.1 Pro** (high/low) | `gemini-3.1-pro-high` / `gemini-3.1-pro-low` | 🆓 Quota Google |
| **Gemini 3 Flash** | `gemini-3-flash` | 🆓 Quota Google |
| **Gemini 2.5 Pro / Flash** | `gemini-2.5-pro` / `gemini-2.5-flash` | 🆓 Quota Google |
| **Gemini 3.1 Flash** (image/lite) | `gemini-3.1-flash-image` / `gemini-3.1-flash-lite` | 🆓 Quota Google |

> ⚠️ **Aviso Legal:** O uso de proxies não-oficiais para acessar APIs do Google pode violar os Termos de Serviço. Relatos de bans de conta existem. **Use contas descartáveis, não sua conta principal.**

---

## 📋 Pré-requisitos

- **Node.js** v18+
- **OpenClaw Gateway** (`npm install -g openclaw`)
- **Uma conta Google** (descartável)
- (Opcional) **OpenCode** com `opencode-antigravity-auth`

---

## 🚀 Instalação Rápida

```powershell
npm install -g antigravity-claude-proxy@latest
acc start
```

Acesse http://localhost:8080 → **Accounts → Add Account** → autorize.

### Configurar OpenClaw Gateway

Adicione ao `~/.openclaw/openclaw.json`:

```json
{
  "models": {
    "providers": {
      "antigravity-proxy": {
        "baseUrl": "http://127.0.0.1:8080",
        "apiKey": "test",
        "api": "anthropic-messages",
        "models": [
          { "id": "claude-opus-4-6-thinking", "name": "Claude Opus 4.6 Thinking", "reasoning": true, "input": ["text","image"], "cost": { "input": 0, "output": 0 }, "contextWindow": 200000, "maxTokens": 32000 },
          { "id": "claude-sonnet-4-6", "name": "Claude Sonnet 4.6", "reasoning": false, "input": ["text","image"], "cost": { "input": 0, "output": 0 }, "contextWindow": 200000, "maxTokens": 16384 },
          { "id": "claude-sonnet-4-6-thinking", "name": "Claude Sonnet 4.6 Thinking", "reasoning": true, "input": ["text","image"], "cost": { "input": 0, "output": 0 }, "contextWindow": 200000, "maxTokens": 16384 },
          { "id": "gemini-3-flash", "name": "Gemini 3 Flash", "reasoning": true, "input": ["text","image"], "cost": { "input": 0, "output": 0 }, "contextWindow": 1048576, "maxTokens": 65536 },
          { "id": "gemini-3.1-pro-high", "name": "Gemini 3.1 Pro High", "reasoning": true, "input": ["text","image"], "cost": { "input": 0, "output": 0 }, "contextWindow": 1048576, "maxTokens": 65536 },
          { "id": "gemini-2.5-flash", "name": "Gemini 2.5 Flash", "reasoning": true, "input": ["text","image"], "cost": { "input": 0, "output": 0 }, "contextWindow": 1048576, "maxTokens": 65536 }
        ]
      }
    }
  }
}
```

> Use `127.0.0.1` não `localhost` no `baseUrl`.

```powershell
openclaw gateway restart
openclaw models list | Select-String "antigravity"
```

---

## 👤 Gerenciamento de Contas

Script completo para gerenciar suas contas Google no proxy:

```powershell
.\scripts\manage-accounts.ps1 list       # Listar contas + status
.\scripts\manage-accounts.ps1 health     # Verificar saúde de cada conta
.\scripts\manage-accounts.ps1 add        # Adicionar nova conta (OAuth)
.\scripts\manage-accounts.ps1 remove     # Remover conta
.\scripts\manage-accounts.ps1 config     # Ver configuração do proxy
.\scripts\manage-accounts.ps1 status     # Status geral do proxy
.\scripts\manage-accounts.ps1 strategy   # Trocar estratégia (hybrid/sticky/round-robin)
.\scripts\manage-accounts.ps1 restart    # Reiniciar proxy
```

### Exemplo de saída

```
[OK] Conta #1: usuario@gmail.com (via oauth)
   Ultimo uso: 12/05/2026 10:30:00

Resumo: 2 total | 2 disponiveis | 0 rate limited | 0 invalidas
```

### Estratégias de Balanceamento

- **hybrid** (padrão): health score + tempo ocioso
- **sticky**: consistência de sessão para quem usa prompt caching
- **round-robin**: alterna entre contas igualmente

```powershell
.\scripts\manage-accounts.ps1 strategy sticky
```

### Reutilizar Tokens do OpenCode

Se já tem contas no `opencode-antigravity-auth`:

```powershell
.\scripts\import-opencode-accounts.ps1
```

---

## 📊 Dashboard

Dashboard HTML local com visualização em tempo real:

```powershell
.\scripts\dashboard.ps1
```

Gera e abre uma página mostrando:
- Status do proxy (online/offline)
- Contas configuradas com indicadores visuais
- Métricas de configuração (estratégia, health score, pesos)
- Links rápidos para adicionar conta

> O dashboard consulta a API do proxy em `http://127.0.0.1:8080/api/accounts` — o proxy precisa estar rodando.

---

## 🛠️ Scripts Inclusos

| Script | Descrição |
|--------|-----------|
| `scripts/manage-accounts.ps1` | CLI completa de gerenciamento de contas |
| `scripts/dashboard.ps1` | Gera dashboard HTML local |
| `scripts/import-opencode-accounts.ps1` | Importa contas do OpenCode |
| `scripts/bidirectional.ps1` | Fluxo OpenClaw ↔ Antigravity (captura + POST) |
| `scripts/execute.ps1` | Injeta prompt na GUI do Antigravity |
| `scripts/ask.ps1` | Atalho para testes rápidos |

---

## 🎮 Uso no OpenClaw

```powershell
openclaw models list
openclaw models set antigravity-proxy/claude-opus-4-6-thinking
```

### No Claude Code

```powershell
$env:ANTHROPIC_BASE_URL = "http://localhost:8080"
$env:ANTHROPIC_API_KEY = "test"
claude --model claude-opus-4-6-thinking
```

### Comandos rápidos do Proxy

```powershell
acc status        # Status do proxy
acc ui            # Abrir dashboard
acc restart       # Reiniciar
acc stop          # Parar
acc accounts list # Listar contas
acc accounts add  # Adicionar conta
```

---

## 🔄 Multi-Account

O proxy suporta múltiplas contas com rotação automática:

```powershell
acc accounts add --no-browser
# Cole o código de autorização
```

---

## 🔍 Troubleshooting

| Problema | Causa | Solução |
|----------|-------|---------|
| Account "error" | Token expirado | `acc accounts add` |
| 401 nos logs | Sessão expirada | Reautentique |
| "Failed to fetch models" | Sem acesso Cloud Code | Verifique permissões |
| Proxy offline | Processo morreu | `acc restart` |
| Add Account não funciona | Detectou sessão local | Use `--no-browser` |

### Reset Completo

```powershell
acc stop
Remove-Item "$env:USERPROFILE\.antigravity-claude-proxy\accounts.json" -Force
acc start
acc accounts add
```

---

## ⚠️ Segurança

**Riscos:**
- Google pode banir sua conta por violação de ToS
- Proxy expõe API local sem autenticação real
- Token OAuth armazenado em texto plano

**Mitigações:**
- ✅ Use contas descartáveis
- ✅ `HOST=127.0.0.1 acc start`
- ✅ Não exponha porta 8080 à rede pública

---

## 🏗️ Arquitetura

```
OpenClaw Gateway  ──▶  antigravity-claude-proxy  ──▶  Google Antigravity
(anthropic api)       (localhost:8080)               (Cloud Code API)
                            │
                    ┌───────┴───────┐
                    │  Account Pool │
                    │  🟢 🟢 🟡   │
                    │  ⟳ Rotação   │
                    └───────────────┘
```

---

## 📦 Dependências

- [antigravity-claude-proxy](https://github.com/lunalimadev-sketch/openclaw-antigravity-bridge) — Proxy que expõe modelos Antigravity via API Anthropic
- [opencode-antigravity-auth](https://github.com/NoeFabris/opencode-antigravity-auth) — Plugin OpenCode para autenticação
- [OpenClaw Gateway](https://docs.openclaw.ai) — Gateway multi-agente

---

## 📄 Licença

MIT — Use por sua conta e risco.

---

*Feito com 🦉 por Luna e dr. Roger (@rog3r)*
