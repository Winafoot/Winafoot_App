"use client";
import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import type { ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/data-table";
import { PageHeader } from "@/components/page-header";
import { Alert } from "@/components/ui/alert";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { errorMessage, getAllPlayers, type PlayerRow } from "@/lib/callables";

const ALL = "all";
const NONE = "none";

/** Tous les joueurs de l'app, toutes équipes confondues, avec leurs totaux. Un clic ouvre la fiche de l'équipe sur ce joueur. */
export default function PlayersPage() {
  const router = useRouter();
  const [players, setPlayers] = useState<PlayerRow[] | null>(null);
  const [truncated, setTruncated] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [category, setCategory] = useState(ALL);

  useEffect(() => {
    getAllPlayers({})
      .then((r) => {
        setPlayers(r.players);
        setTruncated(r.truncated);
      })
      .catch((e) => setError(errorMessage(e, "Lecture des joueurs impossible.")));
  }, []);

  const categories = useMemo(() => [...new Set((players ?? []).map((p) => p.category))].sort(), [players]);
  const rows = useMemo(() => (players ?? []).filter((p) => category === ALL || p.category === (category === NONE ? "" : category)), [players, category]);

  const columns = useMemo<ColumnDef<PlayerRow, unknown>[]>(
    () => [
      { id: "name", header: "Joueur", accessorFn: (p) => `${p.name} ${p.teamName}`, cell: ({ row }) => <span className="font-medium">{row.original.name}</span> },
      { id: "team", header: "Équipe", accessorFn: (p) => p.teamName, cell: ({ row }) => row.original.teamName || "—" },
      { id: "category", header: "Catégorie", accessorFn: (p) => p.category, cell: ({ row }) => row.original.category || "—" },
      { id: "position", header: "Poste", accessorFn: (p) => p.position, cell: ({ row }) => row.original.position || "—" },
      { id: "matches", header: "Matchs", accessorFn: (p) => p.matches },
      { id: "goals", header: "Buts", accessorFn: (p) => p.goals },
      { id: "assists", header: "Passes déc.", accessorFn: (p) => p.assists },
      { id: "yellow", header: "Jaunes", accessorFn: (p) => p.yellowCards },
      { id: "red", header: "Rouges", accessorFn: (p) => p.redCards },
    ],
    [],
  );

  return (
    <>
      <PageHeader title="Joueurs" description="Tous les joueurs de l'application avec leurs statistiques. Cliquez sur une ligne pour ouvrir le détail du joueur dans la fiche de son équipe." />
      {error && <Alert variant="destructive" className="mb-4">{error}</Alert>}
      {truncated && <Alert className="mb-4">La liste est limitée à 5 000 joueurs et 5 000 matchs : certains joueurs ou statistiques manquent.</Alert>}
      <DataTable
        columns={columns}
        data={rows}
        loading={players == null && !error}
        searchPlaceholder="Rechercher un joueur, une équipe…"
        emptyMessage="Aucun joueur."
        initialSorting={[{ id: "goals", desc: true }]}
        getRowId={(p) => `${p.teamUid}/${p.id}`}
        onRowClick={(p) => router.push(`/equipes/detail/?uid=${encodeURIComponent(p.teamUid)}&player=${encodeURIComponent(p.id)}`)}
        toolbar={
          <Select value={category} onValueChange={setCategory}>
            <SelectTrigger className="w-48" aria-label="Filtrer par catégorie">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value={ALL}>Toutes les catégories</SelectItem>
              {categories.map((c) => (
                <SelectItem key={c || NONE} value={c || NONE}>
                  {c || "Sans catégorie"}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        }
      />
    </>
  );
}
