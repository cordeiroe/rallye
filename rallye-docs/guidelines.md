# Rallye — Design Guidelines

**Versão 0.1 — Abril 2026**

---

## Princípios

O app deve transmitir **simplicidade e agilidade**. O usuário entra, faz o que precisa e sai. Nenhuma tela deve gerar dúvida sobre o que fazer a seguir. Sem decoração desnecessária, sem informação irrelevante, sem fluxos longos onde um toque resolve.

**Regra inegociável:** zero AI slop. Nenhuma decisão visual pode ser tomada por conveniência ou por ser o padrão genérico. Gradientes roxos, fontes Inter/Roboto, cards em grid de 3 colunas, botões com border-radius exagerado em azul royal — tudo isso é proibido.

---

## Identidade visual

**Direção:** Quadra de noite. Inspirado na iluminação artificial das quadras cobertas — fundo escuro com tom quente, acento em amarelo âmbar. Sofisticado e diferente de qualquer app de esporte existente.

---

## Tipografia

Duas fontes. Papéis distintos, sem sobreposição.

| Fonte | Papel | Uso |
|---|---|---|
| **Space Grotesk** | Display / destaque | Títulos de tela, valores monetários, horários, números |
| **Outfit** | Corpo / suporte | Texto corrido, labels, informações secundárias, navegação |

### Escala tipográfica

| Token | Fonte | Tamanho | Peso | Uso |
|---|---|---|---|---|
| `display` | Space Grotesk | 32px | 700 | Valores grandes no extrato |
| `heading1` | Space Grotesk | 24px | 600 | Títulos de tela |
| `heading2` | Space Grotesk | 20px | 700 | Saudação na home |
| `heading3` | Space Grotesk | 18px | 600 | Títulos de seção |
| `body` | Outfit | 16px | 400 | Texto principal |
| `bodyMedium` | Outfit | 14px | 500 | Nomes, labels de destaque |
| `caption` | Outfit | 13px | 400 | Informações secundárias |
| `label` | Outfit | 11px | 600 | Section titles, badges |
| `micro` | Outfit | 10px | 400 | Metadados, timestamps |

### Regras de tipografia

- Texto de suporte **nunca abaixo de `#8C8880`** sobre qualquer fundo escuro
- `stat-sub` e textos auxiliares dentro de cards usam sempre `textSecondary (#8C8880)`
- Section titles em **uppercase + letter-spacing** para separar hierarquia
- Valores monetários sempre em **Space Grotesk bold**

---

## Paleta de cores

### Base — fundos

| Token | Hex | Uso |
|---|---|---|
| `background` | `#1C1A18` | Fundo principal da tela |
| `surface` | `#252320` | Cards, modais, superfícies elevadas |
| `surfaceHigh` | `#2E2C29` | Inputs, elementos interativos, time blocks |

### Acento

| Token | Hex | Uso |
|---|---|---|
| `accent` | `#F5C842` | CTAs, valores monetários, ícones ativos, border accent |
| `accentMuted` | `#3D3115` | Fundo de badges com acento, avatares, hover states |

> **Regra do acento:** `#F5C842` aparece com moderação. Só em elementos que exigem ação ou destaque máximo. O restante da interface respira no escuro. Excesso de amarelo destrói a sofisticação.

### Texto

| Token | Hex | Uso |
|---|---|---|
| `textPrimary` | `#F2EFE8` | Texto principal — branco levemente quente |
| `textSecondary` | `#8C8880` | Labels, informações secundárias, metadados |
| `textDisabled` | `#4A4845` | Placeholders, section titles, elementos desabilitados |

### Semânticas

| Token | Hex | Fundo | Uso |
|---|---|---|---|
| `success` | `#4CAF82` | `#0D2B1F` | Aula confirmada, pagamento recebido |
| `warning` | `#E8944A` | `#2B1E0D` | Fila de espera, pendente |
| `error` | `#E05C5C` | `#2B0D0D` | Cancelamento, erro, logout |

> **Regra dos badges:** sempre usar o fundo semântico correspondente. Nunca aplicar a cor semântica diretamente sobre `surface`.

---

## Ícones

**Biblioteca:** Phosphor Icons (`phosphor_flutter`)

**Sistema mixed stroke/filled:**
- Inativo → peso `regular` (stroke), cor `textDisabled (#4A4845)`
- Ativo → peso `fill`, cor `accent (#F5C842)`

### Navbar

| Aba | Inativo | Ativo |
|---|---|---|
| Home | `House` | `HouseFill` |
| Agenda | `Calendar` | `CalendarFill` |
| Extrato | `Invoice` | `InvoiceFill` |
| Perfil | `User` | `UserFill` |

### Ações em cards

| Ação | Ícone |
|---|---|
| Confirmar | `CheckCircle` |
| Rejeitar / Cancelar | `XCircle` |
| Fila de espera | `ClockCountdown` |
| Editar | `PencilSimple` |
| Notificações | `Bell` |
| Configurações | `GearSix` |
| Adicionar slot | `Plus` |
| Grupo | `Users` |
| Desconto | `Tag` |

---

## Componentes

### Navbar bottom

- Fundo `background (#1C1A18)`
- Border top `1px solid surface (#252320)`
- 4 itens: Home, Agenda, Extrato, Perfil
- Ícone ativo: filled + `accent`
- Label ativo: `accent`
- Padding bottom respeita safe area do dispositivo

### Cards de slot / aula

```
background: surface (#252320)
border-radius: 14px
padding: 14px 16px
border-left: 3px solid transparent  →  inativo
border-left: 3px solid accent (#F5C842)  →  próxima aula
border-left: 3px solid textDisabled (#4A4845)  →  aula em grupo
```

**Border accent rule:** `border-left: 3px solid #F5C842` aparece **apenas** no card cujo `starts_at` é o mais próximo do momento atual com status `confirmed`. Quando o horário passa, a marcação migra automaticamente para o próximo. Cards passados, cancelados ou sem confirmação nunca recebem a marcação.

### Stat cards

```
background: surface (#252320)
border-radius: 12px
padding: 14px 12px
```

- Valor principal: `Space Grotesk 20px 700 accent` (monetário) ou `textPrimary` (neutro)
- Label: `Outfit 11px textSecondary`
- Sublabel: `Outfit 11px textSecondary` — **nunca abaixo de `#8C8880`**

### Badges

```
border-radius: 6px
padding: 3px 8px
font: Outfit 10px 600
```

| Tipo | Fundo | Texto |
|---|---|---|
| success | `#0D2B1F` | `#4CAF82` |
| warning | `#2B1E0D` | `#E8944A` |
| error | `#2B0D0D` | `#E05C5C` |
| accent | `#3D3115` | `#F5C842` |
| muted | `#2E2C29` | `#8C8880` |

### Botões

**Primário (CTA):**
```
background: accent (#F5C842)
color: background (#1C1A18)
border-radius: 10px
padding: 14px
font: Space Grotesk 14px 700
width: 100%
```

**Secundário / Destrutivo:**
```
background: transparent
border: 1px solid surfaceHigh (#2E2C29)
color: error (#E05C5C)  →  ação destrutiva
color: textSecondary (#8C8880)  →  ação neutra
border-radius: 10px
padding: 12px
font: Space Grotesk 13-14px 600
```

**Ações inline (confirmar/rejeitar):**
```
Confirmar: background accent, color background, border-radius 7px, padding 6px 12px
Rejeitar:  background surfaceHigh, color textSecondary, border-radius 7px, padding 6px 10px
```

### Inputs

```
background: surface (#252320)
border: 1px solid surfaceHigh (#2E2C29)
border-radius: 10px
padding: 12px 14px
font: Space Grotesk (valores) ou Outfit (texto)
color: textPrimary
placeholder-color: textDisabled
```

### Toggles

```
width: 40px, height: 22px, border-radius: 11px
OFF: background surfaceHigh, thumb textDisabled
ON:  background accentMuted (#3D3115), thumb accent (#F5C842)
```

### Avatares

```
border-radius: 50%
background: accentMuted (#3D3115)
color: accent (#F5C842)
font: Space Grotesk bold
```

Foto do Google OAuth usada quando disponível.

### Filter pills

```
Ativo:   background accent, color background, border-radius 20px, padding 6px 14px
Inativo: background surface, color textSecondary, border-radius 20px, padding 6px 14px
font: Outfit 12px 500
```

### Dividers

```
height: 1px
background: surface (#252320)
margin: 0 20px
```

### Section titles

```
font: Outfit 11px 600
color: textDisabled (#4A4845)
letter-spacing: 0.1em
text-transform: uppercase
padding: 0 20px
```

---

## Layout e espaçamento

- Padding horizontal padrão das telas: `20px`
- Gap entre cards: `8px`
- Gap entre seções: `16–24px`
- Safe area bottom: respeitada pelo navbar

---

## Regras de desconto em slots

- Exibir badge de desconto **somente** quando `slot.price < teacher.default_price`
- Calcular e exibir o percentual: `((default - slot) / default * 100)%`
- Aumento de valor é **silencioso** — nenhuma informação exibida ao aluno

---

## Nomenclatura — interface em português

O app é direcionado ao público brasileiro. Toda string de interface em português. Exemplos:

| Inglês (banco/código) | Português (interface) |
|---|---|
| `confirmed` | Confirmado |
| `pending` | Pendente |
| `waitlisted` | Fila de espera |
| `cancelled` | Cancelado |
| `available` | Disponível |
| `settings` | Configurações |
| `teacher` | Professor |
| `student` | Aluno |
| `slot` | Horário |
| `session` | Aula |

---

## Anti-padrões — o que nunca fazer

- Gradientes de qualquer tipo
- Sombras decorativas (`box-shadow` com blur)
- Fontes Inter, Roboto, Arial ou system fonts
- Bordas arredondadas exageradas em botões (> 12px)
- Cores roxas ou azul royal como acento
- Grid de cards em 3 colunas
- Ícones sem sistema definido (misturar libs)
- Texto auxiliar abaixo de `#8C8880` sobre fundos escuros
- Badge semântico sem fundo correspondente
- Accent `#F5C842` em mais de 20% dos elementos visíveis por tela
