import { createClient } from "@/lib/supabase/server";
import { formatCurrency } from "@/lib/utils";
import { logoutAction } from "@/actions/auth";
import PartnerLinkCard from "@/components/partner/PartnerLinkCard";

export default async function DashboardPage() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: profile } = await supabase
    .from("profiles")
    .select("display_name, salary, partner_id")
    .eq("id", user!.id)
    .single();

  let partnerName: string | null = null;
  if (profile?.partner_id) {
    const { data: partner } = await supabase
      .from("profiles")
      .select("display_name")
      .eq("id", profile.partner_id)
      .single();
    partnerName = partner?.display_name ?? null;
  }

  return (
    <div className="mx-auto max-w-lg space-y-4 p-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-secondary-foreground">
            Olá, {profile?.display_name}
          </h1>
          {profile?.salary != null && (
            <p className="text-sm text-muted-foreground">
              Salário: {formatCurrency(profile.salary)}
            </p>
          )}
        </div>
        <form action={logoutAction}>
          <button
            type="submit"
            className="rounded-lg px-3 py-2 text-sm font-medium text-muted-foreground hover:bg-secondary hover:text-secondary-foreground transition-colors"
          >
            Sair
          </button>
        </form>
      </div>

      <PartnerLinkCard partnerName={partnerName} />

      <div className="rounded-xl bg-white p-6 shadow-sm">
        <p className="text-sm text-muted-foreground">
          Dashboard completo em breve...
        </p>
      </div>
    </div>
  );
}
