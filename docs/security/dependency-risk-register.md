# Registro de Riscos de Dependências de Terceiros

- **Data da avaliação inicial:** 14/10/2026
- **Reavaliação preliminar:** 15/10/2026
- **Revalidação para a release:** 15/10/2026
- **Commit de referência:** `e4862e5`
- **Situação:** Riscos conhecidos em acompanhamento.

## 1. Objetivo

Este documento registra vulnerabilidades conhecidas em dependências
utilizadas pelo Codex Kit, suas possíveis consequências, evidências
encontradas e medidas de mitigação.

O objetivo é manter transparência sobre riscos de segurança sem
comprometer a estabilidade e a compatibilidade multiplataforma.

## 2. Metodologia

A avaliação utilizou:

- Auditoria npm com resolução temporária de dependências.
- Inspeção da árvore de dependências instalada no Ubuntu x64.
- Análise estática do código das ferramentas afetadas.
- Consulta aos avisos de segurança publicados pelos mantenedores.
- Resultados dos testes automatizados em Ubuntu, macOS e Windows.

A auditoria inicial identificou 12 pacotes sinalizados,
associados a duas vulnerabilidades distintas.

A presença de uma dependência vulnerável não comprova, isoladamente,
a possibilidade de exploração através do Codex Kit.

## 3. RISCO-001 — Negação de serviço no braces

- **Identificador:** GHSA-vfj7-8cjw-p6xm
- **Severidade:** Alta
- **Dependência afetada:** `braces@3.0.3`
- **Situação:** Aberto — aguardando correção upstream.

### Ferramentas afetadas

- OpenSpec 1.13.0
- CodeGraph 2.3.27 (configuração inicial; substituído no manifesto candidato)
- Repomix 1.18.1

### Evidências identificadas

O OpenSpec utiliza `fast-glob` na resolução de caminhos
de artefatos.

O CodeGraph 2.3.27 utilizava `fast-glob` na descoberta
de arquivos e espaços de trabalho. Na versão 3.0.0,
o projeto declara a substituição por `tinyglobby`,
eliminando essa cadeia de dependências de produção.

O Repomix utiliza `globby` e aceita padrões de inclusão e
exclusão por meio de ferramentas MCP.

O tratamento de padrões do Repomix preserva a sintaxe de
chaves `{}`, sem impor um limite específico de aninhamento
na interface analisada.

### Impacto potencial

Um padrão de busca não confiável, com aninhamento excessivo
de chaves, pode provocar esgotamento da pilha de execução
e interrupção do processo Node.js.

### Avaliação de exposição

Foi identificado um caminho plausível de entrada pelo MCP
do Repomix.

A exploração completa através da integração do Codex Kit
não foi demonstrada.

A origem e a validação dos padrões utilizados pelo OpenSpec
ainda podem exigir investigação adicional.

### Medidas preventivas

- Evitar padrões glob provenientes de fontes não confiáveis.
- Não utilizar expressões com aninhamento excessivo de chaves.
- Não expor essas ferramentas como serviços públicos sem
  autenticação e controles adicionais.
- Não considerar o isolamento de caminhos suficiente para
  impedir ataques de negação de serviço.

### Critério de resolução

- Disponibilização de correção upstream compatível.
- Atualização e validação da dependência afetada.
- Execução dos testes de regressão multiplataforma.
- Nova auditoria de vulnerabilidades.

## 4. RISCO-002 — Negação de serviço no sprintf-js

- **Identificador:** GHSA-hp3w-g68c-fv3c
- **Severidade:** Moderada
- **Dependência afetada:** `sprintf-js@1.1.3`
- **Situação:** Aberto — aguardando correção upstream.

### Cadeia de dependências

DBHub 1.4.0
→ mssql 11.0.2
→ tedious 18.6.2
→ sprintf-js 1.1.3

### Evidências identificadas

O conector SQL Server do DBHub utiliza `mssql`.

O driver `tedious` importa `sprintf-js` em módulos relacionados
à comunicação com o banco de dados.

Nas chamadas analisadas, os formatos utilizados pelo `sprintf`
são definidos diretamente pelo código do driver.

### Impacto potencial

Uma string de formatação não confiável, contendo especificadores
de precisão excessivos, pode provocar uma exceção não tratada
e interromper o processo.

### Avaliação de exposição

Não foi identificado um caminho direto que permita controlar
a string de formatação nas chamadas examinadas.

O uso do SQL Server, isoladamente, não demonstra a possibilidade
de exploração.

A ausência de um caminho comprovado não equivale à eliminação
da vulnerabilidade.

### Medidas preventivas

- Manter o DBHub habilitado somente por projeto.
- Utilizar transporte `stdio`.
- Preferir credenciais de banco de dados somente leitura.
- Aplicar o princípio do menor privilégio.
- Evitar expor o DBHub diretamente a clientes externos
  não confiáveis.

### Critério de resolução

- Correção upstream disponível.
- Atualização compatível da cadeia de dependências.
- Reavaliação do conector SQL Server.
- Testes funcionais e de segurança aprovados.

## 5. Vulnerabilidade corrigida — pnpm

- **Versão anterior:** `10.33.2`
- **Versão atual:** `10.34.7`
- **Situação:** Resolvido para os avisos identificados na auditoria.

Foram identificados 18 avisos de segurança associados
à versão anterior do pnpm.

Após a atualização, a auditoria isolada da versão 10.34.7
não identificou vulnerabilidades conhecidas.

Os testes CI e Bootstrap Smoke passaram em:

- Ubuntu
- macOS
- Windows

A atualização também foi validada no ambiente local.

## 6. Reavaliação preliminar — 15/10/2026

A comparação utilizou resoluções temporárias de dependências,
sem instalação de executáveis e sem alteração do ambiente global.

| Cenário | Altas | Moderadas | Total |
|---|---:|---:|---:|
| Versões inicialmente fixadas | 8 | 4 | 12 |
| OpenSpec 1.14.1 | 8 | 4 | 12 |
| CodeGraph 3.0.0 | 6 | 4 | 10 |
| DBHub 1.5.0 | 8 | 4 | 12 |
| Três atualizações combinadas | 6 | 4 | 10 |

Nenhum cenário apresentou vulnerabilidades críticas.

### Atualização candidata: CodeGraph 3.0.0

A atualização isolada do CodeGraph reduziu de 12 para 10
o número de pacotes sinalizados pela auditoria npm.

A remoção da cadeia vulnerável no CodeGraph não elimina
a vulnerabilidade de `braces` das demais ferramentas.

Os avisos de `braces` e `sprintf-js` continuam presentes
na resolução de dependências candidata.

Não foram identificados benefícios de segurança adicionais
na comparação isolada de OpenSpec 1.14.1 e DBHub 1.5.0.
A versão fixada do pnpm permanece em 10.34.7.

### Evidências funcionais

No Ubuntu Linux x64, uma instalação temporária do
CodeGraph 3.0.0 passou nas seguintes verificações:

- Inicialização do runtime nativo.
- Análise semântica de uma fixture TypeScript.
- Handshake MCP usando protocolo 2025-06-18.
- Descoberta de ferramentas pelo método `tools/list`.
- Busca semântica via `tools/call`.

O teste de regressão permanente foi preparado para execução
no Bootstrap Smoke de Ubuntu, macOS e Windows.

Na data da reavaliação preliminar, esses testes
multiplataforma ainda não haviam sido executados.

### Riscos residuais e decisão

Os riscos RISCO-001 e RISCO-002 permanecem abertos.

A redução numérica de alertas não equivale à eliminação
das vulnerabilidades conhecidas nem comprova ausência
de caminhos exploráveis.

Na avaliação preliminar, a adoção do CodeGraph 3.0.0
estava condicionada à aprovação dos testes multiplataforma
e à revisão do Pull Request.

Antes da publicação da v1.0.0, deve ser reexecutada
a auditoria com o manifesto final e registrada qualquer
mudança nos riscos residuais.

## 7. Revalidação para a release v1.0.0 — 15/10/2026

### Escopo da auditoria final

A auditoria utilizou o manifesto integrado à `main`,
com 12 pacotes npm de versões fixadas, incluindo
`@lzehrung/codegraph@3.0.0`.

A resolução ocorreu em diretório temporário, utilizando
`npm install --package-lock-only --ignore-scripts`,
seguido de `npm audit --json`.

Não houve instalação global nem modificação do repositório.

A auditoria abrange os pacotes npm selecionados do manifesto.
Não constitui uma análise exaustiva das demais dependências,
ferramentas ou superfícies de ataque do Codex Kit.

### Resultado

| Severidade | Pacotes sinalizados |
|---|---:|
| Crítica | 0 |
| Alta | 6 |
| Moderada | 4 |
| Baixa | 0 |
| **Total** | **10** |

Os 10 pacotes sinalizados estão associados aos avisos:

- `GHSA-vfj7-8cjw-p6xm` — `braces`; severidade alta.
- `GHSA-hp3w-g68c-fv3c` — `sprintf-js`; severidade moderada.

Os avisos continuam relevantes para as cadeias de dependências
documentadas em RISCO-001 e RISCO-002.

A redução de 12 para 10 representa menos pacotes sinalizados,
não a eliminação dessas vulnerabilidades.

### Evidências funcionais e multiplataforma

A atualização do CodeGraph 3.0.0 foi integrada pelo
[Pull Request #1](https://github.com/lucasdelima-dev/codex-kit/pull/1).

Foram aprovadas as seguintes execuções:

- [CI do PR](https://github.com/lucasdelima-dev/codex-kit/actions/runs/38774090672):
  Ubuntu, macOS e Windows.
- [Bootstrap Smoke](https://github.com/lucasdelima-dev/codex-kit/actions/runs/38774406067):
  Ubuntu, macOS e Windows, incluindo o teste MCP nativo.
- [CI pós-merge](https://github.com/lucasdelima-dev/codex-kit/actions/runs/38779614011):
  aprovado na `main`.
- [DBHub Windows pós-merge](https://github.com/lucasdelima-dev/codex-kit/actions/runs/38779614201):
  aprovado na `main`.

O Bootstrap Smoke confirmou a instalação, a inicialização
do runtime nativo e a execução do teste MCP permanente nas
três plataformas.

O instalador também foi ajustado para utilizar Python 3.12
nas ferramentas gerenciadas pelo `uv`.

### Riscos residuais e decisão de publicação

RISCO-001 e RISCO-002 permanecem **abertos**.

As medidas preventivas descritas nas respectivas seções
continuam aplicáveis. A aprovação de testes funcionais
não comprova a ausência de exploração possível.

A publicação da v1.0.0 pode ser considerada somente mediante
aceitação explícita dos riscos residuais pelo responsável
pela release, registrada na aprovação do Pull Request
de preparação da versão.

A aceitação não altera a classificação dos avisos nem
substitui futuras atualizações de segurança.

As notas de lançamento devem mencionar os dois avisos
e referenciar este registro.

---

## 8. Critérios de segurança para a v1.0.0

Antes da publicação da primeira versão estável:

1. Reexecutar a auditoria npm utilizando o manifesto final.
2. Verificar novamente os avisos de segurança pendentes.
3. Reavaliar a exposição em caso de alterações nas dependências.
4. Documentar os riscos residuais nas notas de lançamento.
5. Confirmar a aprovação dos testes multiplataforma.
6. Não suprimir alertas sem justificativa técnica documentada.

## 9. Acompanhamento

Os riscos permanecerão documentados até que existam evidências
suficientes para considerá-los corrigidos ou não aplicáveis.

A aprovação dos testes automatizados não constitui garantia
de ausência de vulnerabilidades.

Este documento representa a avaliação realizada na data
indicada e deverá ser atualizado conforme novas evidências.
