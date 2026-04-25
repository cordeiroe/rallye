# Rallye — Product Brief

**Versão 0.2 — Abril 2026**

---

## 1. Visão geral

App mobile para controle transparente de aulas entre professor e aluno de padel. O mesmo usuário pode ser professor para alguns e aluno para outros, dentro de um único perfil contextual.

| | |
|---|---|
| **Nome (placeholder)** | Rallye |
| **Problema central** | Professor e aluno perdem o controle de quantas aulas foram dadas e o valor devido no mês |
| **Solução** | Agenda compartilhada com extrato em tempo real, mesma visão para os dois lados |
| **Perfil de usuário** | Único app, perfis contextuais — mesmo usuário pode ser professor e aluno |
| **Primeiro usuário** | Professor de padel de Emerson em Canoas/POA — validação real desde o início |

---

## 2. Modelo de negócio

**Estratégia:** Professor-first. O professor é o cliente pagante. O aluno sempre usa de graça — elimina fricção de adoção.

| | Grátis | Pro (R$39–59/mês) |
|---|---|---|
| Alunos vinculados | Até 3 | Ilimitados |
| Histórico exportável | — | Sim |
| Múltiplos clubes | — | Sim |

---

## 3. Fluxo MVP

| # | Ator | Ação |
|---|---|---|
| 1 | Professor | Publica slots de disponibilidade (dia, horário, valor, individual ou grupo) |
| 2 | Aluno | Solicita um slot no calendário do professor |
| 3 | Sistema | Se slot individual e já há solicitação, entra como `waitlisted` e professor é notificado |
| 4 | Professor | Confirma solicitação — escolhe aluno manualmente ou por ordem de chegada (configurável) |
| 5 | Sistema | Push notification no início do horário para ambos |
| 6 | Sistema | Push notification no fim do horário |
| 7 | Professor | Confirma encerramento da aula via notificação |
| 8 | Sistema | Session criada e extrato atualizado para os dois |

### Cancelamento

- Cancelamento livre — sem prazo mínimo por ora
- Professor pode cancelar slot já confirmado — todos os alunos confirmados são notificados automaticamente
- Se aluno confirmado cancela → professor é notificado e escolhe da fila (manual ou auto-promoção, configurável em settings)

### Slots em grupo

- Professor define no slot se aceita aula em grupo e quantas vagas (`max_students`)
- Sem limite definido: professor decide na hora quantos confirma
- Badge de desconto exibido apenas quando `slot.price < teacher_profiles.default_price`
- Aumento de valor é silencioso — nenhuma informação exibida ao aluno

---

## 4. Personas e campos

### Campos base — todos os usuários (`users`)

| Campo | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `email` | text | unique, vem da autenticação |
| `full_name` | text | |
| `phone` | text | |
| `city` | text | |
| `avatar_url` | text | puxado do Google OAuth |
| `created_at` | timestamptz | |

### Perfil professor (`teacher_profiles`)

| Campo | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK → users.id |
| `bio` | text | |
| `default_price` | integer | em centavos valor base por aula |
| `experience_years` | int | |
| `created_at` | timestamptz | |

### Clubes do professor (`teacher_clubs`)

| Campo | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `teacher_id` | uuid | FK → teacher_profiles.id |
| `name` | text | campo livre, sanitização futura |
| `deleted_at` | timestamptz | nullable — soft delete |

### Settings do professor (`teacher_settings`)

| Campo | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `teacher_id` | uuid | FK → teacher_profiles.id |
| `auto_promote_waitlist` | boolean | default false |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | atualizado via trigger |

### Perfil aluno (`student_profiles`)

| Campo | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK → users.id |
| `category` | text | nullable — 1ª a 7ª, exibe "Sem categoria informada" se vazio |
| `side` | text | right / left / both |
| `created_at` | timestamptz | |

### Clubes do aluno (`student_clubs`)

| Campo | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `student_id` | uuid | FK → student_profiles.id |
| `name` | text | campo livre, sanitização futura |

---

## 5. Modelo de dados completo

### `relationships` — vínculo professor ↔ aluno (N:N)

| Campo | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `teacher_id` | uuid | FK → teacher_profiles.id |
| `student_id` | uuid | FK → student_profiles.id |
| `agreed_price` | integer | nullable — em centavos — valor combinado específico para essa dupla |
| `active` | boolean | default true |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | atualizado via trigger |
| `deleted_at` | timestamptz | nullable — soft delete |

### `slots` — disponibilidade publicada pelo professor

| Campo | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `teacher_id` | uuid | FK → teacher_profiles.id |
| `starts_at` | timestamptz | UTC |
| `ends_at` | timestamptz | UTC |
| `price` | integer | em centavos (ex: R$80,00 = 8000) pode diferir do default_price |
| `is_group` | boolean | default false |
| `max_students` | int | nullable — sem limite se null |
| `status` | text | available / requested / confirmed / cancelled |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | atualizado via trigger ao mudar de status |
| `deleted_at` | timestamptz | nullable — soft delete |

### `slot_requests` — solicitações de alunos para um slot

| Campo | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `slot_id` | uuid | FK → slots.id |
| `student_id` | uuid | FK → student_profiles.id |
| `status` | text | pending / confirmed / rejected / waitlisted / cancelled |
| `requested_at` | timestamptz | usado para critério "primeiro a solicitar" |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | atualizado via trigger ao mudar de status |
| `deleted_at` | timestamptz | nullable — soft delete |

### `sessions` — aula confirmada e realizada (1 por aluno)

| Campo | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `slot_id` | uuid | FK → slots.id |
| `relationship_id` | uuid | FK → relationships.id |
| `confirmed_at` | timestamptz | nullable |
| `completed_at` | timestamptz | nullable |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | atualizado via trigger |
| `deleted_at` | timestamptz | nullable — soft delete |

### `payments` — registro de pagamentos

| Campo | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `relationship_id` | uuid | FK → relationships.id |
| `amount` | integer | em centavos |
| `paid_at` | timestamptz | UTC |
| `method` | text | pix / cash / other |
| `note` | text | nullable |
| `idempotency_key` | text | unique — gerado pelo cliente, evita duplicação |
| `created_at` | timestamptz | |

### `payment_sessions` — junction: pagamento ↔ sessões quitadas

| Campo | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `payment_id` | uuid | FK → payments.id |
| `session_id` | uuid | FK → sessions.id |

### `notifications` — histórico de notificações

| Campo | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK → users.id |
| `type` | text | slot_requested / slot_confirmed / slot_cancelled / session_completed / payment_registered |
| `payload` | jsonb | dados contextuais da notificação |
| `read_at` | timestamptz | nullable |
| `created_at` | timestamptz | |

---

## 6. Stack de desenvolvimento

| | |
|---|---|
| **Frontend / Mobile** | Flutter |
| **Gerenciamento de estado** | Riverpod |
| **Tratamento de erros** | fpdart (Either/Result type) |
| **Validação de input** | Zod (Edge Functions) |
| **Rate limiting** | Upstash Redis |
| **Backend / BaaS** | Supabase (PostgreSQL) |
| **Auth** | Supabase Auth — Google OAuth + Sign in with Apple (fase TestFlight) |
| **Server-side logic** | Supabase Edge Functions (TypeScript / Deno) |
| **Push notifications** | Simuladas localmente; FCM / APNs na fase TestFlight |
| **CI/CD** | GitHub Actions |
| **Logs** | Discord `#app-logs` via webhook das Edge Functions |
| **Repositório** | Privado inicialmente — abrir quando estável para portfólio |

> **Convenção:** tabelas, colunas, variáveis, funções e qualquer artefato de código sempre em inglês.

---

## 7. Segurança

### RLS (Row Level Security)

Todas as tabelas com RLS habilitado desde o início. Nenhuma tabela sobe sem política definida.

- Professor vê apenas seus próprios alunos, slots e sessões
- Aluno vê apenas o extrato do vínculo com cada professor
- Extrato de professor X não é visível para professor Y
- Aluno não vê histórico de outros alunos do mesmo professor

### Chaves e secrets

- `anon key` — vai no app mobile, pública por design, protegida pelo RLS
- `service_role key` — nunca no app mobile, nunca no repositório
- `.env` e `.gitignore` configurados antes do primeiro commit

### Apple Developer Account

Necessária para TestFlight e notificações push em dispositivo físico (~R$550/ano). Decisão: adquirir quando o app estiver estável para teste real.

---

## 8. Roadmap

### MVP
- Cadastro e perfis contextuais (professor / aluno)
- Publicação de slots com suporte a grupo e vagas
- Solicitação, fila de espera e confirmação de aula
- Notificações push (simuladas localmente no início)
- Encerramento de aula via notificação
- Extrato mensal compartilhado
- Registro de pagamentos
- Tela de settings do professor

### V2
- Jogo aula como tipo separado de sessão
- Exportação de extrato em PDF
- Pagamento integrado (Pix)

### V3 — Marketplace
- Busca de professores por região e clube
- Avaliações e reviews
- Disponibilidade pública para novos alunos
