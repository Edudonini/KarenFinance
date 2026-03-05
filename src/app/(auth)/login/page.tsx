"use client";

import { useActionState } from "react";
import Link from "next/link";
import { loginAction, type AuthActionState } from "@/actions/auth";
import { Button, Input } from "@/components/ui";

const initialState: AuthActionState = {};

export default function LoginPage() {
  const [state, formAction, pending] = useActionState(loginAction, initialState);

  return (
    <div className="rounded-xl bg-white p-8 shadow-sm">
      <div className="mb-6 text-center">
        <h1 className="text-2xl font-bold text-primary">Karen</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Gestão financeira para casais
        </p>
      </div>

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

        <Input
          id="password"
          name="password"
          type="password"
          label="Senha"
          placeholder="••••••"
          autoComplete="current-password"
          required
          error={state.fieldErrors?.password?.[0]}
        />

        {state.error && (
          <p className="text-sm text-destructive">{state.error}</p>
        )}

        <Button type="submit" loading={pending} className="w-full">
          Entrar
        </Button>
      </form>

      <div className="mt-4 flex flex-col items-center gap-2 text-sm">
        <Link
          href="/forgot-password"
          className="text-primary hover:underline"
        >
          Esqueci minha senha
        </Link>
        <Link href="/signup" className="text-muted-foreground hover:text-primary">
          Não tem conta? <span className="font-medium text-primary">Cadastre-se</span>
        </Link>
      </div>
    </div>
  );
}
