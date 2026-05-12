---
name: antigravity-bridge
description: >
  Delega tarefas de programação complexas para o Antigravity IDE (Gemini / Claude Sonnet)
  e retorna a resposta diretamente para o agente OpenClaw via API REST.
  Também gerencia contas Google do proxy antigravity-claude-proxy.
status: READY
trigger: >
  Ative esta skill quando precisar de código avançado, refatoração profunda,
  gerenciar contas do proxy Antigravity, ou contexto grande demais para o modelo local.
---

# Skill: Antigravity Bridge

Bridge entre OpenClaw Gateway e Google Antigravity (Claude, Gemini).

## Arquitetura

```
OpenClaw Gateway ──▶ antigravity-claude-proxy (:8080) ──▶ Google Antigravity
                           │
                   ┌───────┴───────┐
                   │  Account Pool │  ← gerenciado por manage-accounts.ps1
                   └───────────────┘
```

## Gerenciamento de Contas

Use `manage-accounts.ps1` para administrar as contas Google do proxy:

```powershell
# Listar contas e status
powershell -ExecutionPolicy Bypass -File skills/antigravity/scripts/manage-accounts.ps1 list

# Verificar saúde de todas as contas
powershell -ExecutionPolicy Bypass -File skills/antigravity/scripts/manage-accounts.ps1 health

# Ver configuração do proxy
powershell -ExecutionPolicy Bypass -File skills/antigravity/scripts/manage-accounts.ps1 config

# Status geral do proxy
powershell -ExecutionPolicy Bypass -File skills/antigravity/scripts/manage-accounts.ps1 status

# Adicionar nova conta (abre navegador para OAuth)
powershell -ExecutionPolicy Bypass -File skills/antigravity/scripts/manage-accounts.ps1 add

# Remover conta
powershell -ExecutionPolicy Bypass -File skills/antigravity/scripts/manage-accounts.ps1 remove

# Trocar estratégia de balanceamento (hybrid|sticky|round-robin)
powershell -ExecutionPolicy Bypass -File skills/antigravity/scripts/manage-accounts.ps1 strategy sticky

# Reiniciar proxy
powershell -ExecutionPolicy Bypass -File skills/antigravity/scripts/manage-accounts.ps1 restart
```

## Dashboard

Gere um dashboard HTML local com status visual:

```powershell
powershell -ExecutionPolicy Bypass -File skills/antigravity/scripts/dashboard.ps1
```

## Delegar Código para o Antigravity IDE

Para enviar tarefas complexas de programação ao Antigravity (Gemini/Claude):

```powershell
powershell -ExecutionPolicy Bypass -File skills/antigravity/scripts/bidirectional.ps1 -Prompt "<seu prompt>"
```

### Fluxo
1. Script injeta o prompt no Antigravity IDE via `agy chat --reuse-window`
2. Aguarda a resposta ser gerada
3. Captura via clipboard (Ctrl+A, Ctrl+C)
4. Posta a resposta na API REST do OpenClaw (porta 18789)

## Importar Contas do OpenCode

Se já tem contas no `opencode-antigravity-auth`:

```powershell
powershell -ExecutionPolicy Bypass -File skills/antigravity/scripts/import-opencode-accounts.ps1
```

## Comandos Rápidos do Proxy

```powershell
acc status        # Status
acc restart       # Reiniciar
acc accounts list # Listar contas
acc accounts add  # Adicionar
acc ui            # Dashboard web
```

## Pré-requisitos
- `antigravity-claude-proxy` instalado (`npm install -g`)
- Proxy rodando em `http://127.0.0.1:8080`
- Para delegar código: `agy` no PATH + Antigravity IDE aberto
- Para dashboard + account mgmt: proxy precisa estar respondendo

## Notas de Segurança
- **NUNCA** inclua tokens, API keys ou emails de contas em arquivos públicos
- Use contas Google descartáveis, não a principal
- O proxy só deve escutar em 127.0.0.1, nunca em 0.0.0.0
