# Karen Finance — Checklist de Implementação

> ~180 sub-tarefas organizadas em 11 fases (0–10).
> Marque `[x]` conforme concluir cada item.

---

## Fase 0 — Setup Inicial (~25 tarefas)

### Repositório & Projeto

- [x] Inicializar repositório git
- [x] Configurar remote origin (`git@github.com:Edudonini/KarenFinance.git`)
- [x] Criar `CLAUDE.md` com padrões do projeto
- [x] Criar `CHECKLIST.md` (este arquivo)
- [x] Criar `.gitignore` (Next.js padrão)
- [x] Commit inicial e push

### Next.js

- [x] Criar projeto Next.js com App Router (`npx create-next-app@latest`)
- [x] Configurar TypeScript strict mode (`tsconfig.json`)
- [x] Configurar `next.config.ts` (imagens, headers, etc.)
- [x] Instalar e configurar Tailwind CSS
- [x] Configurar design tokens (cores, espaçamentos) no `globals.css` (Tailwind v4)
- [x] Criar utility `cn()` (clsx + tailwind-merge)
- [x] Configurar ESLint + Prettier
- [x] Configurar path aliases (`@/`)

### Supabase

- [ ] Criar projeto no Supabase Dashboard
- [x] Instalar `@supabase/supabase-js` e `@supabase/ssr`
- [x] Configurar variáveis de ambiente (`.env.local`)
- [x] Criar client Supabase (browser)
- [x] Criar client Supabase (server)
- [x] Criar middleware de autenticação (`middleware.ts`)
- [ ] Gerar tipos TypeScript do Supabase (`supabase gen types`)

### PWA

- [ ] Instalar e configurar `next-pwa` / Serwist (Fase 8)
- [x] Criar `manifest.ts` (nome, ícones, cores, display standalone)
- [x] Criar ícones PWA placeholder (192x192, 512x512)

### Estado Global

- [x] Instalar Zustand
- [x] Criar store base com tipagem TypeScript

---

## Fase 1 — Modelagem de Dados e Migrations (~25 tarefas)

### Tabela `profiles`

- [ ] Criar migration: tabela `profiles` (id, display_name, salary, partner_id, avatar_url, created_at, updated_at)
- [ ] Criar trigger `handle_new_user` para inserir profile automaticamente
- [ ] Criar RLS: usuário lê/edita próprio profile
- [ ] Criar RLS: usuário lê profile do parceiro (via `partner_id`)
- [ ] Criar index em `partner_id`

### Tabela `categories`

- [ ] Criar migration: tabela `categories` (id, name, icon, color, type: fixed/variable, budget_limit, user_id, created_at)
- [ ] Criar RLS: usuário acessa suas categorias + categorias do parceiro
- [ ] Seed de categorias padrão (Aluguel, Internet, Lazer, Saúde, Transporte, Açougue, Hortifruti, Mercado)
- [ ] Criar index em `user_id`

### Tabela `transactions`

- [ ] Criar migration: tabela `transactions` (id, description, amount_cents, category_id, user_id, date, type: income/expense, is_installment, total_installments, current_installment, installment_group_id, receipt_id, created_at, updated_at)
- [ ] Criar RLS: usuário acessa suas transações + transações do parceiro
- [ ] Criar function para gerar parcelas automaticamente
- [ ] Criar index composto em `(user_id, date)`
- [ ] Criar index em `category_id`
- [ ] Criar index em `installment_group_id`

### Tabela `shopping_items` (Catálogo)

- [ ] Criar migration: tabela `shopping_items` (id, name, category: açougue/hortifruti/mercado, unit_measure, user_id, created_at, updated_at)
- [ ] Criar RLS: acesso casal
- [ ] Criar index em `name` (busca)
- [ ] Criar index em `user_id`

### Tabela `shopping_list` (Lista Ativa)

- [ ] Criar migration: tabela `shopping_list` (id, item_id FK, quantity, unit_measure, status: pending/bought, added_by, created_at, updated_at)
- [ ] Criar RLS: acesso casal
- [ ] Criar index em `status`

### Tabela `price_history`

- [ ] Criar migration: tabela `price_history` (id, item_id FK, price_cents, store_name, store_cnpj, date, receipt_id, created_at)
- [ ] Criar RLS: acesso casal
- [ ] Criar index composto em `(item_id, date)`
- [ ] Criar view materializada ou function para "último preço" por item

### Tabela `receipts` (Notas Fiscais)

- [ ] Criar migration: tabela `receipts` (id, url, store_name, store_cnpj, total_cents, date, raw_data JSONB, user_id, created_at)
- [ ] Criar RLS: acesso casal

---

## Fase 2 — Autenticação (~18 tarefas)

### Páginas de Auth

- [ ] Criar layout do grupo `(auth)` (centralizado, logo)
- [ ] Criar página de Login (`/login`) com email/senha
- [ ] Criar página de Cadastro (`/signup`) com display_name e salary
- [ ] Criar página de Recuperação de Senha (`/forgot-password`)
- [ ] Criar página de Reset de Senha (`/reset-password`)
- [ ] Implementar Server Actions para login
- [ ] Implementar Server Actions para signup
- [ ] Implementar Server Actions para forgot-password
- [ ] Implementar Server Actions para reset-password
- [ ] Adicionar validação de formulários (Zod)
- [ ] Adicionar feedback visual (loading, toast de erro/sucesso)

### Proteção de Rotas

- [ ] Configurar middleware Next.js para proteger rotas `(app)`
- [ ] Redirecionar não-autenticados para `/login`
- [ ] Redirecionar autenticados de `/login` para `/dashboard`

### Vinculação de Parceiro

- [ ] Criar página/modal de vinculação de parceiro
- [ ] Implementar lógica: gerar código de convite
- [ ] Implementar lógica: aceitar convite e setar `partner_id` mútuo
- [ ] Criar RPC no Supabase para vinculação atômica (transação)

---

## Fase 3 — RF01: Gestão de Orçamento (~25 tarefas)

### Renda Conjunta

- [ ] Criar página de configuração de renda (`/settings/income`)
- [ ] Formulário para editar salário do usuário
- [ ] Exibir soma das rendas (usuário + parceiro)
- [ ] Server Action para atualizar salary no profile
- [ ] Realtime: atualizar quando parceiro alterar salary

### Categorias

- [ ] Criar página de categorias (`/categories`)
- [ ] Listar categorias com ícone, cor e budget_limit
- [ ] Formulário para criar categoria (nome, ícone, cor, tipo, limite)
- [ ] Formulário para editar categoria
- [ ] Confirmar e deletar categoria (com validação de transações vinculadas)
- [ ] Server Actions para CRUD de categorias

### Transações

- [ ] Criar página de transações (`/transactions`)
- [ ] Listar transações do mês com filtro por categoria
- [ ] Formulário para criar transação (descrição, valor, categoria, data, tipo)
- [ ] Suporte a entrada de valor em reais (converter para centavos)
- [ ] Formulário para editar transação
- [ ] Deletar transação (com confirmação)
- [ ] Server Actions para CRUD de transações

### Parcelamentos

- [ ] Checkbox "É parcelado?" no formulário de transação
- [ ] Campos adicionais: total de parcelas
- [ ] Lógica para gerar N transações futuras automaticamente (via DB function)
- [ ] Exibir badge "3/12" nas transações parceladas
- [ ] Listar todas as parcelas de um grupo
- [ ] Permitir cancelar parcelas futuras

### Resumo Mensal

- [ ] Componente de resumo: renda total, gastos totais, saldo
- [ ] Barra de progresso por categoria (gasto vs. limite)
- [ ] Navegação entre meses (anterior/próximo)

---

## Fase 4 — RF02: Lista de Compras (~22 tarefas)

### Catálogo de Itens

- [ ] Criar página de catálogo (`/shopping/catalog`)
- [ ] Listar itens do catálogo com busca
- [ ] Formulário para criar item (nome, categoria, unidade de medida)
- [ ] Formulário para editar item
- [ ] Deletar item do catálogo
- [ ] Server Actions para CRUD de itens

### Lista Ativa

- [ ] Criar página da lista ativa (`/shopping`)
- [ ] Listar itens pendentes agrupados por local (Mercado, Açougue, Hortifruti)
- [ ] Adicionar item à lista (busca no catálogo + quantidade)
- [ ] Marcar item como "comprado" (swipe ou checkbox)
- [ ] Exibir último preço pago ao lado do item (via `price_history`)
- [ ] Remover item da lista
- [ ] Server Actions para operações na lista
- [ ] Realtime: sincronizar lista entre casal

### Botão "Acabou"

- [ ] Botão rápido no catálogo para marcar "acabou"
- [ ] Ao clicar, adicionar à lista ativa com última quantidade
- [ ] Feedback visual (toast/animação)

### Conversão de Unidades

- [ ] Implementar lógica de conversão simples (ex: 2x 500g = 1kg)
- [ ] Exibir quantidade convertida na lista
- [ ] Suporte a unidades: kg, g, L, mL, un

### Finalização de Compra

- [ ] Botão "Finalizar compra" — marcar todos como comprados
- [ ] Converter itens comprados em transação no orçamento

---

## Fase 5 — RF03: QR Code NFC-e (~22 tarefas)

### Scanner

- [ ] Criar página do scanner (`/scanner`)
- [ ] Solicitar permissão da câmera
- [ ] Implementar leitura de QR Code (biblioteca: `html5-qrcode` ou similar)
- [ ] Extrair URL do QR Code
- [ ] Validar formato da URL (NFC-e SP)
- [ ] Feedback visual: overlay na câmera, vibração ao ler

### Edge Function (Parser)

- [ ] Criar Supabase Edge Function `parse-nfce`
- [ ] Receber URL como parâmetro
- [ ] Fazer fetch da página da NFC-e
- [ ] Parsear HTML com cheerio: extrair tabela de produtos
- [ ] Extrair: CNPJ, nome loja, data, itens (nome, qtd, unidade, valor unitário, valor total)
- [ ] Retornar JSON estruturado
- [ ] Tratamento de erros (URL inválida, página fora do ar, formato inesperado)
- [ ] Rate limiting básico

### Processamento no Frontend

- [ ] Exibir preview dos itens extraídos
- [ ] Permitir edição/remoção de itens antes de salvar
- [ ] Mapear itens da nota para itens do catálogo (match por nome)
- [ ] Criar itens novos no catálogo quando não houver match
- [ ] Salvar receipt no banco
- [ ] Salvar price_history para cada item
- [ ] Criar transação automática com total da nota

### Comparativo de Preços

- [ ] Exibir comparativo durante a compra: preço atual vs. último preço
- [ ] Indicador visual: mais caro (vermelho), mais barato (verde), igual (cinza)

---

## Fase 6 — RF04: Dashboard (~18 tarefas)

### Página Principal

- [ ] Criar página dashboard (`/dashboard`)
- [ ] Layout responsivo mobile-first
- [ ] Seletor de mês/período

### Gráfico de Rosca (Categorias)

- [ ] Instalar biblioteca de gráficos (Recharts ou Chart.js)
- [ ] Componente de gráfico de rosca
- [ ] Dados: % gasto por categoria no mês
- [ ] Legendas clicáveis (filtrar ao clicar)
- [ ] Tooltip com valor absoluto e percentual

### Barras de Progresso (Orçamento)

- [ ] Componente de barra de progresso por categoria
- [ ] Exibir: gasto atual / limite definido
- [ ] Cor dinâmica: verde (<60%), amarelo (60-80%), vermelho (>80%)
- [ ] Animação de preenchimento

### Alertas

- [ ] Sistema de alertas quando categoria ultrapassa 80% do limite
- [ ] Componente de alerta visual (banner/badge)
- [ ] Listar categorias em alerta no topo do dashboard

### Resumo Financeiro

- [ ] Card: Renda total do casal
- [ ] Card: Total de gastos no mês
- [ ] Card: Saldo restante
- [ ] Card: Próximas parcelas a vencer
- [ ] Mini-lista: últimas 5 transações

---

## Fase 7 — Layout e Navegação (~18 tarefas)

### Shell do App

- [ ] Criar layout raiz do grupo `(app)` com header e bottom nav
- [ ] Header: logo/nome, avatar do usuário, menu dropdown
- [ ] Implementar menu dropdown (configurações, logout)

### Bottom Navigation

- [ ] Componente de bottom nav fixo (mobile)
- [ ] Ícones + labels: Dashboard, Orçamento, Lista, Scanner
- [ ] Indicador de aba ativa
- [ ] Animação de transição entre abas
- [ ] Esconder bottom nav no desktop (sidebar lateral)

### Componentes Compartilhados

- [ ] Componente `Button` (variantes: primary, secondary, ghost, danger)
- [ ] Componente `Input` (com label, erro, ícone)
- [ ] Componente `Card` (container padrão)
- [ ] Componente `Modal` (dialog acessível)
- [ ] Componente `Toast` (notificações)
- [ ] Componente `EmptyState` (placeholder para listas vazias)
- [ ] Componente `LoadingSkeleton` (shimmer)
- [ ] Componente `CurrencyInput` (entrada de valor em BRL)
- [ ] Componente `MonthPicker` (seletor de mês)

---

## Fase 8 — Requisitos Não Funcionais (~18 tarefas)

### PWA (RNF01)

- [ ] Verificar manifest.json completo (nome, ícones, start_url, display)
- [ ] Testar instalação no Chrome Android
- [ ] Testar instalação no Safari iOS
- [ ] Configurar splash screen
- [ ] Configurar tema de cores da status bar

### Offline & Sync (RNF02)

- [ ] Configurar Service Worker para cache de assets estáticos
- [ ] Implementar cache da lista de compras para uso offline
- [ ] Criar fila de operações offline (IndexedDB ou localStorage)
- [ ] Implementar sync automático ao retomar conexão
- [ ] Resolver conflitos de sync (last-write-wins ou merge)
- [ ] Indicador visual de modo offline
- [ ] Indicador visual de sincronização em andamento
- [ ] Testar cenário: adicionar item offline → reconectar → verificar sync

### Performance (RNF03)

- [ ] Medir LCP da lista de compras (meta: <1.5s)
- [ ] Implementar `loading.tsx` com skeleton para cada rota
- [ ] Otimizar bundle: dynamic imports para componentes pesados (gráficos, scanner)
- [ ] Configurar cache headers para assets estáticos
- [ ] Otimizar imagens (next/image, formatos modernos)

---

## Fase 9 — Testes (~14 tarefas)

### Setup

- [ ] Instalar e configurar Vitest
- [ ] Instalar e configurar Testing Library (React)
- [ ] Instalar e configurar Playwright (E2E)
- [ ] Configurar mocks do Supabase

### Testes Unitários

- [ ] Testar utility `cn()`
- [ ] Testar formatação de moeda (centavos → BRL)
- [ ] Testar conversão de unidades
- [ ] Testar lógica de geração de parcelas

### Testes de Integração

- [ ] Testar fluxo de autenticação (login/signup)
- [ ] Testar CRUD de transações
- [ ] Testar CRUD de lista de compras
- [ ] Testar vinculação de parceiro

### Testes E2E

- [ ] Testar fluxo completo: login → criar transação → ver no dashboard
- [ ] Testar fluxo: marcar "acabou" → item aparece na lista → finalizar compra

---

## Fase 10 — Deploy (~12 tarefas)

### Preparação

- [ ] Revisar variáveis de ambiente para produção
- [ ] Configurar domínio (se aplicável)
- [ ] Revisar RLS policies (segurança)
- [ ] Testar build de produção local (`next build`)

### Vercel

- [ ] Conectar repositório ao Vercel
- [ ] Configurar variáveis de ambiente no Vercel
- [ ] Deploy inicial
- [ ] Verificar funcionalidades em produção
- [ ] Configurar preview deployments para PRs

### Monitoramento

- [ ] Configurar Vercel Analytics (Web Vitals)
- [ ] Configurar alertas de erro (Sentry ou similar)
- [ ] Documentar runbook básico (como fazer rollback, como verificar logs)

---

## Resumo

| Fase                          | Tarefas  | Status |
| ----------------------------- | -------- | ------ |
| 0 — Setup Inicial             | 25       | 🟡     |
| 1 — Modelagem de Dados        | 25       | ⬜     |
| 2 — Autenticação              | 18       | ⬜     |
| 3 — RF01: Orçamento           | 25       | ⬜     |
| 4 — RF02: Lista de Compras    | 22       | ⬜     |
| 5 — RF03: QR Code NFC-e       | 22       | ⬜     |
| 6 — RF04: Dashboard           | 18       | ⬜     |
| 7 — Layout e Navegação        | 18       | ⬜     |
| 8 — RNFs (PWA, Offline, Perf) | 18       | ⬜     |
| 9 — Testes                    | 14       | ⬜     |
| 10 — Deploy                   | 12       | ⬜     |
| **Total**                     | **~217** |        |
