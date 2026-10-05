# Codex Kit

Ambiente portátil, reproduzível e orientado a perfis para configurar e usar
OpenAI Codex com um conjunto integrado de ferramentas de desenvolvimento.

O Codex Kit automatiza a preparação de uma máquina para trabalhar com agentes
de desenvolvimento sem precisar instalar, configurar e integrar manualmente
cada ferramenta em cada computador ou projeto.

Ele centraliza:

- versões pinadas das ferramentas;
- instalação automatizada;
- oito perfis especializados de Codex;
- Skills compartilhadas;
- isolamento entre projetos;
- configurações específicas por projeto;
- wrappers de execução;
- diagnóstico do ambiente;
- suporte a Linux, macOS e Windows.

> Codex Kit é um projeto independente e não é afiliado, patrocinado ou
> mantido pela OpenAI.

---

## Para que serve?

Ao combinar o Codex com várias ferramentas de desenvolvimento, é comum o
ambiente acumular configurações globais, versões diferentes, caminhos
específicos da máquina e integrações que funcionam apenas em um projeto.

O Codex Kit organiza essas responsabilidades em três camadas:

```text
Máquina
   ↓
Perfil Codex
   ↓
Projeto
```

### Máquina

Instala e prepara ferramentas compartilhadas, versões, wrappers e Skills.

### Perfil

Define quais ferramentas e Skills ficam disponíveis para cada tipo de
tarefa, como backend, frontend, pesquisa ou segurança.

### Projeto

Mantém configurações e estado específicos do repositório sem contaminar os
demais projetos da máquina.

---

## Principais recursos

- instalação reproduzível por bootstrap;
- versões de ferramentas centralizadas em manifesto;
- oito ambientes `CODEX_HOME` independentes;
- perfil `full` como padrão;
- perfil `intraer` com política mais restritiva;
- Serena e CodeGraph com root dinâmico por projeto;
- DBHub configurado somente nos projetos que precisam dele;
- Beads e OpenSpec inicializados por projeto;
- UI/UX Pro Max materializado em runtime;
- diagnóstico do ambiente com `codex-doctor`;
- bootstraps projetados para serem idempotentes;
- suporte a Linux, macOS e Windows.

---

# Instalação rápida

O fluxo completo é:

```text
1. Clonar o Codex Kit
2. Preparar a máquina
3. Autenticar o Codex
4. Criar os perfis
5. Preparar um projeto
6. Abrir o projeto com codex-code
```

## 1. Clonar o repositório

### Linux / macOS

```bash
git clone https://github.com/lucasdelima-dev/codex-kit.git ~/.codex-kit
cd ~/.codex-kit
```

### Windows PowerShell

```powershell
git clone https://github.com/lucasdelima-dev/codex-kit.git "$HOME\.codex-kit"
Set-Location "$HOME\.codex-kit"
```

> A URL definitiva será adicionada antes da primeira release pública.

## 2. Preparar a máquina

### Linux / macOS

```bash
~/.codex-kit/bin/bootstrap-machine
```

### Windows PowerShell

```powershell
& "$HOME\.codex-kit\bin\bootstrap-machine.ps1"
```

O bootstrap instala ou prepara as ferramentas e versões definidas em:

```text
manifests/tools.env
```

A execução é projetada para ser idempotente. Isso significa que o mesmo
bootstrap pode ser executado novamente para reconciliar o ambiente após uma
atualização do Codex Kit, sem exigir uma reinstalação manual completa.

---

## 3. Autenticar o Codex

A autenticação não é armazenada neste repositório.

Depois que o Codex estiver instalado, autentique-se usando o mecanismo
disponível na sua instalação local.

Em uma instalação padrão do Codex CLI, por exemplo:

```bash
codex login
```

As credenciais permanecem somente na máquina local e nunca devem ser
adicionadas ao Git.

Os perfis reutilizam a autenticação local através de links relativos,
evitando duplicar arquivos de credenciais.

---

## 4. Criar os perfis

### Linux / macOS

```bash
~/.codex-kit/bin/bootstrap-profile all
```

### Windows PowerShell

```powershell
& "$HOME\.codex-kit\bin\bootstrap-profile.ps1" all
```

O comando prepara os oito perfis oficiais:

```text
lean
backend
frontend
research
security
full
experimental
intraer
```

O perfil padrão usado pelo launcher é:

```text
full
```

---

## 5. Preparar um projeto

Depois que a máquina e os perfis estiverem prontos, prepare o repositório
que será usado com o Codex Kit.

### Linux / macOS

```bash
~/.codex-kit/bin/bootstrap-project ~/meu-projeto --standard
```

### Windows PowerShell

```powershell
& "$HOME\.codex-kit\bin\bootstrap-project.ps1" "$HOME\meu-projeto" --standard
```

O modo `--standard` prepara o estado local normalmente usado pelo kit,
incluindo Beads e OpenSpec.

As configurações específicas permanecem associadas ao próprio projeto.

DBHub não é habilitado globalmente. Ele deve ser configurado apenas nos
projetos que realmente precisam acessar um banco.

---

## 6. Abrir o projeto com Codex

Depois dos bootstraps, use o launcher `codex-code`.

Perfil padrão (`full`):

```bash
codex-code ~/meu-projeto
```

Ou, estando dentro do projeto:

```bash
cd ~/meu-projeto
codex-code
```

Para escolher um perfil explicitamente:

```bash
codex-code lean ~/meu-projeto
codex-code backend ~/minha-api
codex-code frontend ~/meu-site
codex-code research ~/meu-projeto
codex-code security ~/meu-projeto
codex-code full ~/meu-projeto
codex-code experimental ~/meu-projeto
codex-code intraer ~/meu-projeto
```

O launcher define automaticamente o `CODEX_HOME` correspondente ao perfil
e o `CODEX_PROJECT_ROOT` correspondente ao projeto aberto.

Isso permite trocar de contexto sem misturar configurações entre perfis ou
entre repositórios diferentes.

---

# Perfis

O Codex Kit oferece oito perfis para diferentes tipos de trabalho:

| Perfil | Uso principal |
|---|---|
| `lean` | alterações rápidas com o mínimo de contexto |
| `backend` | APIs, regras de negócio, banco e integrações |
| `frontend` | UI/UX, desenvolvimento web, testes e browser automation |
| `research` | investigação, documentação e análise ampla |
| `security` | revisão de segurança e análise estática |
| `full` | desenvolvimento ponta a ponta; perfil padrão |
| `experimental` | teste de ferramentas antes de adoção nos perfis estáveis |
| `intraer` | execução mais restritiva e menor exposição a serviços externos |

Cada perfil possui seu próprio `CODEX_HOME` em:

```text
~/.codex-profiles/<perfil>
```

As Skills compartilhadas ficam em:

```text
~/.codex-shared/skills
```

---

# Ferramentas

O kit integra ferramentas como OpenSpec, Superpowers, Beads, RTK, Serena,
CodeGraph, Context7, Repomix, Semgrep, DBHub, Playwright, Chrome DevTools,
OpenDesign e UI/UX Pro Max.

As versões utilizadas ficam centralizadas em `manifests/tools.env`.

---

# Diagnóstico

Para verificar a instalação:

```bash
~/.codex-kit/bin/codex-doctor
```

Um ambiente saudável deve terminar sem falhas (`FAIL: 0`).

---

# Atualização

```bash
cd ~/.codex-kit
git pull
./bin/bootstrap-machine
./bin/bootstrap-profile all
```

Os bootstraps podem ser executados novamente para reconciliar o ambiente.

---

# Segurança

O repositório é público. Credenciais, tokens, chaves privadas, DSNs reais,
dados internos, caminhos pessoais e configurações específicas de projetos
não devem ser versionados.

Configurações sensíveis permanecem locais e configurações específicas devem
pertencer ao próprio projeto.

---

# Licença

O código original do Codex Kit é distribuído sob a licença MIT.

Consulte `LICENSE`, `NOTICE` e `THIRD_PARTY_NOTICES` para detalhes e
atribuições de componentes de terceiros.
