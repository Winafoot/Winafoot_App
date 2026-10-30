"use client";
import { useMemo, useState } from "react";
import type { ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/data-table";
import { PageHeader } from "@/components/page-header";
import { Alert } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { AUDIT_ACTIONS, useAudit, type AuditEntry } from "@/lib/data";
import { formatDateTime, toDate } from "@/lib/utils";

export default function AuditPage() {
  const { data, loading, error } = useAudit(300);
  const [outcome, setOutcome] = useState<"all" | "success" | "failure">("all");
  const rows = useMemo(() => data.filter((e) => outcome === "all" || e.outcome === outcome), [data, outcome]);

  const columns = useMemo<ColumnDef<AuditEntry, unknown>[]>(
    () => [
      { id: "at", header: "Date", accessorFn: (e) => toDate(e.at)?.getTime() ?? 0, cell: ({ row }) => formatDateTime(row.original.at) },
      {
        id: "action",
        header: "Action",
        accessorFn: (e) => AUDIT_ACTIONS[e.action] ?? e.action,
        cell: ({ getValue }) => <span className="font-medium">{getValue() as string}</span>,
      },
      { id: "target", header: "Compte concerné", accessorFn: (e) => e.targetEmail ?? e.targetUid ?? "", cell: ({ getValue }) => (getValue() as string) || "—" },
      { id: "admin", header: "Administrateur", accessorFn: (e) => e.adminEmail ?? e.adminUid ?? "", cell: ({ getValue }) => (getValue() as string) || "—" },
      {
        id: "outcome",
        header: "Résultat",
        accessorFn: (e) => e.outcome,
        cell: ({ row }) =>
          row.original.outcome === "success" ? (
            <Badge>Succès</Badge>
          ) : (
            <Badge variant="destructive" title={row.original.error ?? undefined}>
              Échec
            </Badge>
          ),
      },
      {
        id: "details",
        header: "Détail",
        enableSorting: false,
        accessorFn: (e) => e.error ?? e.details ?? "",
        cell: ({ getValue }) => <span className="text-muted-foreground">{(getValue() as string) || "—"}</span>,
      },
    ],
    [],
  );

  return (
    <>
      <PageHeader title="Journal d'audit" description="Actions effectuées depuis le back-office, réussies ou refusées. Les 300 plus récentes." />
      {error && <Alert variant="destructive" className="mb-4">Lecture impossible : {error.message}</Alert>}
      <DataTable
        columns={columns}
        data={rows}
        loading={loading}
        searchPlaceholder="Rechercher dans le journal…"
        emptyMessage="Aucune entrée."
        pageSize={25}
        initialSorting={[{ id: "at", desc: true }]}
        toolbar={
          <Select value={outcome} onValueChange={(v) => setOutcome(v as typeof outcome)}>
            <SelectTrigger className="w-40" aria-label="Filtrer par résultat">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Tous</SelectItem>
              <SelectItem value="success">Succès</SelectItem>
              <SelectItem value="failure">Échecs</SelectItem>
            </SelectContent>
          </Select>
        }
      />
    </>
  );
}
