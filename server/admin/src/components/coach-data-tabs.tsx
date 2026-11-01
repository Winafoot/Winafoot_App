"use client";
import { useState } from "react";
import { Eye } from "lucide-react";
import { toast } from "sonner";
import { Alert } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { errorMessage, getCoachData, type CoachData } from "@/lib/callables";
import { formatDateTime } from "@/lib/utils";

type Row = Record<string, unknown>;

const text = (v: unknown): string => (v == null || v === "" ? "—" : String(v));
const nested = (row: Row, key: string, sub: string): unknown => (row[key] as Row | undefined)?.[sub];

function Empty({ children }: { children: React.ReactNode }) {
  return <p className="py-8 text-center text-sm text-muted-foreground">{children}</p>;
}

function Players({ rows }: { rows: Row[] }) {
  if (rows.length === 0) return <Empty>Aucun joueur.</Empty>;
  return (
    <Table>
      <TableHeader>
        <TableRow className="hover:bg-transparent">
          <TableHead>Joueur</TableHead>
          <TableHead>Poste</TableHead>
          <TableHead>Pied fort</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {rows.map((p) => (
          <TableRow key={String(p.id)}>
            <TableCell className="font-medium">
              {text(p.firstName)} {text(p.lastName)}
            </TableCell>
            <TableCell>{text(p.position)}</TableCell>
            <TableCell>{text(p.strongFoot)}</TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}

function Matches({ rows }: { rows: Row[] }) {
  if (rows.length === 0) return <Empty>Aucun match.</Empty>;
  return (
    <Table>
      <TableHeader>
        <TableRow className="hover:bg-transparent">
          <TableHead>Adversaire</TableHead>
          <TableHead>Statut</TableHead>
          <TableHead>Score</TableHead>
          <TableHead>Créé le</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {rows.map((m) => (
          <TableRow key={String(m.id)}>
            <TableCell className="font-medium">{text(nested(m, "opponent", "name"))}</TableCell>
            <TableCell>
              <Badge variant="secondary">{text(m.status)}</Badge>
            </TableCell>
            <TableCell className="tabular-nums">{m.scoreUs == null ? "—" : `${m.scoreUs} - ${m.scoreThem ?? 0}`}</TableCell>
            <TableCell>{formatDateTime(m.createdAt)}</TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}

function Compositions({ rows }: { rows: Row[] }) {
  if (rows.length === 0) return <Empty>Aucune composition.</Empty>;
  return (
    <Table>
      <TableHeader>
        <TableRow className="hover:bg-transparent">
          <TableHead>Nom</TableHead>
          <TableHead>Schéma</TableHead>
          <TableHead>Joueurs</TableHead>
          <TableHead>Favori</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {rows.map((c) => (
          <TableRow key={String(c.id)}>
            <TableCell className="font-medium">{text(c.name)}</TableCell>
            <TableCell>{text(c.formationLabel)}</TableCell>
            <TableCell>{text(c.playerCount)}</TableCell>
            <TableCell>{c.isFavorite ? "Oui" : "—"}</TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}

function LinkedTeams({ rows }: { rows: Row[] }) {
  if (rows.length === 0) return <Empty>Aucune équipe liée.</Empty>;
  return (
    <Table>
      <TableHeader>
        <TableRow className="hover:bg-transparent">
          <TableHead>Équipe</TableHead>
          <TableHead>Identifiant</TableHead>
          <TableHead>N°</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {rows.map((t) => (
          <TableRow key={String(t.id)}>
            <TableCell className="font-medium">{text(t.teamName)}</TableCell>
            <TableCell>{text(t.email).replace(/@equipes\.wina\.invalid$/, "")}</TableCell>
            <TableCell>{text(t.teamIndex)}</TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}

/**
 * Données de l'app d'un coach. Elles ne se chargent qu'à la demande : l'accès est tracé dans le journal d'audit
 * (effectif, parfois des mineurs), et les règles Firestore ne les ouvrent pas aux administrateurs côté client.
 */
export function CoachDataTabs({ uid }: { uid: string }) {
  const [data, setData] = useState<CoachData>();
  const [loading, setLoading] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      setData(await getCoachData({ uid }));
    } catch (e) {
      toast.error(errorMessage(e, "Chargement impossible."));
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card className="mt-4">
      <CardHeader>
        <CardTitle>Données de l&apos;équipe</CardTitle>
        <CardDescription>Effectif, matchs, compositions et équipes liées (lecture seule).</CardDescription>
      </CardHeader>
      <CardContent>
        {!data ? (
          <div className="grid justify-items-start gap-3">
            <p className="text-sm text-muted-foreground">
              Ces données concernent des joueurs. Leur consultation est enregistrée dans le journal d&apos;audit.
            </p>
            <Button variant="outline" onClick={load} loading={loading}>
              <Eye /> Afficher les données
            </Button>
          </div>
        ) : (
          <>
            {data.truncated && <Alert variant="warning" className="mb-4">Affichage limité à {data.limit} entrées par liste.</Alert>}
            <Tabs defaultValue="players">
              <TabsList>
                <TabsTrigger value="players">Joueurs ({data.players.length})</TabsTrigger>
                <TabsTrigger value="matches">Matchs ({data.matches.length})</TabsTrigger>
                <TabsTrigger value="compositions">Compositions ({data.compositions.length})</TabsTrigger>
                <TabsTrigger value="linked">Équipes liées ({data.linkedTeams.length})</TabsTrigger>
              </TabsList>
              <TabsContent value="players">
                <Players rows={data.players} />
              </TabsContent>
              <TabsContent value="matches">
                <Matches rows={data.matches} />
              </TabsContent>
              <TabsContent value="compositions">
                <Compositions rows={data.compositions} />
              </TabsContent>
              <TabsContent value="linked">
                <LinkedTeams rows={data.linkedTeams} />
              </TabsContent>
            </Tabs>
          </>
        )}
      </CardContent>
    </Card>
  );
}
