import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export const cn = (...inputs: ClassValue[]) => twMerge(clsx(inputs));

const dateTime = new Intl.DateTimeFormat("fr-FR", { dateStyle: "short", timeStyle: "short" });
const dateOnly = new Intl.DateTimeFormat("fr-FR", { dateStyle: "medium" });

/** Accepte un Timestamp Firestore, une Date ou une chaîne ISO ; « — » si la valeur est absente ou invalide. */
export function toDate(value: unknown): Date | null {
  if (value == null) return null;
  if (value instanceof Date) return value;
  if (typeof value === "object" && "toDate" in (value as object)) return (value as { toDate: () => Date }).toDate();
  if (typeof value === "string" || typeof value === "number") {
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  return null;
}
export const formatDateTime = (value: unknown) => {
  const d = toDate(value);
  return d ? dateTime.format(d) : "—";
};
export const formatDate = (value: unknown) => {
  const d = toDate(value);
  return d ? dateOnly.format(d) : "—";
};
export const formatNumber = (n: number) => new Intl.NumberFormat("fr-FR").format(n);
