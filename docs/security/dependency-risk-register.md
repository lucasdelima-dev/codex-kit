# Registro de Riscos de Dependências de Terceiros

- **Data da avaliação:** 14/10/2026
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

A auditoria identificou 12 pacotes sinalizados, associados a
duas vulnerabilidades distintas.

A presença de uma dependência vulnerável não comprova, isoladamente,
a possibilidade de exploração através do Codex Kit.

## 3. RISCO-001 — Negação de serviço no braces

- **Identificador:** GHSA-vfj7-8cjw-p6xm
- **Severidade:** Alta
- **Dependência afetada:** `braces@3.0.3`
- **Situação:** Aberto — aguardando correção upstream.

### Ferramentas afetadas

- OpenSpec 1.13.0
- Codegraph 2.3.27
- Repomix 1.18.1

### Evidências identificadas

O OpenSpec utiliza `fast-glob` na resolução de caminhos
de artefatos.

O Codegraph utiliza `fast-glob` na descoberta de arquivos
e espaços de trabalho.

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
e pelo Codegraph ainda podem exigir investigação adicional.

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

## 6. Critérios de segurança para a v1.0.0

Antes da publicação da primeira versão estável:

1. Reexecutar a auditoria npm utilizando o manifesto final.
2. Verificar novamente os avisos de segurança pendentes.
3. Reavaliar a exposição em caso de alterações nas dependências.
4. Documentar os riscos residuais nas notas de lançamento.
5. Confirmar a aprovação dos testes multiplataforma.
6. Não suprimir alertas sem justificativa técnica documentada.

## 7. Acompanhamento

Os riscos permanecerão documentados até que existam evidências
suficientes para considerá-los corrigidos ou não aplicáveis.

A aprovação dos testes automatizados não constitui garantia
de ausência de vulnerabilidades.

Este documento representa a avaliação realizada na data
indicada e deverá ser atualizado conforme novas evidências.
