---
name: repomix-cli
description: Use o Repomix localmente para condensar conjuntos específicos de arquivos do repositório atual em contexto estruturado e econômico. Prefira escopo mínimo, compressão e limites explícitos de tokens. Nunca use recursos remotos.
---

# Repomix CLI

Use diretamente o comando `repomix`.

Repositório:

`.`

## Finalidade

Use Repomix quando for útil reunir contexto de vários arquivos relacionados sem lê-los individualmente em sequência.

É especialmente útil para:

- módulos pequenos;
- conjuntos de arquivos relacionados;
- análise de arquitetura localizada;
- preparação de contexto para revisão;
- comparação de implementação entre poucos arquivos.

Não use Repomix quando Serena ou CodeGraph puderem responder com menos contexto.

## Prioridade das ferramentas

Prefira:

1. Serena para símbolos e código localizado;
2. CodeGraph para arquitetura, dependências e impacto;
3. Repomix quando for realmente necessário reunir conteúdo de vários arquivos.

## Padrão seguro

Prefira:

`repomix . --include "PADRÕES" --compress --stdout --token-budget LIMITE`

Use `--style json` quando saída estruturada for útil.

## Seleção de arquivos

Sempre use `--include` ou `--stdin` quando o objetivo estiver restrito a parte do repositório.

Não empacote o repositório atual inteiro por padrão.

Comece pelo menor conjunto de arquivos capaz de responder à tarefa.

## Compressão

Prefira:

`--compress`

quando estruturas, assinaturas, classes, métodos e interfaces forem suficientes.

Não use conteúdo integral se a estrutura comprimida responder à pergunta.

## Limite de contexto

Sempre que possível use:

`--token-budget`

Escolha um limite compatível com a tarefa e aumente apenas se necessário.

## Saída

Prefira:

`--stdout`

para evitar arquivos persistentes desnecessários no repositório.

Não use `--copy`.

Não gere `repomix-output.*` no projeto sem necessidade explícita.

## Segurança

Não execute:

- `--remote`;
- `--remote-branch`;
- `--remote-trust-config`;
- `--mcp`;
- `--skill-generate`;
- `--init`;
- `--global`;
- `--no-security-check`.

Mantenha a verificação de segurança habilitada.

Nunca envie automaticamente a saída do Repomix para serviços externos.

Não inclua deliberadamente:

- arquivos `.env`;
- credenciais;
- tokens;
- chaves;
- dumps de banco;
- arquivos de segredo;
- artefatos de autenticação;
- dados operacionais sensíveis.

## Git e ignores

Respeite os filtros padrão do Repomix.

Não use:

`--no-gitignore`
`--no-dot-ignore`
`--no-default-patterns`

salvo solicitação explícita e justificada.

## Economia de contexto

Antes de usar Repomix, pergunte implicitamente:

"Serena ou CodeGraph conseguem responder com menos contexto?"

Se sim, prefira essas ferramentas.

Se não, use Repomix com o menor `--include` possível.
