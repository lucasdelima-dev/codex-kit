---
name: serena-cli
description: Use o Serena através do mcporter para inteligência semântica sobre o código do repositório atual. Use para localizar classes, métodos e símbolos, inspecionar árvores rasas de símbolos, encontrar referências ou implementações, obter diagnósticos e realizar alterações semânticas localizadas. Prefira Serena a ler arquivos inteiros quando estiver trabalhando com símbolos conhecidos do código.
---

# Serena CLI

Use o Serena através do `mcporter`.

Repositório:

`.`

## Regras principais

- Prefira busca semântica em vez de ler arquivos inteiros.
- Para classes, métodos e símbolos conhecidos, comece com `find_symbol`.
- Mantenha `include_body=false` quando o corpo da implementação não for necessário.
- Use `depth=1` quando quiser apenas os filhos imediatos de uma classe.
- Recupere contexto progressivamente, somente conforme necessário.
- Evite despejar grandes quantidades de código no contexto.
- Use CodeGraph quando a necessidade principal for arquitetura, dependências, impacto ou relações amplas no repositório.

## Padrão de chamada

Use:

`mcporter call serena.<tool> --args '<json>' --output text`

## Localizar símbolo

Para localizar uma classe, método ou outro símbolo, use:

`serena.find_symbol`

Exemplo conceitual:

`mcporter call serena.find_symbol --args '<json>' --output text`

Sempre que possível:

- informe `relative_path` se o arquivo já for conhecido;
- use `depth=1` para estrutura rasa;
- use `include_body=false` inicialmente;
- limite a resposta com `max_answer_chars`.

## Outras operações

Para visão geral dos símbolos de um arquivo:

`serena.get_symbols_overview`

Para referências:

`serena.find_referencing_symbols`

Para implementações:

`serena.find_implementations`

Para diagnósticos:

`serena.get_diagnostics_for_file`

Para renomeação semântica:

`serena.rename_symbol`

## Descoberta de ferramentas

Não execute rotineiramente:

`mcporter list serena --brief`

Esse comando lista todas as ferramentas do Serena e gera saída desnecessária.

Quando precisar de uma operação menos comum, consulte somente o schema da ferramenta necessária:

`mcporter list serena.<tool> --schema`

## Serena x CodeGraph

Use Serena principalmente para:

- localizar símbolos;
- navegar por classes e métodos;
- encontrar referências;
- encontrar implementações;
- diagnósticos;
- alterações semânticas localizadas.

Use CodeGraph principalmente para:

- arquitetura;
- dependências;
- callers e callees;
- impacto de alterações;
- caminhos entre componentes;
- análise ampla do repositório.

## Segurança operacional

Se o Serena falhar por permissão, timeout ou inicialização:

- não altere `SERENA_HOME`;
- não edite `~/.serena/serena_config.yml`;
- não altere configurações globais do Serena;
- não crie configuração alternativa em `/tmp`;
- solicite a permissão necessária ou reporte a falha;
- não use fallback textual amplo silenciosamente se a tarefa pediu explicitamente Serena.
