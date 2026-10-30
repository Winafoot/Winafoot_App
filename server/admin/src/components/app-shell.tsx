"use client";
import { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useTheme } from "next-themes";
import {
  FileText,
  LayoutDashboard,
  Loader2,
  LogOut,
  Menu,
  Moon,
  ShieldCheck,
  Sun,
  UserPlus,
  Users,
  Wallet,
  X,
  type LucideIcon,
} from "lucide-react";
import { useAuth } from "@/lib/auth-provider";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { LoginScreen } from "@/components/login-screen";

interface NavItem {
  href: string;
  label: string;
  icon: LucideIcon;
}

const NAV: { title: string; items: NavItem[] }[] = [
  {
    title: "Pilotage",
    items: [
      { href: "/", label: "Tableau de bord", icon: LayoutDashboard },
      { href: "/coachs/", label: "Coachs", icon: Users },
      { href: "/abonnements/", label: "Abonnements", icon: Wallet },
    ],
  },
  {
    title: "Administration",
    items: [
      { href: "/creer-coach/", label: "Créer un coach", icon: UserPlus },
      { href: "/administrateurs/", label: "Administrateurs", icon: ShieldCheck },
      { href: "/audit/", label: "Journal d'audit", icon: FileText },
    ],
  },
];

function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme();
  return (
    <Button
      variant="ghost"
      size="icon"
      aria-label="Changer de thème"
      onClick={() => setTheme(resolvedTheme === "dark" ? "light" : "dark")}
    >
      <Sun className="size-4 dark:hidden" />
      <Moon className="hidden size-4 dark:block" />
    </Button>
  );
}

function isActive(pathname: string, href: string): boolean {
  if (href === "/") return pathname === "/";
  return pathname.startsWith(href.replace(/\/$/, ""));
}

function Sidebar({ onNavigate }: { onNavigate?: () => void }) {
  const pathname = usePathname();
  const { user, signOut } = useAuth();

  return (
    <div className="flex h-full flex-col gap-6 p-4">
      <Link href="/" onClick={onNavigate} className="flex items-center gap-3 px-2">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/favicon.png" alt="" className="size-8 rounded-lg" />
        <span className="font-semibold">Wina</span>
        <span className="rounded-full bg-primary/15 px-2 py-0.5 text-xs font-medium text-primary">Admin</span>
      </Link>

      <nav className="flex flex-1 flex-col gap-5 overflow-y-auto">
        {NAV.map((group) => (
          <div key={group.title} className="grid gap-1">
            <p className="px-2 text-xs font-medium uppercase tracking-wide text-muted-foreground">{group.title}</p>
            {group.items.map(({ href, label, icon: Icon }) => (
              <Link
                key={href}
                href={href}
                onClick={onNavigate}
                aria-current={isActive(pathname, href) ? "page" : undefined}
                className={cn(
                  "flex items-center gap-3 rounded-md px-2 py-2 text-sm transition-colors hover:bg-muted",
                  isActive(pathname, href) && "bg-primary/10 font-medium text-primary hover:bg-primary/15",
                )}
              >
                <Icon className="size-4" />
                {label}
              </Link>
            ))}
          </div>
        ))}
      </nav>

      <div className="grid gap-2 border-t pt-4">
        <Link
          href="/securite/"
          onClick={onNavigate}
          className={cn(
            "flex items-center gap-3 rounded-md px-2 py-2 text-sm hover:bg-muted",
            isActive(pathname, "/securite/") && "bg-primary/10 font-medium text-primary",
          )}
        >
          <ShieldCheck className="size-4" />
          Sécurité du compte
        </Link>
        <div className="flex items-center justify-between gap-2 px-2">
          <p className="min-w-0 truncate text-xs text-muted-foreground" title={user?.email ?? ""}>
            {user?.email}
          </p>
          <div className="flex shrink-0">
            <ThemeToggle />
            <Button variant="ghost" size="icon" aria-label="Se déconnecter" onClick={signOut}>
              <LogOut className="size-4" />
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}

/** Coquille du back-office : n'affiche les pages qu'à un administrateur connecté, sinon l'écran de connexion. */
export function AppShell({ children }: { children: React.ReactNode }) {
  const { status } = useAuth();
  const [open, setOpen] = useState(false);

  if (status === "loading") {
    return (
      <div className="flex min-h-screen items-center justify-center" role="status" aria-label="Chargement">
        <Loader2 className="size-6 animate-spin text-muted-foreground" />
      </div>
    );
  }
  if (status !== "ready") return <LoginScreen />;

  return (
    <div className="min-h-screen lg:grid lg:grid-cols-[260px_1fr]">
      <aside className="sticky top-0 hidden h-screen border-r bg-card lg:block">
        <Sidebar />
      </aside>

      <div className="flex min-w-0 flex-col">
        <header className="sticky top-0 z-30 flex h-14 items-center gap-3 border-b bg-background/90 px-4 backdrop-blur lg:hidden">
          <Button variant="ghost" size="icon" aria-label="Ouvrir le menu" onClick={() => setOpen(true)}>
            <Menu className="size-5" />
          </Button>
          <span className="font-semibold">Wina — Back-office</span>
        </header>

        {open && (
          <div className="fixed inset-0 z-40 lg:hidden">
            <button className="absolute inset-0 bg-black/50" aria-label="Fermer le menu" onClick={() => setOpen(false)} />
            <div className="relative h-full w-72 max-w-[85vw] bg-card shadow-xl">
              <Button variant="ghost" size="icon" className="absolute right-2 top-2" aria-label="Fermer" onClick={() => setOpen(false)}>
                <X className="size-4" />
              </Button>
              <Sidebar onNavigate={() => setOpen(false)} />
            </div>
          </div>
        )}

        <main className="mx-auto w-full max-w-6xl flex-1 p-4 sm:p-6 lg:p-8">{children}</main>
      </div>
    </div>
  );
}
