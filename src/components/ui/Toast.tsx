"use client";

import { cn } from "@/lib/utils";
import { useToastStore } from "@/stores/toast-store";

export default function Toast() {
  const { toasts, removeToast } = useToastStore();

  if (toasts.length === 0) return null;

  return (
    <div className="fixed bottom-4 right-4 z-50 flex flex-col gap-2">
      {toasts.map((toast) => (
        <div
          key={toast.id}
          className={cn(
            "flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium text-white shadow-lg transition-all",
            {
              "bg-success": toast.type === "success",
              "bg-destructive": toast.type === "error",
              "bg-primary": toast.type === "info",
            }
          )}
          role="alert"
        >
          <span className="flex-1">{toast.message}</span>
          <button
            onClick={() => removeToast(toast.id)}
            className="ml-2 rounded-md p-1 hover:bg-white/20"
            aria-label="Fechar"
          >
            <svg
              className="h-4 w-4"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      ))}
    </div>
  );
}
