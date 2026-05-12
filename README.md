# 🛸 OpenClaw × Antigravity Bridge

Conecte seu **OpenClaw Gateway** aos modelos do **Google Antigravity** — Claude Opus 4.6 Thinking, Claude Sonnet 4.6, Gemini 3.1 Pro e outros — usando sua cota do Google Cloud.

```
OpenClaw Gateway → antigravity-claude-proxy (:8080) → Google Antigravity
```

---

## 📋 Índice

- [Pré-requisitos](#-pré-requisitos)
- [Instalação Passo a Passo](#-instalação-passo-a-passo)
- [Gerenciar o Proxy](#-gerenciar-o-proxy)
- [Gerenciar Contas](#-gerenciar-contas)
- [Configurar OpenClaw](#-configurar-openclaw)
- [Uso](#-uso)
- [Multi-Account](#-multi-account)
- [Segurança](#-segurança)
- [Troubleshooting](#-troubleshooting)

---

## 📋 Pré-requisitos

| Item | Versão Mínima | Como verificar |
|------|--------------|----------------|
| **Node.js** | v18+ | `node -v` |
| **npm** | (vem com Node) | `npm -v` |
| **OpenClaw Gateway** | qualquer | `openclaw --version` |
| **Conta Google** | — | (descartável recomendada) |

---

## 🚀 Instalação Passo a Passo

### 1. Instalar o Proxy

```powershell
npm install -g antigravity-claude-proxy@latest
```

Verifique se o comando `acc` ficou disponível:

```powershell
acc --help
```

### 2. Iniciar o Proxy

```powershell
acc start
```

O proxy sobe em **http://127.0.0.1:8080** (ou localhost:8080).

> ⚠️ Se encontrar problemas, rode em foreground para ver logs:
> ```powershell
> acc start --log
> ```

### 3. Acessar o Dashboard

Abra http://127.0.0.1:8080 no navegador.

Você verá a interface web do proxy com:
- Status do servidor
- Gerenciamento de contas (Accounts)
- Logs em tempo real

### 4. Adicionar Conta Google

**Via Web UI (recomendado para primeira conta):**
1. http://127.0.0.1:8080 → **Accounts → Add Account**
2. Faça login com sua conta Google
3. Autorize as permissões (Cloud Code, perfil, email)
4. Pronto! A conta aparece na lista

**Via CLI (headless — para servidores sem navegador):**
```powershell
acc accounts add --no-browser
# Abra o URL gerado em qualquer navegador
# Após autorizar, cole o código de volta no terminal
```

**Via OpenCode (reutilizar contas existentes):**
```powershell
.\scripts\import-opencode-accounts.ps1
```

### 5. Verificar Contas

```powershell
acc accounts list
```

Saída esperada:
```
📋 Linked Accounts:
  🟢 usuario@gmail.com (OAuth)
```

### 6. Configurar OpenClaw Gateway

Adicione o provider ao seu `~/.openclaw/openclaw.json`:

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

> **Importante:** Use `127.0.0.1` e não `localhost` no `baseUrl` — evita problemas de resolução DNS no Windows.

### 7. Reiniciar o Gateway

```powershell
openclaw gateway restart
```

### 8. Testar

```powershell
openclaw models list | Select-String "antigravity"
```

Deverá listar todos os modelos configurados.

---

## 🛸 Gerenciar o Proxy

| Comando | Descrição |
|---------|-----------|
| `acc status` | Status do proxy (online/offline, versão) |
| `acc start` | Iniciar como serviço de fundo |
| `acc start --log` | Iniciar com logs visíveis |
| `acc stop` | Parar o proxy |
| `acc restart` | Reiniciar |
| `acc ui` | Abrir dashboard no navegador |

---

## 👤 Gerenciar Contas

### No Dashboard Web

Abra http://127.0.0.1:8080 → **Accounts** → Add/Remove/List

### Via CLI

```powershell
acc accounts list           # Listar contas
acc accounts add            # Adicionar (abre navegador)
acc accounts add --no-browser  # Adicionar (headless)
acc accounts remove <email> # Remover conta
acc accounts verify         # Verificar saúde
acc accounts clear          # Remover TODAS as contas
```

### Estratégias de Balanceamento

Ao iniciar o proxy, escolha a estratégia:

```powershell
acc start --strategy=hybrid       # (padrão) health score + tempo ocioso
acc start --strategy=sticky       # Sessão consistente (prompt caching)
acc start --strategy=round-robin  # Alterna igualmente entre contas
```

### Script de Setup Automático

```powershell
.\scripts\setup.ps1
```

Faz toda a instalação guiada: verifica Node.js, instala o proxy, inicia, e ajuda a configurar a primeira conta.

---

## ⚙️ Configurar OpenClaw

### Modelos Disponíveis

| Modelo | Proxy ID | Janela de Contexto |
|--------|----------|-------------------|
| Claude Opus 4.6 Thinking | `claude-opus-4-6-thinking` | 200K |
| Claude Sonnet 4.6 | `claude-sonnet-4-6` | 200K |
| Claude Sonnet 4.6 Thinking | `claude-sonnet-4-6-thinking` | 200K |
| Gemini 3 Flash | `gemini-3-flash` | 1M |
| Gemini 3.1 Pro High | `gemini-3.1-pro-high` | 1M |
| Gemini 2.5 Flash | `gemini-2.5-flash` | 1M |

### Uso no OpenClaw

```powershell
# Ver modelos
openclaw models list

# Mudar modelo padrão
openclaw models set antigravity-proxy/claude-opus-4-6-thinking

# Usar em sub-agentes
# model="antigravity-proxy/claude-opus-4-6-thinking"
```

### Uso no Claude Code

```powershell
$env:ANTHROPIC_BASE_URL = "http://localhost:8080"
$env:ANTHROPIC_API_KEY = "test"
claude --model claude-opus-4-6-thinking
```

---

## 🔄 Multi-Account

O proxy suporta múltiplas contas Google com rotação automática. Quando uma conta atinge o limite de taxa, o proxy alterna para a próxima automaticamente.

```powershell
# Adicionar quantas contas quiser
acc accounts add --no-browser
```

### Como o balanceamento funciona

1. Cada conta tem um **health score** (começa em 70, máximo 100)
2. Requisições bem-sucedidas → +1 de score
3. Rate limit → -10 de score
4. Erro → -20 de score
5. Contas com score abaixo de 50 não são usadas
6. O proxy também considera: tokens disponíveis, quota restante, tempo desde último uso

---

## ⚠️ Segurança

### Riscos Conhecidos
- **Google pode banir sua conta** por violação de ToS ao usar APIs via proxy não-oficial
- O proxy armazena o refresh token OAuth em texto plano
- A porta 8080 não tem autenticação real

### Boas Práticas
- ✅ Use **contas Google descartáveis**, nunca sua conta principal
- ✅ Mantenha o proxy preso ao localhost (`HOST=127.0.0.1 acc start`)
- ✅ **Nunca** exponha a porta 8080 à rede pública
- ✅ Em servidores, use VPN ou firewall para restringir acesso
- ✅ Evite compartilhar screenshots ou logs com emails de conta

---

## 🔍 Troubleshooting

| Problema | Causa | Solução |
|----------|-------|---------|
| `acc` não encontrado | Proxy não instalado | `npm install -g antigravity-claude-proxy@latest` |
| Porta 8080 em uso | Outro serviço na porta | Mude a porta: `PORT=3000 acc start` |
| Account status "error" | Token OAuth expirado | `acc accounts add` para reautenticar |
| 401 nos logs | Sessão Antigravity expirada | Refaça OAuth |
| "Failed to fetch models" | Conta sem Cloud Code | Verifique permissões da conta Google |
| Proxy caiu sozinho | Processo morreu | `acc restart` |
| Botão "Add Account" não funciona | Detectou sessão local no navegador | Use `acc accounts add --no-browser` |

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
┌────────────────────┐     ┌──────────────────────────┐     ┌──────────────────────┐
│  OpenClaw Gateway  │────▶│ antigravity-claude-proxy │────▶│  Google Antigravity │
│  (anthropic api)   │     │  (localhost:8080)        │     │  Cloud Code API     │
└────────────────────┘     │                          │     └──────────────────────┘
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

- [antigravity-claude-proxy](https://github.com/badrisnarayanan/antigravity-claude-proxy) (v2.8.3+) — Proxy que expõe modelos Antigravity via API compatível com Anthropic
- [opencode-antigravity-auth](https://github.com/NoeFabris/opencode-antigravity-auth) — Plugin para autenticação (fonte de tokens alternativos)
- [OpenClaw Gateway](https://docs.openclaw.ai) — Gateway multi-agente

---

## 📄 Licença

MIT — Use por sua conta e risco. Veja o [Aviso de Segurança](#-segurança).

---

*Feito com 🦉 por Luna e dr. Roger (@rog3r)*
