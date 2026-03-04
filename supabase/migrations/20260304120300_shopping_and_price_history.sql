-- Migration 4: Shopping items, shopping list, price history, latest_prices view, realtime
-- Dependencies: profiles, receipts

-- =============================================================================
-- Table: shopping_items (catalog)
-- =============================================================================
CREATE TABLE public.shopping_items (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT NOT NULL,
  category     TEXT NOT NULL CHECK (category IN ('acougue', 'hortifruti', 'mercado')),
  unit_measure TEXT NOT NULL DEFAULT 'un',
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_shopping_items_name ON public.shopping_items(name);
CREATE INDEX idx_shopping_items_user_id ON public.shopping_items(user_id);

CREATE TRIGGER set_shopping_items_updated_at
  BEFORE UPDATE ON public.shopping_items
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- =============================================================================
-- RLS: shopping_items
-- =============================================================================
ALTER TABLE public.shopping_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own and partner shopping items"
  ON public.shopping_items FOR SELECT
  USING (
    auth.uid() = user_id
    OR auth.uid() = public.get_partner_id(user_id)
  );

CREATE POLICY "Users can insert own shopping items"
  ON public.shopping_items FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own shopping items"
  ON public.shopping_items FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own shopping items"
  ON public.shopping_items FOR DELETE
  USING (auth.uid() = user_id);

-- =============================================================================
-- Table: shopping_list (active list)
-- =============================================================================
CREATE TABLE public.shopping_list (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id      UUID NOT NULL REFERENCES public.shopping_items(id) ON DELETE CASCADE,
  quantity     NUMERIC NOT NULL DEFAULT 1,
  unit_measure TEXT NOT NULL DEFAULT 'un',
  status       TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'bought')),
  added_by     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_shopping_list_status ON public.shopping_list(status);

CREATE TRIGGER set_shopping_list_updated_at
  BEFORE UPDATE ON public.shopping_list
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- =============================================================================
-- RLS: shopping_list (granular — partner can UPDATE/DELETE but not INSERT)
-- =============================================================================
ALTER TABLE public.shopping_list ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own and partner shopping list"
  ON public.shopping_list FOR SELECT
  USING (
    auth.uid() = added_by
    OR auth.uid() = public.get_partner_id(added_by)
  );

CREATE POLICY "Users can insert own shopping list items"
  ON public.shopping_list FOR INSERT
  WITH CHECK (auth.uid() = added_by);

CREATE POLICY "Users and partner can update shopping list"
  ON public.shopping_list FOR UPDATE
  USING (
    auth.uid() = added_by
    OR auth.uid() = public.get_partner_id(added_by)
  );

CREATE POLICY "Users and partner can delete shopping list items"
  ON public.shopping_list FOR DELETE
  USING (
    auth.uid() = added_by
    OR auth.uid() = public.get_partner_id(added_by)
  );

-- =============================================================================
-- Table: price_history
-- =============================================================================
CREATE TABLE public.price_history (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id     UUID NOT NULL REFERENCES public.shopping_items(id) ON DELETE CASCADE,
  price_cents INTEGER NOT NULL,
  store_name  TEXT,
  store_cnpj  TEXT,
  date        DATE NOT NULL DEFAULT CURRENT_DATE,
  receipt_id  UUID REFERENCES public.receipts(id) ON DELETE SET NULL,
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_price_history_item_date ON public.price_history(item_id, date);

-- =============================================================================
-- RLS: price_history
-- =============================================================================
ALTER TABLE public.price_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own and partner price history"
  ON public.price_history FOR SELECT
  USING (
    auth.uid() = user_id
    OR auth.uid() = public.get_partner_id(user_id)
  );

CREATE POLICY "Users can insert own price history"
  ON public.price_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own price history"
  ON public.price_history FOR DELETE
  USING (auth.uid() = user_id);

-- =============================================================================
-- View: latest_prices — last price per item
-- =============================================================================
CREATE OR REPLACE VIEW public.latest_prices AS
SELECT DISTINCT ON (item_id)
  id,
  item_id,
  price_cents,
  store_name,
  date
FROM public.price_history
ORDER BY item_id, date DESC, created_at DESC;

-- =============================================================================
-- Function: get_last_price(UUID) → INTEGER
-- =============================================================================
CREATE OR REPLACE FUNCTION public.get_last_price(p_item_id UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT price_cents
  FROM public.price_history
  WHERE item_id = p_item_id
  ORDER BY date DESC, created_at DESC
  LIMIT 1;
$$;

-- =============================================================================
-- Realtime: enable for shopping_list and profiles
-- =============================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.shopping_list;
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
