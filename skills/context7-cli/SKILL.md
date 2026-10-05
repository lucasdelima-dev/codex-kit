---
name: context7-cli
description: Use o Context7 CLI somente para consultar documentação pública atualizada de bibliotecas, frameworks e ferramentas externas. Nunca envie código, nomes internos, regras de negócio ou informações do repositório atual ao Context7.
---

# Context7 CLI

Use diretamente o comando `ctx7`.

## Finalidade

Context7 serve exclusivamente para consultar documentação pública externa, por exemplo:

- PHP;
- Slim;
- Doctrine;
- Vue;
- Quasar;
- JavaScript;
- TypeScript;
- Docker;
- Redis;
- bibliotecas e frameworks públicos.

## Segurança

Context7 é um serviço externo.

Nunca envie ao Context7:

- código do repositório atual;
- trechos de arquivos internos;
- nomes de classes ou métodos internos;
- nomes de módulos internos;
- regras de negócio;
- URLs internas;
- endereços IP internos;
- nomes de servidores;
- credenciais;
- tokens;
- payloads reais;
- dados de banco;
- informações internas ou confidenciais;
- detalhes que permitam reconstruir arquitetura interna.

Quando a dúvida vier do código interno, converta-a para uma pergunta genérica sobre a tecnologia pública.

Exemplo:

Não usar:
`Como implementar computed properties no Vue 3?`

Preferir:
`Doctrine ORM transaction rollback best practices`

## Resolver biblioteca

Use:

`ctx7 library NOME "PERGUNTA PÚBLICA"`

Exemplo:

`ctx7 library vue "computed properties"`

O resultado fornece o library ID apropriado.

## Consultar documentação

Use:

`ctx7 docs LIBRARY_ID "PERGUNTA PÚBLICA"`

Exemplo conceitual:

`ctx7 docs /vuejs/docs "computed properties"`

## Fluxo recomendado

1. identificar qual biblioteca pública está envolvida;
2. formular uma consulta sem informações internas;
3. usar `ctx7 library`;
4. usar `ctx7 docs` com o ID retornado;
5. aplicar localmente o conhecimento obtido.

## Proibições

Não execute automaticamente:

- `ctx7 setup`;
- `ctx7 remove`;
- `ctx7 login`;
- `ctx7 logout`;
- alteração de `--base-url`.

Não configure MCP.

Não altere `AGENTS.md`.

Se autenticação for necessária, informe ao usuário e pare antes de executar `ctx7 login`.

## Economia de contexto

Faça perguntas específicas.

Prefira uma consulta curta e direcionada a buscar documentação excessivamente ampla.
