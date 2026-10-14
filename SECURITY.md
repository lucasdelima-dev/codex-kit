# Política de Segurança

## Comunicação de vulnerabilidades

Não publique detalhes sensíveis de vulnerabilidades em
issues públicas.

Prefira o recurso de comunicação privada de vulnerabilidades
do GitHub ou um aviso privado de segurança, quando disponíveis
para este repositório.

Ao comunicar uma vulnerabilidade, informe, quando aplicável:

- Componente e versão afetados.
- Etapas necessárias para reproduzir o problema.
- Comportamento observado e comportamento esperado.
- Impacto potencial.
- Possíveis medidas de correção ou mitigação.

Nunca inclua credenciais reais, tokens, informações privadas
de projetos ou dados de produção.

## Escopo

São considerados relevantes os problemas de segurança
relacionados a:

- Scripts de instalação e configuração.
- Wrappers e execução de ferramentas.
- Limites de privilégios e permissões.
- Configurações padrão inseguras.
- Isolamento entre projetos.
- Tratamento e instalação de dependências.
- Exposição de credenciais.
- Operações no sistema de arquivos.

Vulnerabilidades identificadas em ferramentas de terceiros
também devem ser comunicadas aos respectivos mantenedores
quando apropriado.

## Acesso a bancos de dados e DBHub

O DBHub é habilitado somente por projeto e utiliza
transporte `stdio`.

Credenciais de banco de dados nunca devem ser incluídas
em commits.

Utilize uma conta dedicada, com apenas as permissões
necessárias, preferencialmente limitada a consultas.

Não utilize contas administrativas, root, superusuário
ou credenciais privilegiadas de produção com agentes de IA.

O modo somente leitura, os limites de resultados e os
tempos máximos de consulta são medidas adicionais
de proteção.

As permissões configuradas diretamente no banco de dados
continuam sendo a principal barreira de autorização.

## Riscos conhecidos em dependências de terceiros

Consulte o
[Registro de Riscos de Dependências](docs/security/dependency-risk-register.md)
para verificar:

- Vulnerabilidades conhecidas.
- Componentes e versões afetadas.
- Evidências de exposição.
- Medidas preventivas.
- Critérios para resolução.

## Versões com suporte

Até a publicação das versões oficiais, as correções de
segurança são aplicadas à versão mais recente disponível
na branch principal (`main`).
