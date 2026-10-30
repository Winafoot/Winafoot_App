"use client";
import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import type { ColumnDef } from "@tanstack/react-table";
import { Trash2, UserPlus } from "lucide-react";
import Link from "next/link";
import { BulkDeleteDialog } from "@/components/bulk-delete-dialog";
import { DataTable } from "@/components/data-table";
import { PageHeader } from "@/components/page-header";
import { Alert } from "@/components/ui/alert";
import { CoachStatusBadge, SubscriptionBadge } from "@/components/coach-badges";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useCoaches, type Coach } from "@/lib/data";
import { TEAM_CATEGORIES, TEAM_FORMATS } from "@/lib/team-options";
import { formatDate, toDate } from "@/lib/utils";

type StatusFilter = "all" | "active" | "disabled" | "incomplete";

export default function CoachesPage() {
  const router = useRouter();
  const { data, loading, error } = useCoaches();
  const [status, setStatus] = useState<StatusFilter>("all");
  const [selected, setSelected] = useState<Coach[]>([]);
  const [deleting, setDeleting] = useState(false);
  // Changer la clé remonte le tableau : la sélection repart de zéro (changement de filtre, fin d'une suppression).
  const [tableKey, setTableKey] = useState(0);
  const resetSelection = () => {
    setSelected([]);
    setTableKey((k) => k + 1);
  };

  const rows = useMemo(
    () =>
      data.filter((c) => {
        if (status === "disabled") return c.disabled === true;
        if (status === "incomplete") return c.profilCompleted === false && !c.disabled;
        if (status === "active") return !c.disabled && c.profilCompleted !== false;
        return true;
      }),
    [data, status],
  );

  const columns = useMemo<ColumnDef<Coach, unknown>[]>(
    () => [
      {
        id: "name",
        header: "Coach",
        accessorFn: (c) => `${c.coachName ?? c.firstname ?? ""} ${c.email ?? ""}`.trim(),
        cell: ({ row }) => (
          <div className="min-w-0">
            <p className="truncate font-medium">{row.original.coachName ?? row.original.firstname ?? "—"}</p>
            <p className="truncate text-xs text-muted-foreground">{row.original.email}</p>
          </div>
        ),
      },
      { id: "team", header: "Équipe", accessorFn: (c) => c.teamName ?? "", cell: ({ row }) => row.original.teamName ?? "—" },
      {
        id: "category",
        header: "Catégorie",
        accessorFn: (c) => TEAM_CATEGORIES[c.category ?? ""] ?? c.category ?? "",
        cell: ({ getValue }) => (getValue() as string) || "—",
      },
      {
        id: "format",
        header: "Format",
        accessorFn: (c) => c.teamFormat ?? 0,
        cell: ({ row }) => (row.original.teamFormat ? `Foot à ${row.original.teamFormat}` : "—"),
      },
      { id: "status", header: "Statut", enableSorting: false, accessorFn: () => "", cell: ({ row }) => <CoachStatusBadge coach={row.original} /> },
      {
        id: "subscription",
        header: "Abonnement",
        accessorFn: (c) => c.subscription?.status ?? "",
        cell: ({ row }) => <SubscriptionBadge coach={row.original} />,
      },
      {
        id: "createdAt",
        header: "Créé le",
        accessorFn: (c) => toDate(c.createdAt)?.getTime() ?? 0,
        cell: ({ row }) => formatDate(row.original.createdAt),
      },
    ],
    [],
  );

  return (
    <>
      <PageHeader
        title="Coachs"
        description="Comptes coach de l'application. Cliquez sur une ligne pour ouvrir la fiche."
        actions={
          <Button asChild>
            <Link href="/creer-coach/">
              <UserPlus /> Créer un coach
            </Link>
          </Button>
        }
      />
      {error && <Alert variant="destructive" className="mb-4">Lecture impossible : {error.message}</Alert>}
      <DataTable
        key={tableKey}
        selectable
        getRowId={(c) => c.id}
        onSelectionChange={setSelected}
        columns={columns}
        data={rows}
        loading={loading}
        searchPlaceholder="Rechercher un coach, une équipe…"
        emptyMessage="Aucun coach ne correspond."
        initialSorting={[{ id: "createdAt", desc: true }]}
        onRowClick={(c) => router.push(`/coachs/detail/?uid=${encodeURIComponent(c.id)}`)}
        toolbar={
          <>
          <Select
            value={status}
            onValueChange={(v) => {
              setStatus(v as StatusFilter);
              resetSelection();
            }}
          >
            <SelectTrigger className="w-44" aria-label="Filtrer par statut">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Tous les statuts</SelectItem>
              <SelectItem value="active">Actifs</SelectItem>
              <SelectItem value="incomplete">Profil incomplet</SelectItem>
              <SelectItem value="disabled">Désactivés</SelectItem>
            </SelectContent>
          </Select>
          {selected.length > 0 && (
            <Button variant="destructive" onClick={() => setDeleting(true)}>
              <Trash2 /> Supprimer la sélection ({selected.length})
            </Button>
          )}
          </>
        }
      />
      <BulkDeleteDialog
        open={deleting}
        coaches={selected}
        onClose={() => setDeleting(false)}
        onFinished={resetSelection}
      />
      <p className="mt-3 text-xs text-muted-foreground">
        Formats : {TEAM_FORMATS.map((f) => f.label.split(" — ")[0]).join(", ")}.
      </p>
    </>
  );
}
