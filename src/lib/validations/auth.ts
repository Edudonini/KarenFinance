import { z } from "zod";

export const LoginSchema = z.object({
  email: z.email("Email inválido"),
  password: z.string().min(6, "Senha deve ter pelo menos 6 caracteres"),
});

export const SignupSchema = z.object({
  display_name: z.string().min(2, "Nome deve ter pelo menos 2 caracteres"),
  email: z.email("Email inválido"),
  password: z.string().min(6, "Senha deve ter pelo menos 6 caracteres"),
  salary: z.number().int().nonnegative("Salário deve ser positivo"),
});

export const ForgotPasswordSchema = z.object({
  email: z.email("Email inválido"),
});

export const ResetPasswordSchema = z
  .object({
    password: z.string().min(6, "Senha deve ter pelo menos 6 caracteres"),
    confirmPassword: z.string().min(6, "Confirme a senha"),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Senhas não coincidem",
    path: ["confirmPassword"],
  });
