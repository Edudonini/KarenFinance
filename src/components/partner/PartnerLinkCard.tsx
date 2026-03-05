"use client";

import { useActionState, useState } from "react";
import { Button, Input } from "@/components/ui";
import { generateInviteCode, linkPartner, type PartnerActionState } from "@/actions/partner";

interface PartnerLinkCardProps {
  partnerName?: string | null;
}

const initialState: PartnerActionState = {};

export default function PartnerLinkCard({ partnerName }: PartnerLinkCardProps) {
  const [linkState, linkAction, linkPending] = useActionState(linkPartner, initialState);
  const [inviteCode, setInviteCode] = useState<string | null>(null);
  const [generating, setGenerating] = useState(false);
  const [copied, setCopied] = useState(false);

  if (partnerName) {
    return (
      <div className="rounded-xl bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-secondary-foreground">Parceiro</h2>
        <div className="mt-3 flex items-center gap-2">
          <svg className="h-5 w-5 text-success" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
          </svg>
          <span className="text-sm text-secondary-foreground">{partnerName}</span>
        </div>
      </div>
    );
  }

  async function handleGenerateCode() {
    setGenerating(true);
    const result = await generateInviteCode();
    if (result.inviteCode) {
      setInviteCode(result.inviteCode);
    }
    setGenerating(false);
  }

  async function handleCopy() {
    if (!inviteCode) return;
    await navigator.clipboard.writeText(inviteCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  return (
    <div className="rounded-xl bg-white p-6 shadow-sm">
      <h2 className="text-lg font-semibold text-secondary-foreground">
        Vincular parceiro
      </h2>

      <div className="mt-4 space-y-4">
        {/* Generate invite code */}
        <div>
          <p className="text-sm text-muted-foreground">
            Gere um código e envie para seu parceiro(a):
          </p>
          {inviteCode ? (
            <div className="mt-2 flex items-center gap-2">
              <code className="rounded-lg bg-secondary px-4 py-2 text-lg font-mono font-bold tracking-widest text-primary">
                {inviteCode}
              </code>
              <Button variant="ghost" size="sm" onClick={handleCopy}>
                {copied ? "Copiado!" : "Copiar"}
              </Button>
            </div>
          ) : (
            <Button
              variant="secondary"
              size="sm"
              className="mt-2"
              loading={generating}
              onClick={handleGenerateCode}
            >
              Gerar código
            </Button>
          )}
        </div>

        {/* Link with partner's code */}
        <div className="border-t border-muted pt-4">
          <p className="text-sm text-muted-foreground">
            Ou insira o código do seu parceiro(a):
          </p>
          <form action={linkAction} className="mt-2 flex gap-2">
            <Input
              id="invite_code"
              name="invite_code"
              placeholder="ABC123"
              className="font-mono uppercase"
              error={linkState.error}
            />
            <Button type="submit" size="md" loading={linkPending}>
              Vincular
            </Button>
          </form>
          {linkState.success && (
            <p className="mt-2 text-sm text-success">Parceiro vinculado com sucesso!</p>
          )}
        </div>
      </div>
    </div>
  );
}
