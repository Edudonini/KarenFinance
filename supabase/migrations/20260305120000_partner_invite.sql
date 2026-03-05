-- Add invite_code column to profiles
ALTER TABLE profiles ADD COLUMN invite_code TEXT UNIQUE;

-- Index for fast lookup by invite_code
CREATE INDEX idx_profiles_invite_code ON profiles (invite_code) WHERE invite_code IS NOT NULL;

-- RPC: Generate a 6-char alphanumeric invite code for the current user
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_code TEXT;
  v_exists BOOLEAN;
BEGIN
  -- Only generate if user doesn't already have a code
  SELECT invite_code INTO v_code FROM profiles WHERE id = auth.uid();
  IF v_code IS NOT NULL THEN
    RETURN v_code;
  END IF;

  -- Generate unique 6-char code
  LOOP
    v_code := upper(substr(md5(random()::text), 1, 6));
    SELECT EXISTS(SELECT 1 FROM profiles WHERE invite_code = v_code) INTO v_exists;
    EXIT WHEN NOT v_exists;
  END LOOP;

  UPDATE profiles SET invite_code = v_code WHERE id = auth.uid();
  RETURN v_code;
END;
$$;

-- RPC: Link partner using invite code
CREATE OR REPLACE FUNCTION link_partner(p_invite_code TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_partner_id UUID;
  v_my_partner_id UUID;
BEGIN
  -- Check if caller already has a partner
  SELECT partner_id INTO v_my_partner_id FROM profiles WHERE id = auth.uid();
  IF v_my_partner_id IS NOT NULL THEN
    RAISE EXCEPTION 'Você já está vinculado a um parceiro';
  END IF;

  -- Find partner by invite code
  SELECT id INTO v_partner_id FROM profiles WHERE invite_code = upper(p_invite_code);
  IF v_partner_id IS NULL THEN
    RAISE EXCEPTION 'Código de convite inválido';
  END IF;

  -- Cannot link to yourself
  IF v_partner_id = auth.uid() THEN
    RAISE EXCEPTION 'Você não pode vincular a si mesmo';
  END IF;

  -- Check if partner already has a partner
  SELECT partner_id INTO v_my_partner_id FROM profiles WHERE id = v_partner_id;
  IF v_my_partner_id IS NOT NULL THEN
    RAISE EXCEPTION 'Este parceiro já está vinculado a outra pessoa';
  END IF;

  -- Link both profiles atomically
  UPDATE profiles SET partner_id = v_partner_id, invite_code = NULL WHERE id = auth.uid();
  UPDATE profiles SET partner_id = auth.uid(), invite_code = NULL WHERE id = v_partner_id;
END;
$$;
