---
name: beads-cli
description: Use o Beads localmente no repositório atual para acompanhar tarefas, dependências, bloqueios e progresso de implementação. Quando o projeto utilizar OpenSpec, ele continua sendo a fonte de verdade de requisitos e escopo.
---

# Beads CLI

Use `bd` diretamente no repositório:

`.`

## Responsabilidades

OpenSpec:
- requisitos;
- escopo;
- decisões;
- tasks oficiais da change.

Beads:
- estado de execução;
- tarefas em andamento;
- dependências;
- bloqueios;
- progresso local.

Superpowers:
- implementação;
- debugging;
- TDD;
- revisão;
- verificação.

## Comandos principais

Contexto:

`bd where`
`bd status`
`bd context`

Trabalho disponível:

`bd ready`
`bd blocked`
`bd list`

Consultar tarefa:

`bd show ID`

Criar tarefa:

`bd create "TÍTULO"`

Atualizar tarefa:

`bd update ID`

Fechar tarefa:

`bd close ID`

Dependências:

`bd dep`
`bd link`
`bd graph`

Notas e comentários:

`bd note ID`
`bd comment ID`

Use `--json` quando a saída estruturada reduzir ambiguidade.

## Segurança

O Beads deste repositório é local e privado.

Sempre respeite:
- `no-git-ops=true`;
- `export.git-add=false`;
- nenhum Dolt remote configurado.

Não execute automaticamente:
- `bd sync`;
- `bd vc`;
- `bd gitlab`;
- `bd github`;
- `bd jira`;
- `bd linear`;
- `bd notion`;
- `bd federation`;
- `bd hooks`;
- `bd setup`;
- `bd dolt remote`;
- `bd worktree`.

Não altere `AGENTS.md`.

Não publique, exporte, faça push ou configure remoto para dados do Beads.

Se uma operação puder enviar dados para fora da máquina, peça autorização explícita.

## Integração com OpenSpec

Não transforme tarefas do Beads em nova fonte de requisitos.

Quando existir uma change OpenSpec:
1. consulte a change;
2. derive o trabalho operacional dela;
3. use Beads apenas para acompanhar execução;
4. não amplie o escopo.

## Descoberta

Se precisar de flags específicas, consulte somente:

`bd COMANDO --help`

Não faça configuração global ou integração como tentativa de resolver uma dúvida.
