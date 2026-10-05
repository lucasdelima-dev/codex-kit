

## Política local: OpenSpec + Superpowers

Em projetos internos que utilizem OpenSpec, OpenSpec é a fonte de verdade para requisitos, escopo e tasks de uma change existente.

Regras:
- Não substituir uma change OpenSpec por um plano alternativo.
- Não usar brainstorming ou writing-plans para redesenhar uma change já especificada, salvo pedido explícito.
- executing-plans pode executar as tasks definidas pelo OpenSpec.
- systematic-debugging pode ser usado livremente para diagnóstico.
- test-driven-development pode ser usado quando adequado à implementação.
- verification-before-completion deve ser preferido antes de declarar uma tarefa concluída.
- requesting-code-review e receiving-code-review podem complementar a validação.
- Não criar git worktrees automaticamente; somente quando solicitado ou claramente necessário.
- dispatching-parallel-agents e subagent-driven-development devem ser usados apenas quando trouxerem ganho real e com escopo bem delimitado.
- Evitar trabalho adicional, refatorações oportunistas e funcionalidades fora do escopo especificado.


## Política local: serviços externos e connectors

Este perfil é destinado a projetos internos ou restritos.

Não use automaticamente connectors, plugins ou serviços externos para processar conteúdo do repositório.

Isso inclui, entre outros:
- GitHub;
- Notion;
- Vercel;
- Canva;
- Sites;
- serviços externos de análise ou armazenamento.

Não envie código, arquivos, diffs, arquitetura, regras de negócio, nomes internos ou dados do projeto para esses serviços.

Connectors externos só podem ser usados quando o usuário solicitar explicitamente.

Context7 é a única exceção automática e deve ser usado exclusivamente para documentação pública de bibliotecas, frameworks e ferramentas, sem enviar contexto interno do projeto.

Prefira sempre ferramentas locais:
- Serena;
- CodeGraph;
- Beads;
- Repomix;
- Semgrep;
- RTK;
- OpenSpec.
