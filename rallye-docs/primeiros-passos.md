# Rallye — Primeiros Passos

Guia de setup inicial antes de escrever a primeira linha de código do app.

---

## 1. Criação do projeto no GitHub

- Criar repositório privado: `rallye` — descrição: "App mobile para controle de aulas entre professor e aluno de esportes de raquete"
- Inicializar com `README.md` e `.gitignore` para Flutter
- Criar branch `main` como branch protegida — nenhum push direto, apenas via PR
- Configurar regra de proteção: PR só pode ser mergeado com CI verde

**Estrutura inicial de branches:**
```
main        — produção, sempre estável
dev         — desenvolvimento, base para PRs
```

**Adicionar os arquivos de documentação na raiz do repo:**
```
CLAUDE.md
docs/
  rallye-brief.md
  guidelines.md
  mocks.html
```

---

## 2. Configuração do CI/CD (GitHub Actions)

Configurar antes de qualquer feature. O CI é a fundação que permite TDD com confiança.

### Flutter workflow

Criar `.github/workflows/flutter.yml`:

```yaml
name: Flutter CI

on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main, dev]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
      - run: flutter pub get
      - run: dart format --check .
      - run: flutter analyze
      - run: flutter test
```

### Edge Functions workflow

Criar `.github/workflows/edge-functions.yml`:

```yaml
name: Edge Functions CI

on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main, dev]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: denoland/setup-deno@v1
      - run: deno lint supabase/functions/
      - run: deno test supabase/functions/

  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
      - run: supabase functions deploy
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
          SUPABASE_PROJECT_ID: ${{ secrets.SUPABASE_PROJECT_ID }}
```

### Abertura de issue em falha

Adicionar step ao final de ambos os workflows (substitui notificação Discord):

```yaml
      - name: Open issue on failure
        if: failure()
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `CI failure: ${context.workflow} — ${context.sha.slice(0, 7)}`,
              body: `**Workflow:** ${context.workflow}\n**Branch:** ${context.ref}\n**Run:** ${context.serverUrl}/${context.repo.owner}/${context.repo.repo}/actions/runs/${context.runId}\n**Commit:** ${context.payload.head_commit?.message ?? '—'}`,
              labels: ['ci-failure']
            })
```

Quando o CI falhar, rodar `/check-issues` no Claude Code — o agente lê as issues com label `ci-failure`, investiga, corrige e fecha a issue após o fix.

**Secrets necessários no GitHub:**
- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_PROJECT_ID`
- `SENTRY_DSN`

---

## 3. Configuração do Sentry

### Criar projeto

1. Acessar [sentry.io](https://sentry.io) e criar novo projeto
2. Selecionar plataforma **Flutter**
3. Copiar o DSN gerado — vai para secrets do GitHub e `.env` local

### Adicionar ao `.env` local

```
SENTRY_DSN=https://xxxx@sentry.io/xxxx
```

### Integração no Flutter

Adicionar `sentry_flutter` ao `pubspec.yaml` (já listado na seção 5.2).

Inicializar no `main.dart` antes de qualquer widget:

```dart
await SentryFlutter.init(
  (options) {
    options.dsn = const String.fromEnvironment('SENTRY_DSN');
    options.tracesSampleRate = 1.0;
  },
  appRunner: () => runApp(const App()),
);
```

### Integração nas Edge Functions

Usar `@sentry/deno` nas Edge Functions. `SENTRY_DSN` adicionado como variável de ambiente no Supabase Dashboard → Settings → Edge Functions.

---

## 4. Criação e configuração do Supabase

### Criar projeto

1. Acessar [supabase.com](https://supabase.com) e criar novo projeto: `rallye`
2. Escolher região mais próxima: **South America (São Paulo)**
3. Guardar a senha do banco em local seguro (não no repositório)

### Configurações iniciais obrigatórias

**Habilitar RLS globalmente:**
- Acessar Database → Tables
- Garantir que RLS está habilitado — nenhuma tabela sobe sem política definida

**Configurar Auth:**
- Habilitar Google OAuth: Authentication → Providers → Google
  - Criar credenciais no Google Cloud Console
  - Adicionar Client ID e Secret no Supabase
- Configurar redirect URLs para desenvolvimento local

**Variáveis de ambiente locais:**

Criar arquivo `.env` na raiz do projeto Flutter (já no `.gitignore`):
```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=xxxx
```

**Adicionar secrets no GitHub:**
```
SUPABASE_ACCESS_TOKEN   — token de acesso à API do Supabase CLI
SUPABASE_PROJECT_ID     — ID do projeto (encontrado nas configurações)
```

### Criar schema inicial

Rodar as migrations na ordem definida no `rallye-brief.md`:

```
1. users
2. teacher_profiles + teacher_clubs + teacher_settings
3. student_profiles + student_clubs
4. relationships
5. slots + slot_requests
6. sessions
7. payments + payment_sessions
8. notifications
```

Cada migration sobe com políticas RLS correspondentes antes de avançar para a próxima tabela.

### Supabase CLI

Instalar localmente para desenvolvimento e deploy de Edge Functions:

```bash
npm install -g supabase
supabase login
supabase link --project-ref <PROJECT_ID>
```

---

## 5. Início do desenvolvimento

Com infraestrutura pronta, o desenvolvimento começa nessa ordem:

### 5.1 Criar projeto Flutter

```bash
flutter create rallye
cd rallye
```

Organizar estrutura de pastas conforme definido no `CLAUDE.md` antes de qualquer código.

### 5.2 Configurar dependências iniciais

Adicionar ao `pubspec.yaml`:
```yaml
dependencies:
  supabase_flutter: ^2.x
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  fpdart: ^1.x
  sentry_flutter: ^8.x
  phosphor_flutter: ^2.x
  google_fonts: ^6.x        # Space Grotesk + Outfit
  go_router: ^13.x

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.x
  riverpod_generator: ^2.x
  build_runner: ^2.x
  mocktail: ^1.x
```

### 5.3 Configurar linter e formatação

**Flutter — criar `analysis_options.yaml` na raiz:**

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - avoid_print
    - prefer_const_constructors
    - prefer_const_declarations
    - sort_child_properties_last
```

**Edge Functions — criar `supabase/functions/deno.json`:**

```json
{
  "lint": {
    "rules": {
      "tags": ["recommended"],
      "include": ["no-unused-vars", "ban-ts-comment"]
    }
  },
  "fmt": {
    "useTabs": false,
    "lineWidth": 100,
    "indentWidth": 2,
    "singleQuote": true
  },
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true
  }
}
```

> `any` é proibido no TypeScript. `noImplicitAny: true` e `ban-ts-comment` garantem isso no CI automaticamente. Se o TypeScript não consegue inferir o tipo, o problema é discutido antes de prosseguir.

### 5.4 Configurar tema e tokens

Primeiro arquivo de código: `lib/core/theme/` com todos os tokens de cor e tipografia definidos no `guidelines.md`. Nenhum widget é criado antes disso existir.

### 5.4 Ordem de desenvolvimento sugerida

```
1. Auth (login Google, seleção de perfil)
2. Estrutura de navegação (navbar, rotas)
3. Home professor + Home aluno
4. Agenda (calendário + slots)
5. Detalhe do slot + fila de espera
6. Extrato
7. Perfil + Configurações
8. Edge Functions (notificações push, extrato calculado)
```

Cada item dessa lista só começa quando o anterior tem testes passando no CI.

---

## Checklist de validação antes de começar a desenvolver

- [ ] Repositório criado e branch `main` protegida
- [ ] GitHub Actions rodando (mesmo sem código Flutter, o workflow deve existir)
- [ ] Step de abertura de issue em falha configurado nos dois workflows
- [ ] Label `ci-failure` criada no repositório GitHub
- [ ] Sentry criado e DSN adicionado aos secrets do GitHub e `.env` local
- [ ] Supabase criado com Auth configurado e RLS habilitado globalmente
- [ ] Secrets configurados no GitHub (`SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_ID`, `SENTRY_DSN`)
- [ ] `.env` local criado e no `.gitignore`
- [ ] `CLAUDE.md` e `docs/` commitados na raiz do repositório
- [ ] Estrutura de pastas Flutter criada antes do primeiro widget
