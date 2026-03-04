-- Migration 2: Categories table, seed function, updated handle_new_user
-- Dependencies: profiles

-- =============================================================================
-- Table: categories
-- =============================================================================
CREATE TABLE public.categories (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT NOT NULL,
  icon         TEXT NOT NULL DEFAULT '📦',
  color        TEXT NOT NULL DEFAULT '#6366f1',
  type         TEXT NOT NULL CHECK (type IN ('fixed', 'variable')),
  budget_limit INTEGER,  -- cents, nullable
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_categories_user_id ON public.categories(user_id);

-- =============================================================================
-- Function: seed_default_categories(UUID)
-- =============================================================================
CREATE OR REPLACE FUNCTION public.seed_default_categories(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.categories (name, icon, color, type, user_id) VALUES
    ('Aluguel',     '🏠', '#8b5cf6', 'fixed',    p_user_id),
    ('Internet',    '🌐', '#3b82f6', 'fixed',    p_user_id),
    ('Lazer',       '🎮', '#f59e0b', 'variable', p_user_id),
    ('Saúde',       '💊', '#ef4444', 'variable', p_user_id),
    ('Transporte',  '🚗', '#64748b', 'variable', p_user_id),
    ('Açougue',     '🥩', '#dc2626', 'variable', p_user_id),
    ('Hortifruti',  '🥦', '#22c55e', 'variable', p_user_id),
    ('Mercado',     '🛒', '#0ea5e9', 'variable', p_user_id);
END;
$$;

-- =============================================================================
-- Update handle_new_user to also seed categories
-- =============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'display_name', '')
  );

  PERFORM public.seed_default_categories(NEW.id);

  RETURN NEW;
END;
$$;

-- =============================================================================
-- RLS: categories
-- =============================================================================
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own and partner categories"
  ON public.categories FOR SELECT
  USING (
    auth.uid() = user_id
    OR auth.uid() = public.get_partner_id(user_id)
  );

CREATE POLICY "Users can insert own categories"
  ON public.categories FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own categories"
  ON public.categories FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own categories"
  ON public.categories FOR DELETE
  USING (auth.uid() = user_id);
