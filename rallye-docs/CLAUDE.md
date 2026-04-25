# CLAUDE.md — Rallye

Arquivo de contexto do projeto. Leia antes de qualquer ação.

---

## Visão do projeto

App mobile para controle transparente de aulas entre professor e aluno de esportes de raquete (padel, tênis, squash, badminton). O mesmo usuário pode ser professor para alguns e aluno para outros — perfis contextuais dentro de um único app. O problema central é a falta de controle financeiro e histórico de aulas entre professor e aluno, que hoje acontece por WhatsApp e memória.

Público-alvo inicial: professores autônomos de esportes de raquete e seus alunos, no Brasil. O MVP começa com padel como esporte principal, mas a arquitetura suporta qualquer esporte de raquete desde o início — sem hardcode de esporte específico no modelo de dados ou na interface.

Documentação completa: `docs/rallye-brief.md`

---

## Stack

| Camada | Tecnologia |
|---|---|
| Mobile | Flutter |
| Backend / BaaS | Supabase (PostgreSQL) |
| Auth | Supabase Auth — Google OAuth + Sign in with Apple |
| Server-side | Supabase Edge Functions (TypeScript / Deno) |
| Push notifications | FCM / APNs (simulado localmente no início) |
| CI/CD | GitHub Actions (testes, deploy de Edge Functions no Supabase) |
| Monitoramento / Erros | Sentry (Flutter SDK + integração nas Edge Functions) |
| State management | Riverpod (`flutter_riverpod` + `riverpod_annotation`) |
| Error handling | fpdart — `Either<Failure, T>` em toda lógica de negócio |

Não sugira alternativas a essas tecnologias. As decisões estão tomadas.

> **Infraestrutura:** não há VPS ou servidor próprio. O backend roda inteiramente no Supabase — banco gerenciado, Edge Functions na infraestrutura deles. GitHub Actions cuida apenas de testes automáticos e deploy das Edge Functions via Supabase CLI.

> **Ambientes:** projeto de laboratório — único banco Supabase, sem staging separado.

---

## Convenções de código

- **Tudo em inglês:** tabelas, colunas, variáveis, funções, classes, arquivos, rotas, comentários de código
- **Strings de interface em português:** todo texto visível ao usuário é em português brasileiro
- Nomenclatura de arquivos Flutter: `snake_case`
- Nomenclatura de classes Dart: `PascalCase`
- Nomenclatura de variáveis e funções Dart: `camelCase`
- Nomenclatura de tabelas e colunas Postgres: `snake_case`
- Sempre usar `const` em widgets Flutter quando possível
- Separar lógica de negócio da UI — nunca colocar regras de negócio diretamente em widgets

---

## Estrutura de pastas Flutter

```
lib/
  core/
    constants/       # tokens de cor, tipografia, espaçamento
    theme/           # ThemeData do app
    utils/           # helpers e extensões
  data/
    models/          # entidades do domínio
    repositories/    # acesso ao Supabase
    services/        # Edge Functions, push notifications
  features/
    auth/            # login, cadastro, seleção de perfil
    home/            # home professor e home aluno
    agenda/          # calendário e slots
    extrato/         # histórico financeiro
    perfil/          # dados do usuário
    configuracoes/   # settings do professor
    slot_detail/     # detalhe de um slot e fila de espera
  shared/
    widgets/         # componentes reutilizáveis
    navigation/      # rotas e navbar
```

Sempre pergunte antes de criar arquivos fora dessa estrutura.

---

## Design system

Referência completa: `docs/guidelines.md`
Mocks de todas as telas: `docs/mocks.html`

### Regra inegociável
Zero AI slop. Nunca use padrões visuais genéricos — gradientes roxos, fontes Inter/Roboto, grid de 3 cards, botões com border-radius exagerado em azul royal. Cada decisão visual deve ser intencional.

### Fontes

```dart
// Space Grotesk — títulos, valores monetários, horários
// Outfit — corpo, labels, navegação
```

### Tokens de cor principais

```dart
const background  = Color(0xFF1C1A18);
const surface     = Color(0xFF252320);
const surfaceHigh = Color(0xFF2E2C29);
const accent      = Color(0xFFF5C842);
const accentMuted = Color(0xFF3D3115);
const textPrimary    = Color(0xFFF2EFE8);
const textSecondary  = Color(0xFF8C8880);
const textDisabled   = Color(0xFF4A4845);
const success = Color(0xFF4CAF82);
const warning = Color(0xFFE8944A);
const error   = Color(0xFFE05C5C);
```

### Regras visuais críticas

- Texto auxiliar nunca abaixo de `textSecondary (#8C8880)` sobre fundos escuros
- `accent (#F5C842)` em no máximo 20% dos elementos visíveis por tela
- Border accent `3px solid accent` apenas no card com `starts_at` mais próximo do momento atual e status `confirmed`
- Badge de desconto exibido apenas quando `slot.price < teacher.default_price`
- Ícones: Phosphor Icons (`phosphor_flutter`) — `regular` para inativo, `fill` para ativo

---

## Vínculo professor-aluno — fluxo de descoberta

**MVP:** aluno busca professor pelo nome; lista de resultados filtrada por região e por esporte.

**V2:** mapa com clubes cadastrados + professores que atendem em cada clube, filtráveis por esporte. Aluno escolhe a partir da localização.

O schema de `relationships` deve suportar busca por nome, região e esporte desde o MVP para não exigir migração posterior.

---

## Definição de Slot e Session

**Slot** = disponibilidade de horário aberta pelo professor. Pode ser individual ou em grupo (`is_group`, `max_students`).

**Session** = sessão de aula entre 1 aluno e o professor. É a unidade de cobrança.

Regras:
- 1 slot individual confirmado → 1 session gerada
- 1 slot em grupo com N alunos confirmados → N sessions geradas (uma por aluno)
- O professor não gera session para si — session existe para rastrear e cobrar o aluno
- Sessions são geradas individualmente por aluno, nunca como registro coletivo

---

## Fila de espera — fluxo de promoção

Promoção **não é automática**. Fluxo quando uma vaga abre:

1. Professor revisa a fila e aprova manualmente o próximo candidato
2. Aluno promovido recebe notificação push para aceitar ou recusar
3. Se aceitar → `slot_request` muda para `confirmed`, session gerada
4. Se recusar ou não responder → professor pode promover o próximo

`v1-promote-waitlist` cobre os steps 1 e 2. A ação do aluno (aceitar/recusar) dispara endpoint separado.

---

## Pagamento — MVP e roadmap

**MVP:** pagamento manual. Professor marca a session como paga diretamente no app — sem gateway, sem automação.

**Futuro:** integração com Stripe e/ou Mercado Pago.

Para não bloquear a migração futura, a tabela `payments` deve ter desde o início:
```sql
provider      text default 'manual',  -- 'manual' | 'stripe' | 'mercadopago'
external_id   text default null        -- ID da transação no gateway
```

---

## Modelo de dados — entidades principais

Referência completa: `docs/rallye-brief.md`

**Regra:** nenhuma tabela ou coluna referencia esporte específico por nome (sem `is_padel`, sem `padel_level`). Esporte é sempre uma referência à tabela `sports`. Isso garante que tênis, squash e badminton entram sem migração.

```
sports                          # padel, tênis, squash, badminton…

users
  └── teacher_profiles → teacher_clubs, teacher_settings, teacher_sports
  └── student_profiles → student_clubs, student_sports

teacher_profiles ↔ student_profiles → relationships (sport_id obrigatório)

slots → slot_requests (pending/confirmed/rejected/waitlisted/cancelled)
slots + relationships → sessions (1 session por aluno)

sessions → payment_sessions → payments
users → notifications
```

Nunca altere o schema do banco sem confirmar explicitamente com o usuário.

---

## Segurança — regras obrigatórias

- RLS habilitado em todas as tabelas desde o início
- Nenhuma tabela sobe para produção sem política RLS definida
- `service_role key` nunca no código do app, nunca no repositório
- `.env` e `.gitignore` configurados antes do primeiro commit
- Professor acessa apenas seus próprios alunos, slots e sessões
- Aluno acessa apenas o extrato do vínculo com cada professor

---

## Filosofia de trabalho — como usar IA corretamente

> "A IA é seu espelho: revela mais rápido quem você é. Se for incompetente, produz coisas ruins mais rápido. Se for competente, produz coisas boas mais rápido." — Fabio Akita

**O humano decide o quê. O agente decide o como.** Nunca inverta. Quando o desenvolvedor começa a perguntar "o que devo fazer aqui?", o resultado piora dramaticamente.

**O agente nunca diz não.** Se for pedido algo over-engineered, ele implementa com entusiasmo. Se for pedido algo inseguro, ele implementa sem reclamar. O desenvolvedor é o freio, o code review e o adulto na sala. Toda lógica de segurança e financeira passa por revisão explícita antes de ser aceita.

**Código gerado que não é compreendido não é aceito.** Sempre explique o que foi gerado antes de prosseguir. Se o desenvolvedor não consegue explicar linha a linha, o código não entra.

**Documentar toda armadilha imediatamente.** Cada descoberta — comportamento inesperado do Supabase, quirk do Flutter, limitação de uma lib — vai para `## Common Hurdles` no momento em que é descoberta. Não depois. O agente lê esse documento antes de cada sessão e não repete os mesmos erros.

---

## TDD — prioridade máxima

TDD é a regra mais importante deste projeto. É mais importante com IA do que sem ela — o agente modifica código com confiança e quebra coisas silenciosamente quando não há testes. Os testes são a rede de segurança que permite velocidade sustentável.

### Camadas de teste no Flutter

**Unit tests** — obrigatórios, rodam no CI:
- Toda lógica de negócio: repositórios, services, regras de domínio
- Toda transformação de dados: modelos, parsers
- Regras críticas: border accent rule, cálculo de desconto, promoção de fila de espera

**Widget tests** — obrigatórios, rodam no CI:
- Todo widget reutilizável: `SlotCard`, `StatCard`, badges, navbar
- Verificam presença de elementos dado um estado
- Simulam interações básicas: tap, scroll

**Integration tests** — opcionais no CI, obrigatórios localmente antes de PR importante:
- Fluxos completos: agendamento, extrato, configurações
- Rodam no emulador, mais lentos — fora do CI no MVP

### Edge Functions (TypeScript/Deno)

Obrigatório testar toda Edge Function. A infraestrutura não está sob controle direto e falhas silenciosas chegam pelo usuário. Usar `Deno.test` nativo. Cada função cobre:
- Happy path
- Casos de erro esperados
- Validação de inputs

### Regras de TDD

- Nunca aceitar código sem teste correspondente
- Bug fix sempre acompanha teste de regressão que reproduz o bug
- Testes escritos junto com a feature, nunca retroativamente
- Ratio mínimo esperado: ~1.5x linhas de teste para linhas de código

---

## CI/CD — configurar antes da primeira feature

O CI/CD entra no projeto antes de qualquer feature de produto. É a base que permite small releases com confiança.

### Pipeline Flutter (GitHub Actions)

```
1. flutter analyze       — análise estática
2. flutter test          — unit tests + widget tests
3. dart format --check   — formatação
```

Roda em todo commit e todo PR. Nenhum commit quebrado entra na main. Sem exceção.

### Pipeline Edge Functions (GitHub Actions)

```
1. deno lint             — análise estática
2. deno test             — testes das functions
3. supabase functions deploy — deploy automático no merge para main
```

### Feedback do CI para o Claude Code via GitHub Issues

O loop de feedback usa GitHub Issues como destino — sem servidor dedicado, sem bot ativo:

```
GitHub Actions falha → action abre issue com título + logs → desenvolvedor roda /check-issues → Claude Code lê as issues abertas e age
```

**Setup no GitHub Actions:**
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
        body: `Run: ${context.serverUrl}/${context.repo.owner}/${context.repo.repo}/actions/runs/${context.runId}`,
        labels: ['ci-failure']
      })
```

**Como usar:**
- Rodar `/check-issues` no Claude Code — o agente lê todas as issues abertas com label `ci-failure`, investiga, corrige e fecha a issue após o fix.

**Vantagens:**
- Zero infraestrutura adicional
- Issues ficam rastreadas no repositório com histórico
- Desenvolvedor aciona o agente quando quiser, sem sessão aberta permanente

### Regras de commit

- Cada commit é production-ready — nunca commitar código quebrado
- Commits atômicos: um commit = uma mudança coesa
- Mensagens descritivas: `Add SlotCard widget with border accent rule` — nunca `fix` ou `ajuste`
- Nunca `git add .` — apenas arquivos relacionados à mudança
- Nunca acumular mudanças não commitadas por mais de uma sessão

---

## Refactoring contínuo

Refactoring não é fase — é hábito. Nunca acumular dívida técnica que exige cirurgia de emergência depois.

- Widget acima de 100 linhas → extrair subcomponentes
- Método `build()` acima de 50 linhas → extrair widgets
- Repositório acima de 80 linhas → extrair service
- Lógica duplicada em 2+ lugares → extrair helper ou mixin
- Fazer no momento, não depois — o agente executa refactoring em minutos quando a base tem testes

---

## Timezone

Todos os timestamps salvos em **UTC** no banco. Conversão para exibição na camada de apresentação — nunca na lógica de negócio.

O timezone do usuário é derivado da cidade cadastrada no perfil (`users.city`). Uma lib de mapeamento cidade → IANA timezone resolve a conversão — investigar `timezone` package do pub.dev ou equivalente que cubra cidades brasileiras. A lib `intl` do Flutter e o Postgres `AT TIME ZONE` fazem a conversão uma vez que o IANA timezone está resolvido.

Regras:
- Nunca salvar horário local no banco — sempre UTC
- Nunca converter timezone em Edge Function — apenas no Flutter ao exibir
- `starts_at` e `ends_at` de slots são sempre UTC — o Flutter converte para o timezone do usuário antes de exibir

---

## Paginação

Toda listagem usa **cursor-based pagination** — nunca offset. Offset degrada com volume, cursor é constante.

Padrão de cursor no Supabase:
```typescript
// Primeira página
const { data } = await supabase
  .from('sessions')
  .select('*')
  .eq('relationship_id', relationshipId)
  .is('deleted_at', null)
  .order('created_at', { ascending: false })
  .limit(20)

// Próxima página — cursor é o created_at do último item
const { data } = await supabase
  .from('sessions')
  .select('*')
  .eq('relationship_id', relationshipId)
  .is('deleted_at', null)
  .lt('created_at', lastCreatedAt)
  .order('created_at', { ascending: false })
  .limit(20)
```

Telas que usam paginação no Rallye: extrato, histórico de sessões, lista de solicitações, notificações.

---

## Tratamento de erros

Três camadas obrigatórias para todo erro:

**1. Tipagem estrita — Result type no Flutter**
Usar `fpdart` para encapsular resultados em `Either<Failure, T>`. Nenhuma exceção sobe solta pela UI:

```dart
// Repositório retorna Either, nunca lança exceção
Future<Either<Failure, List<Session>>> fetchSessions(String relationshipId);

// Widget trata os dois casos explicitamente
final result = await repository.fetchSessions(id);
result.fold(
  (failure) => showError(failure.message),
  (sessions) => updateState(sessions),
);
```

**2. Tradução na UI**
Erros técnicos nunca aparecem na tela do usuário. Toda `Failure` tem uma mensagem em português, clara e acionável:
- `NetworkFailure` → "Sem conexão. Verifique sua internet."
- `NotFoundFailure` → "Horário não encontrado."
- `UnauthorizedFailure` → "Sessão expirada. Faça login novamente."

**3. Log no Sentry**
Todo erro inesperado (não tratado como fluxo normal) é capturado via `Sentry.captureException` com `user_id` e contexto do evento. O usuário vê a mensagem traduzida; o Sentry recebe o detalhe técnico com stack trace.

---

## Rate limiting — Upstash Redis

Edge Functions customizadas não têm rate limiting nativo no Supabase. Usar **Upstash Redis** — plano gratuito, integra com Deno nativamente:

```typescript
import { Ratelimit } from 'https://esm.sh/@upstash/ratelimit'
import { Redis } from 'https://esm.sh/@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '1m'),
})

const { success } = await ratelimit.limit(userId)
if (!success) return new Response('Too many requests', { status: 429 })
```

Funções com rate limiting obrigatório: criação de conta, login, criação de slot, solicitação de slot, registro de pagamento.

Adicionar `UPSTASH_REDIS_REST_URL` e `UPSTASH_REDIS_REST_TOKEN` aos secrets do GitHub e variáveis de ambiente do Supabase.

---

## Edge Functions — regras de autenticação e versionamento

### `anon key` + JWT como padrão absoluto

Toda Edge Function usa `anon key` com JWT do usuário autenticado. O RLS do Postgres faz o controle de acesso — não a função.

`service_role` é proibido como padrão. Se em algum momento for absolutamente necessário, precisa ser documentado explicitamente aqui como exceção com justificativa — nunca usado silenciosamente.

```typescript
// Padrão obrigatório em toda Edge Function
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_ANON_KEY')!, // nunca SERVICE_ROLE_KEY como padrão
  { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
)
// Com isso, o RLS se aplica automaticamente com o contexto do usuário autenticado
```

### Versionamento de Edge Functions

Toda Edge Function é nomeada com prefixo de versão desde o início:

```
supabase/functions/
  v1-confirm-slot/
  v1-register-payment/
  v1-close-session/
  v1-send-notification/
  v1-promote-waitlist/
```

Quando uma função precisa de breaking change:
1. Criar `v2-confirm-slot` com a nova implementação
2. Deployar `v2` sem remover `v1`
3. Migrar o Flutter para chamar `v2`
4. Manter `v1` ativa até confirmar que nenhum cliente antigo a usa
5. Remover `v1` após confirmação

Nunca sobrescrever uma função em produção com breaking change sem versionamento.

---

### Validação de ownership quando `service_role` é necessário

Toda Edge Function que usa `service_role` (que bypassa RLS) valida explicitamente que o usuário autenticado tem permissão sobre o recurso antes de qualquer operação:

```typescript
// Padrão obrigatório — extrair e validar user do JWT
const authHeader = req.headers.get('Authorization')
const { data: { user }, error } = await supabase.auth.getUser(
  authHeader?.replace('Bearer ', '') ?? ''
)
if (error || !user) return new Response('Unauthorized', { status: 401 })

// Validar ownership explicitamente — nunca confiar só no RLS
const { data: slot } = await supabase
  .from('slots')
  .select('teacher_id')
  .eq('id', slotId)
  .single()

if (slot?.teacher_id !== user.id) {
  return new Response('Forbidden', { status: 403 })
}
```

Regra: 401 para não autenticado, 403 para autenticado mas sem permissão. Nunca retornar 404 para esconder a existência do recurso em contexto de ownership — use 403 explícito.

---

## Idempotência

Operações financeiras e de estado crítico são idempotentes — se a Edge Function rodar duas vezes com o mesmo input, o resultado é o mesmo sem duplicação.

Padrão: `idempotency_key` único gerado pelo cliente (UUID v4), salvo na tabela da operação:

```typescript
// Cliente gera e envia no request
const idempotencyKey = crypto.randomUUID()

// Edge Function verifica antes de processar
const { data: existing } = await supabase
  .from('payments')
  .select('id')
  .eq('idempotency_key', idempotencyKey)
  .single()

if (existing) {
  return new Response(JSON.stringify(existing), { status: 200 })
}
// Só processa se não existe — evita duplicação
```

Operações com idempotência obrigatória: registro de pagamento, encerramento de sessão, confirmação de slot.

---

## Notificações — estado de leitura

Notificação é marcada como lida por **ação explícita do usuário** — tap na notificação no app. Nunca marcada automaticamente ao abrir a tela.

`read_at` é preenchido no momento do tap via update na tabela `notifications`. Badge de não lidas conta registros com `read_at IS NULL`.

---



### Flutter/Dart — `analysis_options.yaml`

Configuração na raiz do projeto. Usa `flutter_lints` como base oficial:

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

`flutter analyze` roda no CI em todo commit. Falha de lint = commit bloqueado.

### Edge Functions — TypeScript/Deno — `deno.json`

Configuração na pasta `supabase/functions/`:

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

`deno lint` e `deno fmt --check` rodam no CI em todo commit.

### Regra absoluta — proibição de `any` no TypeScript

**`any` é proibido. Sem exceções.**

O uso de `any` significa que a modelagem dos dados não está clara ou que foi tomado um atalho. Quando surgir a tentação de usar `any`, o desenvolvimento para e o problema é discutido antes de prosseguir.

O `noImplicitAny: true` no `compilerOptions` e a flag `ban-ts-comment` no linter barram `any` e `@ts-ignore` automaticamente — o CI falha antes do código entrar.

Se o TypeScript não consegue inferir o tipo, a solução correta é sempre uma dessas:
- Definir uma interface ou type explícito
- Usar `unknown` com type guard quando o tipo é genuinamente desconhecido
- Revisar a modelagem dos dados

Nunca `any`. Se aparecer, é sinal de problema na arquitetura — não um atalho aceitável.

### Regras de estilo de código — TypeScript e Dart

**`var` / `const` / `let` no TypeScript**
- `const` por padrão — sempre
- `let` apenas quando a variável precisa ser reatribuída
- `var` nunca — barrado pelo linter com `no-var`

**`final` / `var` no Dart**
- `final` por padrão — sempre
- `var` apenas quando necessário
- `const` em widgets sempre que possível — não são reconstruídos desnecessariamente

**Early return — guard clauses first**
Validar e retornar cedo. O happy path fica flat, sem aninhamento:
```typescript
// errado
function processSlot(slot: Slot) {
  if (slot) {
    if (slot.status === 'confirmed') {
      // lógica aqui dentro aninhada
    }
  }
}

// certo
function processSlot(slot: Slot) {
  if (!slot) return
  if (slot.status !== 'confirmed') return
  // lógica principal flat
}
```

**Sem `else` após `return`/`throw`/`continue`**
Se o bloco `if` termina com `return`, o `else` é desnecessário e proibido:
```typescript
// errado
if (isValid) {
  return process()
} else {
  return error()
}

// certo
if (isValid) return process()
return error()
```

**`else if` em último caso**
Usar `else if` apenas quando não há alternativa. Na maioria dos casos, early return ou switch/map eliminam a necessidade.

**Funções pequenas — responsabilidade única**
Uma função faz uma coisa. Limite de 20 linhas por função. Se precisa de comentário para explicar o que a função faz, o nome está errado ou ela deve ser dividida.

**Nomes que dispensam comentário**
O nome da função e das variáveis deve tornar o código autoexplicativo:
```typescript
// ruim
function get(id: string)       // o que busca?
function handle(data: unknown) // o que faz?

// certo
function fetchTeacherProfile(teacherId: string): Promise<TeacherProfile>
function confirmSlotRequest(requestId: string): Promise<void>
```

**Sem números mágicos — usar constantes nomeadas**
```typescript
// errado
if (slot.price < slot.defaultPrice * 0.9) showDiscountBadge()

// certo
const DISCOUNT_THRESHOLD = 0.9
if (slot.price < slot.defaultPrice * DISCOUNT_THRESHOLD) showDiscountBadge()
```

**Sem negação dupla**
```typescript
// errado
if (!isNotValid)

// certo
if (isValid)
```

**Tipagem explícita em retornos de função pública**
Toda função pública declara o tipo de retorno — não depende de inferência para contratos públicos:
```typescript
// errado
async function getSlot(id: string) { ... }

// certo
async function getSlot(id: string): Promise<Slot> { ... }
```

---

## Gerenciamento de estado — Riverpod

**Decisão: Riverpod**

- Estado da arte no Flutter — substituto moderno do Provider, criado pelo mesmo autor
- Fortemente tipado — alinha com a filosofia do projeto, sem `dynamic` ou `Object`
- Integra naturalmente com streams do Supabase (realtime)
- Fácil de testar unitariamente e mockar nos widget tests
- Cada provider tem responsabilidade única

Adicionar ao `pubspec.yaml`:
```yaml
dependencies:
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x

dev_dependencies:
  riverpod_generator: ^2.x
  build_runner: ^2.x
```

Nunca usar gerenciamento de estado ad-hoc (`setState` além do estritamente necessário para UI local). Toda lógica de negócio e estado compartilhado vive em providers.

---

## Validação de input — Zod nas Edge Functions

Toda Edge Function que recebe payload externo usa **Zod** para validar e tipar o input antes de qualquer operação. Sem Zod, o body chega como `unknown` e abre espaço para `any` entrar pela porta dos fundos.

Zod valida o schema e infere o tipo TypeScript automaticamente — sem cast manual, sem `any`:

```typescript
import { z } from 'https://deno.land/x/zod/mod.ts'

const CreateSlotSchema = z.object({
  teacher_id: z.string().uuid(),
  starts_at: z.string().datetime(),
  ends_at: z.string().datetime(),
  price: z.number().int().positive(), // centavos — inteiro positivo
  is_group: z.boolean(),
  max_students: z.number().int().positive().nullable(),
})

type CreateSlotInput = z.infer<typeof CreateSlotSchema>

// Na Edge Function — sempre usar safeParse, nunca parse
const result = CreateSlotSchema.safeParse(await req.json())
if (!result.success) {
  return new Response(JSON.stringify(result.error), { status: 400 })
}
// result.data é CreateSlotInput — totalmente tipado
```

Regras:
- Toda Edge Function pública tem schema Zod definido antes da lógica
- Sempre `safeParse` — nunca `parse` (não lança exceção, retorna result tipado)
- Schema Zod é a fonte de verdade do contrato da função — documentação viva

---

## Soft delete — integridade dos dados

**Decisão: soft delete em todas as tabelas que mudam de estado.**

Nenhum registro crítico é deletado fisicamente. Deleção = setar `deleted_at`. Queries sempre filtram `deleted_at IS NULL`.

Tabelas com soft delete:
- `slots` — slot cancelado não desaparece, histórico preservado
- `slot_requests` — solicitação cancelada fica registrada
- `relationships` — vínculo desfeito mantém histórico de sessões
- `sessions` — nunca deletar sessão realizada
- `teacher_clubs` — clube removido preserva histórico

Coluna padrão em todas essas tabelas:
```sql
deleted_at timestamptz default null
```

Políticas RLS sempre incluem `AND deleted_at IS NULL` nas queries de leitura.

---

## `updated_at` — rastreamento de mudança de estado

Toda tabela que muda de estado tem `updated_at`. Atualizado automaticamente via trigger no Postgres — nunca manualmente no código.

Tabelas que precisam de `updated_at`:
- `slots` — status muda: available → requested → confirmed → cancelled
- `slot_requests` — status muda: pending → confirmed → rejected → waitlisted → cancelled
- `relationships` — active pode mudar
- `teacher_settings` — configurações mudam
- `sessions` — confirmed_at e completed_at são preenchidos ao longo do tempo
- `notifications` — read_at é preenchido depois

Trigger padrão a aplicar em todas:
```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
BEFORE UPDATE ON slots
FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

---

## Supabase Realtime

**Decisão: usar Realtime — está incluído no plano gratuito** (200 conexões simultâneas, 2M mensagens/mês — suficiente para MVP).

Casos de uso no Rallye:
- Aluno vê status da solicitação mudar em tempo real (pending → confirmed/rejected)
- Notificações in-app sem polling
- Extrato atualiza após professor marcar sessão como paga

Padrão com Riverpod:
```dart
// Provider que escuta stream do Supabase Realtime
@riverpod
Stream<List<SlotRequest>> slotRequestsStream(SlotRequestsStreamRef ref, String slotId) {
  return Supabase.instance.client
      .from('slot_requests')
      .stream(primaryKey: ['id'])
      .eq('slot_id', slotId)
      .map((rows) => rows.map(SlotRequest.fromJson).toList());
}
```

Nunca usar polling (`Timer.periodic`) onde Realtime resolve.

---

## Offline

**Decisão: sem suporte offline.**

O app requer conexão ativa. Sem internet — sem acesso. Nenhuma camada de cache local, nenhum sync, nenhuma fila de operações pendentes. Exibir mensagem clara de erro de conectividade quando não há rede.

---

## Logs — Sentry

**Decisão: Sentry no lugar do Discord para logs de app.**

Sentry captura exceções com stack trace automático, sessões, alertas por threshold e integra com Flutter e Deno nativamente. O Discord não é mais usado como destino de logs de produto.

### Flutter — `sentry_flutter`

```dart
await SentryFlutter.init(
  (options) {
    options.dsn = const String.fromEnvironment('SENTRY_DSN');
    options.tracesSampleRate = 1.0;
  },
  appRunner: () => runApp(const App()),
);
```

Eventos capturados automaticamente:
- Exceções não tratadas
- Erros de framework Flutter
- Navegação (breadcrumbs automáticos)

Eventos capturados manualmente (obrigatório):
- Falhas de notificação push
- Operações financeiras com erro inesperado

### Edge Functions — `@sentry/deno`

```typescript
import * as Sentry from 'https://deno.land/x/sentry/index.mjs'

Sentry.init({ dsn: Deno.env.get('SENTRY_DSN') })

// Capturar exceção não tratada
try {
  // lógica
} catch (err) {
  Sentry.captureException(err, { extra: { user_id, event: 'slot.confirm' } })
  return new Response('Internal error', { status: 500 })
}
```

Regras:
- Nunca logar dados sensíveis — sem tokens, sem dados pessoais além de `user_id`
- Erros esperados (validação, 404, 403) não vão para o Sentry — apenas exceções inesperadas
- `SENTRY_DSN` vai para secrets do GitHub e variáveis de ambiente do Supabase

---



JavaScript tem um problema histórico com ponto flutuante (IEEE 754):

```javascript
0.1 + 0.2 === 0.30000000000000004 // true
```

Em um app financeiro isso é catastrófico — extrato errado, valor cobrado diferente do combinado, desconto calculado incorretamente.

**Regra: todos os valores monetários são salvos em centavos como inteiro.**

```
R$ 80,00  → salva como 8000
R$ 39,50  → salva como 3950
R$ 0,99   → salva como 99
```

**No banco (Postgres/Supabase):**
- Tipo: `integer` ou `bigint` — nunca `numeric`, `float` ou `decimal`
- Todas as colunas de valor: `price`, `default_price`, `agreed_price`, `amount` — todas em centavos

**No TypeScript (Edge Functions):**
- Nunca operar com valores em reais — sempre em centavos
- Conversão para exibição apenas na camada de apresentação
- Constante obrigatória para conversão:
```typescript
const CENTS_PER_REAL = 100

// converter para exibição
function formatCurrency(cents: number): string {
  return (cents / CENTS_PER_REAL).toLocaleString('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  })
}
```

**No Flutter/Dart:**
- Mesma regra — valores trafegam como `int` (centavos)
- Conversão para exibição apenas no widget, nunca na lógica de negócio
- Nunca usar `double` para valores monetários

**Regra de ouro: se um valor monetário está em `double` ou `float` em qualquer camada, está errado.**

---

## Common Hurdles

*Esta seção cresce ao longo do projeto. Toda armadilha descoberta é documentada aqui imediatamente.*

*(vazio no início — preenchido durante o desenvolvimento)*

---

## Comportamento esperado

- Sempre pergunte antes de criar arquivos fora da estrutura definida
- Nunca altere o schema do banco sem confirmação explícita
- Nunca sugira trocar Flutter, Supabase ou qualquer tecnologia já definida
- Sempre siga as convenções de nomenclatura — inglês no código, português na interface
- Ao criar widgets, sempre use os tokens de cor e tipografia definidos — nunca hardcode hex ou fontsize arbitrário
- Ao criar políticas RLS, apresente o SQL para revisão antes de aplicar
- Quando houver dúvida sobre comportamento de produto, consulte `docs/rallye-brief.md`
- Quando houver dúvida sobre decisão visual, consulte `docs/guidelines.md`
