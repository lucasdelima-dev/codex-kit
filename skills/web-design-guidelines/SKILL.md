---
name: web-design-guidelines
description: Revise código de interface web usando as Web Interface Guidelines da Vercel armazenadas localmente. Use para revisão de UI, UX, acessibilidade, formulários, foco, interação, responsividade, performance visual, i18n e anti-patterns.
---

# Vercel Web Design Guidelines

Use esta Skill para revisar código de interface web.

## Fonte

A referência normativa desta Skill está em:

`references/guidelines.md`

Snapshot de:

`vercel-labs/web-interface-guidelines`

Commit:

`e3d624baaf29dc1fc645aff3e38f03e564d2d6b1`

## Regras obrigatórias

- Leia `references/guidelines.md` antes da revisão.
- Use exclusivamente a cópia local das guidelines.
- Não faça fetch, curl, wget, WebFetch ou consulta externa para atualizar as regras durante a tarefa.
- Não envie código, nomes internos, caminhos, arquitetura ou contexto do projeto para serviços externos.
- Revise somente os arquivos ou escopo pertinentes à solicitação.
- Não modifique arquivos apenas porque encontrou problemas; revisão e correção são tarefas distintas.
- Quando a solicitação for apenas auditoria, produza somente os achados.
- Preserve regras do repositório e instruções de maior prioridade.

## Saída

Siga o formato definido em `references/guidelines.md`.

Prefira achados concisos no formato:

`arquivo:linha - problema`

Agrupe por arquivo.

Quando não houver violações relevantes, indique `✓ pass`.

Não invente violações quando uma regra não puder ser confirmada pelo código disponível.
