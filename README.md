# 🤖 OpenClaw × Antigravity Bridge

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
| **Gemini 3.1 Pro** (high/low thinking) | `gemini-3.1-pro-high` / `gemini-3.1-pro-low` | 🆓 Quota Google |
| **Gemini 3 Flash** | `gemini-3-flash` | 🆓 Quota Google |
| **Gemini 2.5 Pro / Flash** | `gemini-2.5-pro` / `gemini-2.5-flash` | 🆓 Quota Google |
| **Gemini 3.1 Flash** (image/lite) | `gemini-3.1-flash-image` / `gemini-3.1-flash-lite` | 🆓 Quota Google |

> ⚠️ **Aviso Legal:** O uso de proxies não-oficiais para acessar APIs do Google pode violar os Termos de Serviço. Relatos de bans de conta existem. **Use contas descartáveis, não sua conta principal.** Veja [Segurança](#-segurança) para detalhes.

---

## 📋 Pré-requisitos

- **Node.js** v18+
- **OpenClaw Gateway** instalado (`npm install -g openclaw`)
- **Uma conta Google** (de preferência descartável)
- (Opcional) **OpenCode** com `opencode-antigravity-auth` para reutilizar tokens existentes

---

## 🚀 Instalação

### 1. Instalar o Proxy

```powershell
npm install -g antigravity-claude-proxy@latest
```

### 2. Iniciar o Proxy

```powershell
# Como serviço de fundo
acc start

# Ou em foreground para ver logs
acc start --log
```

Acesse o dashboard em: **http://localhost:8080**

### 3. Adicionar Conta Google

**Via Web UI (recomendado):**
1. Abra http://localhost:8080
2. Vá em **Accounts → Add Account**
3. Faça login com sua conta Google
4. Autorize as permissões (Cloud Code, perfil, email)

**Via CLI (headless):**
```powershell
acc accounts add --no-browser
# Abra o URL gerado no navegador
# Após autorizar, cole o código de volta no terminal
```

**Via OpenCode (reutilizar tokens existentes):**
```powershell
# Se já tem contas configuradas no opencode-antigravity-auth:
.\scripts\import-opencode-accounts.ps1
```

### 4. Configurar OpenClaw Gateway

Adicione o provider abaixo ao seu `~/.openclaw/openclaw.json`:

```json
{
  "models": {
    "providers": {
      "antigravity-proxy": {
        "baseUrl": "http://127.0.0.1:8080",
        "apiKey": "test",
        "api": "anthropic-messages",
        "models": [
          {
            "id": "claude-opus-4-6-thinking",
            "name": "Claude Opus 4.6 Thinking",
            "reasoning": true,
            "input": ["text", "image"],
            "cost": { "input": 0, "output": 0 },
            "contextWindow": 200000,
            "maxTokens": 32000
          },
          {
            "id": "claude-sonnet-4-6",
            "name": "Claude Sonnet 4.6",
            "reasoning": false,
            "input": ["text", "image"],
            "cost": { "input": 0, "output": 0 },
            "contextWindow": 200000,
            "maxTokens": 16384
          },
          {
            "id": "claude-sonnet-4-6-thinking",
            "name": "Claude Sonnet 4.6 Thinking",
            "reasoning": true,
            "input": ["text", "image"],
            "cost": { "input": 0, "output": 0 },
            "contextWindow": 200000,
            "maxTokens": 16384
          },
          {
            "id": "gemini-3-flash",
            "name": "Gemini 3 Flash",
            "reasoning": true,
            "input": ["text", "image"],
            "cost": { "input": 0, "output": 0 },
            "contextWindow": 1048576,
            "maxTokens": 65536
          },
          {
            "id": "gemini-3.1-pro-high",
            "name": "Gemini 3.1 Pro High",
            "reasoning": true,
            "input": ["text", "image"],
            "cost": { "input": 0, "output": 0 },
            "contextWindow": 1048576,
            "maxTokens": 65536
          },
          {
            "id": "gemini-2.5-flash",
            "name": "Gemini 2.5 Flash",
            "reasoning": true,
            "input": ["text", "image"],
            "cost": { "input": 0, "output": 0 },
            "contextWindow": 1048576,
            "maxTokens": 65536
          }
        ]
      }
    }
  }
}
```

> **Importante:** Use `127.0.0.1` em vez de `localhost` no `baseUrl` — evita problemas de resolução DNS.

### 5. (Opcional) Adicionar Aliases

Para ver nomes amigáveis no OpenClaw:

```json
{
  "agents": {
    "defaults": {
      "models": {
        "antigravity-proxy/claude-opus-4-6-thinking": {
          "alias": "Claude Opus 4.6 Thinking (Antigravity)"
        },
        "antigravity-proxy/claude-sonnet-4-6": {
          "alias": "Claude Sonnet 4.6 (Antigravity)"
        },
        "antigravity-proxy/gemini-3.1-pro-high": {
          "alias": "Gemini 3.1 Pro High (Antigravity)"
        },
        "antigravity-proxy/gemini-3-flash": {
          "alias": "Gemini 3 Flash (Antigravity)"
        }
      }
    }
  }
}
```

### 6. Reiniciar o Gateway

```powershell
openclaw gateway restart
```

Verifique se os modelos apareceram:

```powershell
openclaw models list | Select-String "antigravity"
```

---

## 🎮 Uso

### No OpenClaw

```powershell
# Ver modelos disponíveis
openclaw models list

# Mudar modelo padrão
openclaw models set antigravity-proxy/claude-opus-4-6-thinking

# Usar em sub-agentes (diretamente)
# defina model="antigravity-proxy/claude-opus-4-6-thinking"
```

### No Claude Code

```powershell
$env:ANTHROPIC_BASE_URL = "http://localhost:8080"
$env:ANTHROPIC_API_KEY = "test"
claude --model claude-opus-4-6-thinking
```

### Gerenciar o Proxy

```powershell
acc status        # Ver status do proxy
acc ui            # Abrir dashboard
acc restart       # Reiniciar proxy
acc stop          # Parar proxy
acc accounts list # Listar contas conectadas
acc accounts add  # Adicionar nova conta
```

---

## 🔄 Multi-Account

O proxy suporta **múltiplas contas Google** com rotação automática. Quando uma conta atinge o limite de taxa, o proxy alterna para a próxima automaticamente.

Para adicionar mais contas:

```powershell
acc accounts add --no-browser
# Repita para cada conta extra
```

Estratégias de balanceamento:
- **hybrid** (padrão): combina health score + tempo ocioso
- **sticky**: mantém sessão consistente para um cliente
- **round-robin**: alterna entre contas igualmente

```powershell
acc start --strategy=sticky
```

---

## 🛠️ Scripts Inclusos

| Script | Descrição |
|--------|-----------|
| `scripts/start-proxy.ps1` | Inicia/gerencia o proxy como serviço |
| `scripts/import-opencode-accounts.ps1` | Importa contas do OpenCode antigravity-auth |

---

## ⚠️ Segurança

### Riscos
- **Google pode banir sua conta** por violação de ToS
- O proxy expõe uma API local sem autenticação real
- O token de atualização OAuth é armazenado em texto plano

### Mitigações
- ✅ Use **contas Google descartáveis**, não sua conta principal
- ✅ Restrinja o proxy ao localhost: `HOST=127.0.0.1 acc start`
- ✅ Não exponha a porta 8080 à rede pública
- ✅ Em VPS, use firewall ou VPN

---

## 🔍 Troubleshooting

| Problema | Causa | Solução |
|----------|-------|---------|
| Account status "error" | Token expirado | Refaça OAuth: `acc accounts add` |
| 401 nos logs | Sessão do Antigravity expirada | Reautentique no Antigravity IDE ou use OAuth |
| "Failed to fetch models" | Conta sem acesso ao Cloud Code | Verifique permissões da conta Google |
| Proxy offline | Processo morreu | `acc restart` |
| Botão "Add Account" não funciona | Proxy detectou sessão local | Use `acc accounts add --no-browser` |

### Reset Completo

```powershell
acc stop
Remove-Item "$env:USERPROFILE\.antigravity-claude-proxy\accounts.json" -Force
acc start
acc accounts add
```

---

## 🏗️ Arquitetura

```
┌────────────────────┐     ┌──────────────────────────┐     ┌─────────────────────┐
│  OpenClaw Gateway  │────▶│ antigravity-claude-proxy │────▶│  Google Antigravity │
│  (anthropic api)   │     │  (localhost:8080)        │     │  Cloud Code API     │
└────────────────────┘     │                          │     └─────────────────────┘
                           │  ┌──────────────────┐    │
                           │  │  Account Pool    │    │
                           │  │  ┌────────────┐  │    │
                           │  │  │ 🟢 Conta 1 │  │    │
                           │  │  │ 🟢 Conta 2 │  │    │
                           │  │  │ 🟡 Conta 3 │  │    │
                           │  │  └────────────┘  │    │
                           │  │  ⟳ Rotação auto │    │
                           │  └──────────────────┘    │
                           └──────────────────────────┘
```

---

## 📦 Dependências

- [antigravity-claude-proxy](https://github.com/badrisnarayanan/antigravity-claude-proxy) — Proxy que expõe modelos Antigravity via API compatível com Anthropic
- [opencode-antigravity-auth](https://github.com/NoeFabris/opencode-antigravity-auth) — Plugin OpenCode para autenticação Antigravity (fonte dos tokens)
- [OpenClaw Gateway](https://docs.openclaw.ai) — Gateway multi-agente

---

## 📄 Licença

MIT — Use por sua conta e risco.

---

*Feito com 🦉 por Luna e dr. Roger (@rog3r)*
