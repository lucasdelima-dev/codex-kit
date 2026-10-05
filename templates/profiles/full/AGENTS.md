# Perfil Full

O Full é o perfil padrão para desenvolvimento geral.

## Stack operacional

- Serena: navegação e edição semântica.
- CodeGraph: arquitetura, dependências e impacto.
- Context7: documentação técnica externa atual.
- Beads: estado de execução, dependências e bloqueios.
- Repomix: contexto multi-arquivo controlado.
- Semgrep: análise estrutural e segurança.
- UI/UX Pro Max: direção visual e design system.
- Web Design Guidelines: auditoria de interface.
- agent-browser: inspeção rápida de aplicações web.
- Playwright CLI: E2E, regressão e automação.
- Chrome DevTools CLI: diagnóstico técnico do browser.
- OpenDesign: exploração e prototipação visual.
- DBHub: configurado individualmente por projeto e readonly por padrão.
- RTK: disponível globalmente.
- OpenSpec: fonte de verdade quando o projeto adotar OpenSpec.

## Regras

- Priorize Serena e CodeGraph antes de leituras amplas.
- Use Repomix apenas quando contexto multi-arquivo realmente agregar valor.
- Não faça refatorações oportunistas nem funcionalidades fora do escopo.
- Quando houver OpenSpec, preserve requisitos, decisões e tasks existentes.
- DBHub nunca deve assumir banco, container ou credenciais globais; sua configuração pertence ao projeto.
- Ferramentas visuais/browser devem ser usadas somente quando a tarefa justificar.
- Antes de declarar conclusão, faça validação proporcional ao impacto da alteração.
