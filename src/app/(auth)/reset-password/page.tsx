"use client";

import { useActionState } from "react";
import { resetPasswordAction, type AuthActionState } from "@/actions/auth";
import { Button, Input } from "@/components/ui";

const initialState: AuthActionState = {};

export default function ResetPasswordPage() {
  const [state, formAction, pending] = useActionState(
    resetPasswordAction,
    initialState
  );

  return (
    <div className="rounded-xl bg-white p-8 shadow-sm">
      <div className="mb-6 text-center">
        <h1 className="text-2xl font-bold text-primary">Karen</h1>
        <p className="mt-1 text-sm text-muted-foreground">Redefinir senha</p>
      </div>

      <form action={formAction} className="space-y-4">
        <Input
          id="password"
          name="password"
          type="password"
          label="Nova senha"
          placeholder="Mínimo 6 caracteres"
          autoComplete="new-password"
          required
          error={state.fieldErrors?.password?.[0]}
        />

        <Input
          id="confirmPassword"
          name="confirmPassword"
          type="password"
          label="Confirmar senha"
          placeholder="Repita a senha"
          autoComplete="new-password"
          required
          error={state.fieldErrors?.confirmPassword?.[0]}
        />

        {state.error && (
          <p className="text-sm text-destructive">{state.error}</p>
        )}

        <Button type="submit" loading={pending} className="w-full">
          Redefinir senha
        </Button>
      </form>
    </div>
  );
}
