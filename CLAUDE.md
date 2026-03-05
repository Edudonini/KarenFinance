# Karen Finance — Contexto para Claude Code

## Visão Geral

WebApp de gestão financeira para casal, Mobile-First (PWA).
Stack: Next.js (App Router) + TypeScript + Supabase + Tailwind CSS + Zustand.

---

## Estrutura de Pastas

```
karen/
├── public/
│   ├── icons/              # Ícones PWA
│   └── manifest.json       # PWA manifest
├── src/
│   ├── app/
│   │   ├── (auth)/         # Grupo de rotas públicas
│   │   │   ├── login/
│   │   │   ├── signup/
│   │   │   ├── forgot-password/
│   │   │   └── reset-password/
│   │   ├── (app)/          # Grupo de rotas protegidas
│   │   │   ├── dashboard/
│   │   │   ├── transactions/
│   │   │   ├── categories/
│   │   │   ├── shopping/
│   │   │   ├── scanner/
│   │   │   └── settings/
│   │   ├── layout.tsx      # Root layout (fonts, metadata)
│   │   └── globals.css
│   ├── components/
│   │   ├── ui/             # Primitivos (Button, Input, Card, Modal, Toast)
│   │   └── [feature]/      # Componentes por feature (TransactionForm, ShoppingItem)
│   ├── hooks/              # Custom hooks (useTransactions, useShopping)
│   ├── lib/
│   │   ├── supabase/
│   │   │   ├── client.ts   # createBrowserClient
│   │   │   ├── server.ts   # createServerClient
│   │   │   └── middleware.ts
│   │   ├── utils.ts        # cn(), formatCurrency(), etc.
│   │   └── constants.ts    # Constantes do app
│   ├── stores/             # Zustand stores
│   ├── types/
│   │   ├── database.ts     # Tipos gerados pelo Supabase
│   │   └── index.ts        # Tipos customizados
│   └── actions/            # Server Actions
├── supabase/
│   ├── migrations/         # SQL migrations
│   ├── functions/          # Edge Functions
│   └── seed.sql            # Dados iniciais
├── CHECKLIST.md
├── CLAUDE.md
└── prd.md
```

---

## Padrões TypeScript

- **Strict mode** habilitado (`strict: true` no tsconfig)
- **Nunca usar `any`** — usar `unknown` e fazer narrowing quando necessário
- **Interfaces** para objetos/contratos, **Types** para unions/intersections
- **Tipos do Supabase** gerados automaticamente (`supabase gen types typescript`)
- Usar `satisfies` para validação de tipo sem perder narrowing

```typescript
// ✅ Correto
interface Transaction {
  id: string;
  description: string;
  amount_cents: number;
  category_id: string;
}

type TransactionType = "income" | "expense";

// ❌ Errado
const data: any = await fetchData();
```

---

## Padrões React / Next.js

- **Server Components por padrão** — só adicionar `"use client"` quando necessário (eventos, hooks, browser APIs)
- **Server Actions** para mutações de dados (criar, editar, deletar)
- **Validação com Zod** em Server Actions
- **Não usar** `useEffect` para fetch de dados — usar Server Components ou React Query
- Route handlers apenas para webhooks/APIs externas

```typescript
// Server Action — src/actions/transactions.ts
"use server";

import { z } from "zod";
import { createServerClient } from "@/lib/supabase/server";
import { revalidatePath } from "next/cache";

const CreateTransactionSchema = z.object({
  description: z.string().min(1),
  amount_cents: z.number().int().positive(),
  category_id: z.string().uuid(),
  date: z.string().date(),
  type: z.enum(["income", "expense"]),
});

export async function createTransaction(formData: FormData) {
  const supabase = await createServerClient();
  const parsed = CreateTransactionSchema.safeParse({
    description: formData.get("description"),
    amount_cents: Number(formData.get("amount_cents")),
    category_id: formData.get("category_id"),
    date: formData.get("date"),
    type: formData.get("type"),
  });

  if (!parsed.success) {
    return { error: parsed.error.flatten() };
  }

  const { error } = await supabase.from("transactions").insert(parsed.data);
  if (error) return { error: error.message };

  revalidatePath("/transactions");
  return { success: true };
}
```

---

## Padrões de Componentes

```typescript
// src/components/ui/Button.tsx
'use client';

import { cn } from '@/lib/utils';
import { ButtonHTMLAttributes, forwardRef } from 'react';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
}

const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={cn(
          'inline-flex items-center justify-center rounded-lg font-medium transition-colors',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2',
          'disabled:pointer-events-none disabled:opacity-50',
          {
            'bg-primary text-white hover:bg-primary/90': variant === 'primary',
            'bg-secondary text-secondary-foreground hover:bg-secondary/80': variant === 'secondary',
            'hover:bg-accent hover:text-accent-foreground': variant === 'ghost',
            'bg-destructive text-white hover:bg-destructive/90': variant === 'danger',
          },
          {
            'h-8 px-3 text-sm': size === 'sm',
            'h-10 px-4 text-sm': size === 'md',
            'h-12 px-6 text-base': size === 'lg',
          },
          className
        )}
        {...props}
      />
    );
  }
);
Button.displayName = 'Button';
export default Button;
```

---

## Padrões de Hooks

```typescript
// src/hooks/useTransactions.ts
"use client";

import { useStore } from "@/stores/transactions";
import { createBrowserClient } from "@/lib/supabase/client";
import { useEffect } from "react";

export function useTransactions(month: string) {
  const { transactions, setTransactions } = useStore();
  const supabase = createBrowserClient();

  useEffect(() => {
    const channel = supabase
      .channel("transactions")
      .on("postgres_changes", { event: "*", schema: "public", table: "transactions" }, () => {
        // Refetch on change
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [supabase]);

  return { transactions };
}
```

---

## Padrões de Services (Supabase)

```typescript
// Queries em Server Components — direto no componente
import { createServerClient } from '@/lib/supabase/server';

export default async function TransactionsPage() {
  const supabase = await createServerClient();
  const { data: transactions } = await supabase
    .from('transactions')
    .select('*, categories(*)')
    .order('date', { ascending: false });

  return <TransactionList transactions={transactions ?? []} />;
}
```

---

## Tailwind CSS

- **Mobile-first:** sempre começar com estilos mobile, usar `md:` e `lg:` para breakpoints maiores
- **Utility `cn()`** para composição condicional de classes
- **Design tokens** definidos no `tailwind.config.ts`:

```typescript
// tailwind.config.ts
const config = {
  theme: {
    extend: {
      colors: {
        primary: { DEFAULT: "#6366f1", foreground: "#ffffff" },
        secondary: { DEFAULT: "#f1f5f9", foreground: "#0f172a" },
        destructive: { DEFAULT: "#ef4444", foreground: "#ffffff" },
        accent: { DEFAULT: "#f1f5f9", foreground: "#0f172a" },
        success: "#22c55e",
        warning: "#f59e0b",
        muted: { DEFAULT: "#f1f5f9", foreground: "#64748b" },
      },
    },
  },
};
```

---

## Formatação de Moeda

- **Sempre trabalhar com centavos** no banco e na lógica (evitar floating point)
- Converter para reais apenas na exibição
- Locale: `pt-BR`, Currency: `BRL`

```typescript
// src/lib/utils.ts
export function formatCurrency(cents: number): string {
  return new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
  }).format(cents / 100);
}

export function toCents(reais: number): number {
  return Math.round(reais * 100);
}
```

---

## Conventional Commits

Formato: `<tipo>(<escopo>): <descrição>`

### Tipos

- `feat` — nova funcionalidade
- `fix` — correção de bug
- `chore` — tarefas de manutenção (deps, config)
- `refactor` — refatoração sem mudança de comportamento
- `style` — formatação, espaçamento
- `test` — adição/modificação de testes
- `docs` — documentação
- `perf` — melhoria de performance

### Escopos

- `auth` — autenticação
- `budget` — orçamento/transações
- `shopping` — lista de compras
- `scanner` — QR Code/NFC-e
- `dashboard` — dashboard
- `ui` — componentes de UI
- `db` — banco de dados/migrations
- `pwa` — PWA/offline
- `config` — configuração do projeto

Exemplo: `feat(shopping): adicionar botão "acabou" com último preço`

---

## Workflow MCP

### Após cada alteração de código:

1. **`getDiagnostics` (IDE MCP)** — Verificar erros TypeScript e ESLint
2. **Corrigir** qualquer erro antes de prosseguir

### Ao criar/modificar componentes visuais:

1. **`take_snapshot` (chrome-devtools)** — Obter estado atual da UI (a11y tree)
2. **`take_screenshot` (chrome-devtools)** — Capturar screenshot para validação visual
3. **`list_console_messages` (chrome-devtools)** — Verificar erros no console

### Ao otimizar performance:

1. **`performance_start_trace` (chrome-devtools)** — Iniciar gravação
2. Navegar/interagir com a página
3. **`performance_stop_trace` (chrome-devtools)** — Parar e analisar resultados
4. Verificar LCP, CLS, INP

### Banco de dados (Supabase MCP):

- Usar **Supabase MCP** para executar queries diretas e gerenciar tabelas
- Verificar dados após migrations
- Testar RLS policies com queries usando diferentes roles

### Deploy (Vercel MCP):

- Usar **Vercel MCP** para gerenciar deployments
- Verificar status de deploy após push

---

## Plugins Claude Code

### `frontend-design`

- **Quando usar:** ao criar qualquer componente visual, página ou formulário
- Produz interfaces com alta qualidade visual, evitando estética genérica de AI

### `superpowers` (v4.3.1)

- **Quando usar:** para TDD (escrever teste antes do código), debugging complexo, patterns comprovados
- Skills: TDD, debugging avançado, collaboration patterns

### `context7`

- **Quando usar:** antes de implementar qualquer feature, buscar documentação atualizada
- Fontes: Next.js, Supabase, Tailwind CSS, Zustand, Zod, Recharts

---

## Boas Práticas Supabase

- **RLS sempre ativo** em todas as tabelas
- **Nunca expor `service_role` key** no frontend
- Usar `@supabase/ssr` para auth (não `@supabase/auth-helpers-nextjs` que é deprecated)
- Tipos gerados: rodar `supabase gen types typescript --project-id <id> > src/types/database.ts`
- Usar `supabase.auth.getUser()` (server-side) em vez de `getSession()` para verificar auth
- Realtime apenas onde necessário (lista de compras, salary do parceiro)

---

## Modelagem de Dados — Decisões

- **Sem tabela `households`** — vincular casal via `partner_id` no profile
- **RLS baseado em partner_id:** `auth.uid() = user_id OR auth.uid() = (SELECT partner_id FROM profiles WHERE id = user_id)`
- **`amount_cents`** (integer) em vez de `amount` (decimal) — evitar problemas de floating point
- **`price_history`** separada para histórico de preços e comparativos
- **`categories`** como tabela separada para CRUD, ícones, cores e `budget_limit`
- **Alerta 80%:** calcular no frontend comparando sum(transactions) vs categories.budget_limit

---

## Lista de "Não Fazer"

- ❌ **Não criar Pull Requests** — commit direto na main (projeto pessoal)
- ❌ **Não usar CSS Modules** — usar Tailwind CSS exclusivamente
- ❌ **Não usar Pages Router** — apenas App Router
- ❌ **Não usar ORM** (Prisma, Drizzle) — usar Supabase client direto
- ❌ **Não usar `useEffect` para fetch** — usar Server Components
- ❌ **Não usar `getSession()`** — usar `getUser()` para verificar auth
- ❌ **Não usar `@supabase/auth-helpers-nextjs`** — usar `@supabase/ssr`
- ❌ **Não usar `any`** em TypeScript
- ❌ **Não armazenar valores monetários como float/decimal** — usar centavos (integer)
- ❌ **Não desabilitar RLS** em nenhuma tabela
- ❌ **Não commitar `.env.local`** ou qualquer arquivo com secrets
