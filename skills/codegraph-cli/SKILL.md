---
name: codegraph-cli
description: Use o CodeGraph diretamente pela CLI para analisar arquitetura, dependências, relações entre símbolos, callers e callees, impacto de alterações e estrutura ampla do repositório atual. Prefira Serena para navegação e edição semântica localizada.
---

# CodeGraph CLI

Use diretamente o comando `codegraph`.

Repositório:
`.`

Execute os comandos a partir da raiz do repositório atual.

## Regra principal

Não use CodeGraph através de MCP ou mcporter.

Se o CodeGraph MCP falhar, não tente reparar transporte, servidor ou configuração. Use a CLI equivalente.

## Localizar símbolos

`codegraph symbols "NOME" --root . --limit 20 --json`

## Busca ampla

`codegraph search "CONSULTA" --root . --json`

Para reduzir contexto, quando aplicável use:

`--no-snippets`

## Callers

`codegraph callers "SIMBOLO_OU_HANDLE" --root . --depth 2 --limit 50 --json`

## Callees

`codegraph callees "SIMBOLO_OU_HANDLE" --root . --depth 2 --limit 50 --json`

## Dependências de arquivo ou símbolo

`codegraph deps "ALVO" --root . --depth 2 --json`

## Dependências reversas

`codegraph rdeps "ALVO" --root . --depth 2 --json`

## Impacto da mudança atual

`codegraph impact --root . --json`

Quando necessário, informe explicitamente base e head conforme a ajuda da versão instalada.

## Explicação direcionada

`codegraph explain "ALVO" --root . --json`

## Revisão

Use `codegraph review` quando a tarefa envolver revisão ampla de alterações.

## Economia de contexto

- comece com `symbols`, `search`, `deps`, `rdeps`, `callers` ou `callees`;
- prefira `--json` para saída estruturada;
- use `--no-snippets` quando precisar apenas de handles e caminhos;
- não rode `codegraph index --json` para tarefas comuns;
- não leia arquivos inteiros se relações do grafo forem suficientes.

## CodeGraph x Serena

Use CodeGraph para:
- arquitetura;
- dependências;
- dependências reversas;
- callers/callees;
- impacto;
- análise ampla.

Use Serena para:
- localizar símbolos com precisão;
- membros de classes;
- referências;
- implementações;
- diagnósticos;
- edição semântica localizada.
