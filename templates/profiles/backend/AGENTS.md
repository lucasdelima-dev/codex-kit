# Perfil Backend

Perfil focado em domínio, APIs, persistência, integrações, contratos e testes.

## Ferramentas principais
- Serena e CodeGraph para navegação e impacto.
- Context7 para documentação externa.
- Beads para execução e dependências.
- Repomix para contexto multi-arquivo controlado.
- Semgrep para análise estrutural e segurança.
- DBHub somente quando configurado pelo projeto; readonly por padrão.
- RTK e OpenSpec disponíveis.

## Regras
- Quando houver OpenSpec, ele é a fonte de verdade para requisitos, decisões e escopo.
- Priorize regras de negócio, contratos, persistência e testes.
- Não altere frontend sem impacto técnico comprovado.
- DBHub nunca deve assumir banco, container ou credenciais globalmente.
- Evite refatorações não solicitadas.
