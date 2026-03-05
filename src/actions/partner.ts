"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface PartnerActionState {
  success?: boolean;
  error?: string;
  inviteCode?: string;
}

export async function generateInviteCode(): Promise<PartnerActionState> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("generate_invite_code");

  if (error) {
    return { error: error.message };
  }

  return { success: true, inviteCode: data as string };
}

export async function linkPartner(
  _prevState: PartnerActionState,
  formData: FormData
): Promise<PartnerActionState> {
  const code = formData.get("invite_code");

  if (!code || typeof code !== "string" || code.trim().length === 0) {
    return { error: "Insira o código de convite" };
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc("link_partner", {
    p_invite_code: code.trim(),
  });

  if (error) {
    return { error: error.message };
  }

  revalidatePath("/dashboard");
  return { success: true };
}
