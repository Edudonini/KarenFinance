-- Migration 3: Receipts and transactions tables, generate_installments function
-- Dependencies: profiles, categories

-- =============================================================================
-- Table: receipts
-- =============================================================================
CREATE TABLE public.receipts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  url         TEXT,
  store_name  TEXT,
  store_cnpj  TEXT,
  total_cents INTEGER NOT NULL DEFAULT 0,
  date        DATE NOT NULL DEFAULT CURRENT_DATE,
  raw_data    JSONB,
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_receipts_user_id ON public.receipts(user_id);

-- =============================================================================
-- RLS: receipts
-- =============================================================================
ALTER TABLE public.receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own and partner receipts"
  ON public.receipts FOR SELECT
  USING (
    auth.uid() = user_id
    OR auth.uid() = public.get_partner_id(user_id)
  );

CREATE POLICY "Users can insert own receipts"
  ON public.receipts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own receipts"
  ON public.receipts FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own receipts"
  ON public.receipts FOR DELETE
  USING (auth.uid() = user_id);

-- =============================================================================
-- Table: transactions
-- =============================================================================
CREATE TABLE public.transactions (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  description          TEXT NOT NULL,
  amount_cents         INTEGER NOT NULL,
  category_id          UUID REFERENCES public.categories(id) ON DELETE SET NULL,
  user_id              UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date                 DATE NOT NULL DEFAULT CURRENT_DATE,
  type                 TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  is_installment       BOOLEAN NOT NULL DEFAULT false,
  total_installments   INTEGER,
  current_installment  INTEGER,
  installment_group_id UUID,
  receipt_id           UUID REFERENCES public.receipts(id) ON DELETE SET NULL,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_transactions_user_date ON public.transactions(user_id, date);
CREATE INDEX idx_transactions_category ON public.transactions(category_id);
CREATE INDEX idx_transactions_installment_group ON public.transactions(installment_group_id);

CREATE TRIGGER set_transactions_updated_at
  BEFORE UPDATE ON public.transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- =============================================================================
-- RLS: transactions
-- =============================================================================
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own and partner transactions"
  ON public.transactions FOR SELECT
  USING (
    auth.uid() = user_id
    OR auth.uid() = public.get_partner_id(user_id)
  );

CREATE POLICY "Users can insert own transactions"
  ON public.transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own transactions"
  ON public.transactions FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own transactions"
  ON public.transactions FOR DELETE
  USING (auth.uid() = user_id);

-- =============================================================================
-- Function: generate_installments
-- Generates N monthly transactions for installment purchases
-- Returns the installment_group_id
-- =============================================================================
CREATE OR REPLACE FUNCTION public.generate_installments(
  p_description TEXT,
  p_total_amount_cents INTEGER,
  p_category_id UUID,
  p_user_id UUID,
  p_start_date DATE,
  p_total_installments INTEGER,
  p_receipt_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_group_id UUID := gen_random_uuid();
  v_installment_amount INTEGER;
  v_remainder INTEGER;
  i INTEGER;
BEGIN
  -- Calculate even split and remainder for first installment
  v_installment_amount := p_total_amount_cents / p_total_installments;
  v_remainder := p_total_amount_cents - (v_installment_amount * p_total_installments);

  FOR i IN 1..p_total_installments LOOP
    INSERT INTO public.transactions (
      description,
      amount_cents,
      category_id,
      user_id,
      date,
      type,
      is_installment,
      total_installments,
      current_installment,
      installment_group_id,
      receipt_id
    ) VALUES (
      p_description || ' (' || i || '/' || p_total_installments || ')',
      CASE WHEN i = 1 THEN v_installment_amount + v_remainder ELSE v_installment_amount END,
      p_category_id,
      p_user_id,
      p_start_date + ((i - 1) * INTERVAL '1 month')::INTERVAL,
      'expense',
      true,
      p_total_installments,
      i,
      v_group_id,
      CASE WHEN i = 1 THEN p_receipt_id ELSE NULL END
    );
  END LOOP;

  RETURN v_group_id;
END;
$$;
