"use client";

import { useActionState } from "react";
import Link from "next/link";
import { forgotPasswordAction, type AuthActionState } from "@/actions/auth";
import { Button, Input } from "@/components/ui";

const initialState: AuthActionState = {};

export default function ForgotPasswordPage() {
  const [state, formAction, pending] = useActionState(
    forgotPasswordAction,
    initialState
  );

  return (
    <div className="rounded-xl bg-white p-8 shadow-sm">
      <div className="mb-6 text-center">
        <h1 className="text-2xl font-bold text-primary">Karen</h1>
        <p className="mt-1 text-sm text-muted-foreground">Recuperar senha</p>
      </div>

      {state.success ? (
        <div className="text-center">
          <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-success/10">
            <svg className="h-6 w-6 text-success" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <p className="text-sm text-muted-foreground">
            Se o email existir em nossa base, enviamos um link de recuperação.
          </p>
        </div>
      ) : (
        <form action={formAction} className="space-y-4">
          <Input
            id="email"
            name="email"
            type="email"
            label="Email"
            placeholder="seu@email.com"
            autoComplete="email"
            required
            error={state.fieldErrors?.email?.[0]}
          />

          {state.error && (
            <p className="text-sm text-destructive">{state.error}</p>
          )}

          <Button type="submit" loading={pending} className="w-full">
            Enviar link
          </Button>
        </form>
      )}

      <div className="mt-4 text-center">
        <Link href="/login" className="text-sm text-primary hover:underline">
          Voltar ao login
        </Link>
      </div>
    </div>
  );
}
