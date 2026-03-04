import { create } from "zustand";

interface AppState {
  currentMonth: string;
  setCurrentMonth: (month: string) => void;
}

function getCurrentMonth(): string {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
}

export const useAppStore = create<AppState>((set) => ({
  currentMonth: getCurrentMonth(),
  setCurrentMonth: (month) => set({ currentMonth: month }),
}));
