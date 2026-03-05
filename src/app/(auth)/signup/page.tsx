"use client";

import { useActionState } from "react";
import Link from "next/link";
import { signupAction, type AuthActionState } from "@/actions/auth";
import { Button, Input } from "@/components/ui";

const initialState: AuthActionState = {};

export default function SignupPage() {
  const [state, formAction, pending] = useActionState(signupAction, initialState);

  if (state.success) {
    return (
      <div className="rounded-xl bg-white p-8 shadow-sm text-center">
        <h1 className="text-2xl font-bold text-primary">Karen</h1>
        <div className="mt-6">
          <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-success/10">
            <svg className="h-6 w-6 text-success" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <p className="text-sm text-muted-foreground">{state.error}</p>
        </div>
        <Link
          href="/login"
          className="mt-4 inline-block text-sm text-primary hover:underline"
        >
          Voltar ao login
        </Link>
      </div>
    );
  }

  return (
    <div className="rounded-xl bg-white p-8 shadow-sm">
      <div className="mb-6 text-center">
        <h1 className="text-2xl font-bold text-primary">Karen</h1>
        <p className="mt-1 text-sm text-muted-foreground">Crie sua conta</p>
      </div>

      <form action={formAction} className="space-y-4">
        <Input
          id="display_name"
          name="display_name"
          type="text"
          label="Nome"
          placeholder="Seu nome"
          autoComplete="name"
          required
          error={state.fieldErrors?.display_name?.[0]}
        />

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
          placeholder="Mínimo 6 caracteres"
          autoComplete="new-password"
          required
          error={state.fieldErrors?.password?.[0]}
        />

        <div className="space-y-1">
          <label
            htmlFor="salary"
            className="block text-sm font-medium text-secondary-foreground"
          >
            Salário mensal
          </label>
          <div className="relative">
            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm text-muted-foreground">
              R$
            </span>
            <input
              id="salary"
              name="salary"
              type="number"
              step="0.01"
              min="0"
              placeholder="0,00"
              required
              className="flex h-10 w-full rounded-lg border border-muted bg-white pl-10 pr-3 py-2 text-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
            />
          </div>
          {state.fieldErrors?.salary?.[0] && (
            <p className="text-sm text-destructive">{state.fieldErrors.salary[0]}</p>
          )}
        </div>

        {state.error && !state.success && (
          <p className="text-sm text-destructive">{state.error}</p>
        )}

        <Button type="submit" loading={pending} className="w-full">
          Cadastrar
        </Button>
      </form>

      <div className="mt-4 text-center text-sm">
        <Link href="/login" className="text-muted-foreground hover:text-primary">
          Já tem conta? <span className="font-medium text-primary">Entrar</span>
        </Link>
      </div>
    </div>
  );
}
