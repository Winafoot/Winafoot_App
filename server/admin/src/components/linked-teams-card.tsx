"use client";
import { useState } from "react";
import { Copy, KeyRound, Wand2 } from "lucide-react";
import { toast } from "sonner";
import { Alert } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { errorMessage, resetLinkedTeamPasswordByAdmin } from "@/lib/callables";
import { useLinkedTeams, type Coach } from "@/lib/data";
import { passwordPolicyViolations } from "@/lib/password-policy";
import { formatDate } from "@/lib/utils";

const LOWER = "abcdefghijkmnopqrstuvwxyz";
const UPPER = "ABCDEFGHJKLMNPQRSTUVWXYZ";
const DIGITS = "23456789";
const SPECIAL = "!@#%&*?";

const pick = (chars: string) => chars[crypto.getRandomValues(new Uint32Array(1))[0] % chars.length];

/** Mot de passe aléatoire de 12 caractères conforme à la politique du projet (sans caractères ambigus : 0/O, 1/l/I). */
function generatePassword(): string {
  const all = LOWER + UPPER + DIGITS + SPECIAL;
  const chars = [pick(LOWER), pick(UPPER), pick(DIGITS), pick(SPECIAL), ...Array.from({ length: 8 }, () => pick(all))];
  // Mélange de Fisher-Yates : les quatre caractères imposés ne restent pas en tête.
  for (let i = chars.length - 1; i > 0; i--) {
    const j = crypto.getRandomValues(new Uint32Array(1))[0] % (i + 1);
    [chars[i], chars[j]] = [chars[j], chars[i]];
  }
  return chars.join("");
}

const identifierOf = (team: Coach) => (team.email ?? "").replace(/@.*$/, "");

function ResetDialog({ team, onClose }: { team: Coach; onClose: () => void }) {
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState<string>();
  const missing = passwordPolicyViolations(password);

  const submit = async () => {
    setBusy(true);
    try {
      await resetLinkedTeamPasswordByAdmin({ uid: team.id, password });
      setDone(password);
      toast.success("Mot de passe redéfini.");
    } catch (e) {
      toast.error(errorMessage(e, "La réinitialisation a échoué."));
    } finally {
      setBusy(false);
    }
  };

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(`Identifiant : ${identifierOf(team)}\nMot de passe : ${done ?? password}`);
      toast.success("Identifiants copiés.");
    } catch {
      toast.error("Copie impossible : sélectionnez le texte à la main.");
    }
  };

  return (
    <Dialog open onOpenChange={(open) => !open && !busy && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Réinitialiser le mot de passe</DialogTitle>
          <DialogDescription>
            Équipe {team.teamName ?? "—"} · identifiant <code className="select-all">{identifierOf(team)}</code>. Les sessions ouvertes de ce compte sont coupées.
          </DialogDescription>
        </DialogHeader>

        {done == null ? (
          <>
            <div className="grid gap-2">
              <Label htmlFor="linked-password">Nouveau mot de passe</Label>
              <div className="flex gap-2">
                <Input id="linked-password" autoComplete="off" value={password} onChange={(e) => setPassword(e.target.value)} disabled={busy} className="font-mono" />
                <Button type="button" variant="outline" onClick={() => setPassword(generatePassword())} disabled={busy}>
                  <Wand2 /> Générer
                </Button>
              </div>
              <p className={password.length > 0 && missing.length > 0 ? "text-sm text-destructive" : "text-sm text-muted-foreground"}>
                {password.length > 0 && missing.length > 0 ? `Il manque : ${missing.join(", ")}.` : "Au moins 6 caractères, avec une minuscule, une majuscule, un chiffre et un caractère spécial."}
              </p>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={onClose} disabled={busy}>
                Annuler
              </Button>
              <Button onClick={submit} loading={busy} disabled={missing.length > 0}>
                Redéfinir
              </Button>
            </DialogFooter>
          </>
        ) : (
          <>
            <Alert variant="success">
              Mot de passe redéfini. Transmettez-le au coach : il ne sera plus affiché une fois cette fenêtre fermée.
            </Alert>
            <div className="rounded-md bg-muted p-3 font-mono text-sm">
              <p>Identifiant : {identifierOf(team)}</p>
              <p>Mot de passe : {done}</p>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={copy}>
                <Copy /> Copier
              </Button>
              <Button onClick={onClose}>Fermer</Button>
            </DialogFooter>
          </>
        )}
      </DialogContent>
    </Dialog>
  );
}

/** Équipes rattachées à un compte propriétaire (formules à 2 ou 3 équipes) : quota utilisé et identifiants. */
export function LinkedTeamsCard({ owner }: { owner: Coach }) {
  const { data: teams, loading, error } = useLinkedTeams(owner.id);
  const [resetting, setResetting] = useState<Coach | null>(null);

  const allowed = owner.subscription?.teamsAllowed;
  // Le compte propriétaire compte pour la première équipe.
  const used = teams.length + 1;

  // Rien à montrer pour un compte à une seule équipe et sans équipe liée.
  if (!loading && teams.length === 0 && (allowed == null || allowed <= 1)) return null;

  return (
    <Card className="mt-4">
      <CardHeader>
        <CardTitle className="flex items-center justify-between">
          Équipes liées
          {allowed != null && (
            <Badge variant={used >= allowed ? "secondary" : "default"}>
              {Math.min(used, allowed)} / {allowed} équipe{allowed > 1 ? "s" : ""} créée{used > 1 ? "s" : ""}
            </Badge>
          )}
        </CardTitle>
        <CardDescription>
          Une formule à plusieurs équipes donne un compte par équipe. Ces comptes n&apos;ont pas d&apos;e-mail : « Mot de passe oublié » ne les sert pas, c&apos;est ici
          qu&apos;on redéfinit leur mot de passe.
        </CardDescription>
      </CardHeader>
      <CardContent>
        {error ? (
          <Alert variant="destructive">Lecture impossible : {error.message}</Alert>
        ) : loading ? (
          <Skeleton className="h-16 w-full" />
        ) : teams.length === 0 ? (
          <p className="py-4 text-sm text-muted-foreground">Aucune équipe liée créée pour l&apos;instant.</p>
        ) : (
          <Table>
            <TableHeader>
              <TableRow className="hover:bg-transparent">
                <TableHead>Équipe</TableHead>
                <TableHead>Identifiant</TableHead>
                <TableHead>Accès</TableHead>
                <TableHead>Créée le</TableHead>
                <TableHead />
              </TableRow>
            </TableHeader>
            <TableBody>
              {teams.map((t) => (
                <TableRow key={t.id}>
                  <TableCell className="font-medium">{t.teamName ?? `Équipe ${t.teamIndex ?? ""}`}</TableCell>
                  <TableCell>
                    <code className="select-all text-xs">{identifierOf(t)}</code>
                  </TableCell>
                  <TableCell>{t.disabled ? <Badge variant="destructive">Désactivé</Badge> : t.access?.active ? <Badge>Actif</Badge> : <Badge variant="secondary">Inactif</Badge>}</TableCell>
                  <TableCell>{formatDate(t.createdAt)}</TableCell>
                  <TableCell className="text-right">
                    <Button variant="outline" size="sm" onClick={() => setResetting(t)}>
                      <KeyRound /> Mot de passe
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </CardContent>
      {resetting && <ResetDialog key={resetting.id} team={resetting} onClose={() => setResetting(null)} />}
    </Card>
  );
}
