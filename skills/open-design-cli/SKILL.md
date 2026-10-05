---
name: open-design-cli
description: Usa o OpenDesign local para prototipação, design systems e exploração visual em perfis de frontend.
---

# OpenDesign

Use o comando local `od` para tarefas de design e prototipação visual.

## Quando usar

- protótipos de interface
- exploração visual
- design systems
- composição de telas
- artefatos visuais
- iteração de UX/UI

## Regras

- Não execute `od mcp install codex`.
- Não registre OpenDesign como MCP nativo.
- Não altere configurações MCP automaticamente.
- Não use OpenDesign no perfil Intraer.
- Não envie conteúdo interno/confidencial para providers externos.
- Não configure BYOK ou APIs externas sem solicitação explícita.
- Não habilite telemetria.
- Preserve as proteções do wrapper `~/.local/bin/od`.

## Divisão de responsabilidades

- OpenDesign: criação e exploração visual.
- UI/UX Pro Max: direção visual e design system.
- Web Design Guidelines: auditoria de interface.
- agent-browser: inspeção rápida.
- Playwright: E2E e regressão.
- Chrome DevTools: diagnóstico técnico.
