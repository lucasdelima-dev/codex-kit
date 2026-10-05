---
name: dbhub-cli
description: Explora e consulta bancos relacionais locais via DBHub e mcporter, usando descoberta progressiva e execução somente leitura.
---

# DBHub via mcporter

Use o servidor `dbhub` através do `mcporter`.

## Fluxo

1. Quando o schema não for conhecido, use `search_objects` antes de escrever SQL.
2. Comece com `detail_level="names"`.
3. Use `summary` para reduzir candidatos.
4. Use `full` apenas nas tabelas necessárias.
5. Execute consultas SQL somente depois de confirmar tabelas e colunas.

## Segurança — perfil Intraer

- O banco autorizado é definido pela configuração local de cada projeto; nunca assuma um nome global.
- Não desative nem contorne `readonly`.
- Não execute INSERT, UPDATE, DELETE ou DDL.
- Não exponha DSN, usuário ou senha.
- Não grave credenciais em Skills, AGENTS.md, OpenSpec ou no repositório.
- Não faça dumps amplos do banco.
- Prefira consultas pequenas e específicas.
- Use `search_objects` com divulgação progressiva para economizar tokens.
