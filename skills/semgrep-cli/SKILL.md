---
name: semgrep-cli
description: Use o Semgrep Community Edition localmente no repositório atual para análise estática direcionada de bugs, padrões inseguros e violações estruturais. Nunca envie código ou resultados para serviços externos.
---

# Semgrep CLI

Use diretamente:

`semgrep scan`

no repositório:

`.`

## Finalidade

Use Semgrep para:

- detectar padrões inseguros;
- procurar variantes de bugs;
- verificar práticas específicas;
- validar padrões estruturais;
- executar regras locais de segurança.

## Segurança

Toda execução deve usar:

`--metrics=off`

Nunca use:

- `--config auto`;
- configurações do Semgrep Registry;
- `semgrep login`;
- `semgrep ci`;
- Semgrep AppSec Platform;
- upload de findings;
- autenticação Semgrep;
- regras que façam validação HTTP externa.

Use somente:

- regras locais;
- arquivos locais de configuração;
- padrões inline.

Não envie código, findings, nomes internos ou metadados do repositório atual para serviços externos.

## Escopo

Nunca faça scan do repositório inteiro por padrão.

Comece pelo menor:

1. arquivo;
2. diretório;
3. módulo;

necessário para responder à tarefa.

## Saída

Prefira:

`--json`

quando a saída estruturada facilitar a análise.

## Padrão inline

Para uma busca simples:

`semgrep scan --metrics=off --lang LINGUAGEM --pattern 'PADRÃO' --json ALVO`

## Regras locais

Quando houver arquivo local de regras:

`semgrep scan --metrics=off --config CAMINHO_LOCAL --json ALVO`

O `--config` deve apontar para arquivo ou diretório local.

## Divisão de responsabilidade

Serena:
- símbolos;
- referências;
- implementação localizada.

CodeGraph:
- dependências;
- arquitetura;
- impacto.

Repomix:
- agregação de contexto.

Semgrep:
- padrões estáticos;
- bugs;
- segurança;
- violações estruturais.

## Regra de economia

Não use Semgrep para navegação geral do código.

Use-o quando houver uma hipótese, padrão ou classe de problema que possa ser expressa como análise estática.

## Regras de padrões por linguagem

Para PHP, mantenha sintaxe PHP válida no padrão.

Exemplo válido para localizar lançamentos de exceção:

`semgrep scan --metrics=off --lang php --pattern 'throw new $E(...);' --json ALVO`

Se uma regra específica da linguagem falhar no parse:

- corrija primeiro a sintaxe da regra;
- não troque silenciosamente para `--lang generic`;
- só use `generic` quando análise textual for realmente a intenção;
- não apresente resultado `generic` como equivalente a análise semântica da linguagem.
