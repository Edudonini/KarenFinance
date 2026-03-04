# PRD: WebApp de Gestão Financeira e Compras para Casal

## 1. Visão Geral
Este projeto consiste em um WebApp **Mobile-First** (SPA/PWA) projetado para um casal que compartilha 100% da renda e despesas. O objetivo é substituir planilhas complexas por uma interface intuitiva que centraliza o orçamento mensal, controle de parcelamentos e uma lista de compras inteligente com integração via QR Code (NFC-e SP).

### Pilares do Produto
* **Pool de Renda:** Soma de salários para um orçamento único.
* **Inteligência de Mercado:** Parser de notas fiscais para histórico de preços unitários.
* **Automação:** Lançamento automático de compras parceladas.
* **Resiliência:** Funcionamento offline (PWA) para uso em supermercados.

---

## 2. Stack Tecnológica
* **Framework:** Next.js (App Router)
* **Linguagem:** TypeScript
* **Banco de Dados & Auth:** Supabase (PostgreSQL)
* **Estilização:** Tailwind CSS
* **Estado Global:** React Context ou Zustand
* **Offline/PWA:** Next-PWA (Service Workers)

---

## 3. Requisitos Funcionais (RF)

### RF01: Gestão de Orçamento (Budget)
- **Renda Conjunta:** O sistema deve somar as entradas de ambos os usuários para compor o saldo mensal.
- **Categorização:** - Gastos Fixos (Aluguel, Internet, etc.)
    - Gastos Variáveis (Lazer, Saúde, Transporte)
    - Subcategorias exclusivas: **Açougue** e **Hortifruti** (separadas do mercado geral).
- **Controle de Parcelamento:** Ao cadastrar uma compra parcelada, o sistema deve projetar automaticamente o valor nas faturas dos meses subsequentes.
- **Transparência:** Todos os lançamentos são visíveis para ambos, sem distinção de privacidade.

### RF02: Lista de Compras Inteligente
- **Status "Acabou":** Botão rápido para itens recorrentes. Ao ser marcado, o item volta para a lista ativa com a última quantidade registrada.
- **Divisão por Local:** Filtros para facilitar a visualização dentro do Supermercado, Açougue ou Hortifruti.
- **Entrada Manual:** Campos para Nome, Preço, Quantidade e Unidade de Medida (com suporte a conversão simples, ex: 2x 500g = 1kg).

### RF03: Integração QR Code (NFC-e SP)
- **Scanner:** Acesso à câmera para leitura do QR Code de notas fiscais de São Paulo (Capital).
- **Parser de Dados:** - Extrair CNPJ do estabelecimento, data, nome dos produtos, quantidades e valores unitários.
    - Alimentar automaticamente a base de dados de preços para comparação histórica.
- **Comparativo:** Durante a compra, exibir o último valor pago naquele item para auxiliar na decisão de compra.

### RF04: Dashboard
- **Visualização:** Gráficos de rosca (categorias) e barras de progresso (orçamento gasto vs. restante).
- **Alertas:** Notificações visuais quando uma categoria ultrapassar 80% do teto definido.

---

## 4. Requisitos Não Funcionais (RNF)
- **RNF01 (PWA):** O app deve ser instalável e permitir a visualização da lista de compras sem conexão com internet.
- **RNF02 (Sincronização):** Dados inseridos offline devem ser sincronizados com o Supabase assim que a conexão for restabelecida.
- **RNF03 (Performance):** O carregamento inicial da lista de compras deve ser inferior a 1.5s.

---

## 5. Modelagem de Dados (Entidades Principais)

### Profiles (Usuários)
- `id`, `display_name`, `salary`, `partner_id`

### Transactions (Finanças)
- `id`, `description`, `amount`, `category_id`, `user_id`, `date`, `is_installment`, `total_installments`, `current_installment`

### Shopping_Items (Catálogo de Preços)
- `id`, `name`, `category` (Açougue, Hortifruti, Mercado), `last_price`, `unit_measure`

### Shopping_List (Lista Ativa)
- `id`, `item_id`, `quantity`, `status` (pending/bought)

---

## 6. Fluxo de Usuário (User Stories)
1. **Eu como usuário**, quero marcar que o "Azeite" acabou para que ele apareça na minha lista de compras automaticamente com a última quantidade comprada.
2. **Eu como usuário**, quero escanear o QR Code da nota fiscal após o caixa para que eu não precise digitar item por item no meu controle de gastos.
3. **Eu como usuário**, quero ver quanto do nosso orçamento de "Lazer" ainda resta antes de decidirmos ir jantar fora.

---

## 7. Estratégia de Implementação da NFC-e (SP)
O WebApp enviará a URL do QR Code para uma **Supabase Edge Function**. Esta função utilizará uma biblioteca de scraping (como `cheerio` ou `puppeteer-core`) para acessar o portal da Nota Fiscal Paulista, extrair os dados da tabela de produtos e retornar um JSON estruturado para o frontend.