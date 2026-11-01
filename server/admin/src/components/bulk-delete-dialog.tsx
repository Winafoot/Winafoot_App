"use client";
import { useRef, useState } from "react";
import { Trash2 } from "lucide-react";
import { toast } from "sonner";
import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { deleteCoach, errorMessage } from "@/lib/callables";
import type { Coach } from "@/lib/data";

const CONFIRM_WORD = "SUPPRIMER";
const PREVIEW = 8;

interface Failure {
  coach: Coach;
  message: string;
}

const labelOf = (c: Coach) => c.teamName ?? c.email ?? c.id;

/**
 * Suppression définitive de plusieurs coachs. Un par un : `deleteCoach` archive, supprime les données et le compte
 * Auth, et le serveur limite ses instances. Chaque suppression est journalisée par le serveur. Un échec n'arrête pas
 * les suivantes, il est listé à la fin.
 */
export function BulkDeleteDialog({
  open,
  coaches,
  onClose,
  onFinished,
}: {
  open: boolean;
  coaches: Coach[];
  onClose: () => void;
  /** Appelé quand le traitement est terminé (même avec des échecs) : la page remet la sélection à zéro. */
  onFinished: () => void;
}) {
  const [typed, setTyped] = useState("");
  const [running, setRunning] = useState(false);
  const [done, setDone] = useState(0);
  const [failures, setFailures] = useState<Failure[]>([]);
  const [finished, setFinished] = useState(false);
  const stopRequested = useRef(false);

  const reset = () => {
    setTyped("");
    setDone(0);
    setFailures([]);
    setFinished(false);
    stopRequested.current = false;
  };

  const close = () => {
    if (running) return;
    const wasFinished = finished;
    reset();
    onClose();
    if (wasFinished) onFinished();
  };

  const run = async () => {
    setRunning(true);
    stopRequested.current = false;
    const failed: Failure[] = [];
    let count = 0;
    for (const coach of coaches) {
      if (stopRequested.current) break;
      try {
        await deleteCoach({ uid: coach.id });
      } catch (e) {
        failed.push({ coach, message: errorMessage(e, "Suppression impossible.") });
      }
      count += 1;
      setDone(count);
    }
    setFailures(failed);
    setRunning(false);
    setFinished(true);
    const ok = count - failed.length;
    if (failed.length === 0) toast.success(`${ok} compte${ok > 1 ? "s" : ""} supprimé${ok > 1 ? "s" : ""}.`);
    else toast.warning(`${ok} supprimé${ok > 1 ? "s" : ""}, ${failed.length} en échec.`);
  };

  const total = coaches.length;
  const ready = typed === CONFIRM_WORD && total > 0;
  const stopped = finished && done < total;

  return (
    <Dialog open={open} onOpenChange={(next) => !next && close()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>
            {finished ? "Suppression terminée" : `Supprimer définitivement ${total} compte${total > 1 ? "s" : ""} ?`}
          </DialogTitle>
          <DialogDescription asChild>
            <div>
              {finished
                ? `${done - failures.length} sur ${total} supprimé${done - failures.length > 1 ? "s" : ""}.`
                : "Cette suppression est irréversible : pour chaque compte, le profil, les joueurs, les matchs et les compositions seront perdus."}
            </div>
          </DialogDescription>
        </DialogHeader>

        {!finished && (
          <>
            <ul className="max-h-40 overflow-auto rounded-md border p-2 text-sm">
              {coaches.slice(0, PREVIEW).map((c) => (
                <li key={c.id} className="truncate py-0.5">
                  {labelOf(c)} <span className="text-muted-foreground">· {c.email}</span>
                </li>
              ))}
              {total > PREVIEW && <li className="py-0.5 text-muted-foreground">… et {total - PREVIEW} autre{total - PREVIEW > 1 ? "s" : ""}</li>}
            </ul>

            {running ? (
              <div className="grid gap-2" role="status" aria-live="polite">
                <div className="h-2 overflow-hidden rounded-full bg-muted">
                  <div className="h-full rounded-full bg-destructive transition-all" style={{ width: `${(done / total) * 100}%` }} />
                </div>
                <p className="text-sm text-muted-foreground">
                  {done} / {total} traité{done > 1 ? "s" : ""}…
                </p>
              </div>
            ) : (
              <div className="grid gap-2">
                <p className="text-sm">
                  Tapez <strong className="select-all">{CONFIRM_WORD}</strong> pour confirmer.
                </p>
                <Input value={typed} onChange={(e) => setTyped(e.target.value)} autoComplete="off" />
              </div>
            )}
          </>
        )}

        {finished && stopped && <Alert variant="warning">Arrêté avant la fin : {total - done} compte(s) n&apos;ont pas été traités.</Alert>}
        {finished && failures.length > 0 && (
          <Alert variant="destructive">
            <p className="mb-1 font-medium">{failures.length} échec{failures.length > 1 ? "s" : ""} :</p>
            <ul className="max-h-40 list-disc overflow-auto pl-5">
              {failures.map((f) => (
                <li key={f.coach.id}>
                  {labelOf(f.coach)} : {f.message}
                </li>
              ))}
            </ul>
          </Alert>
        )}

        <DialogFooter>
          {running ? (
            <Button variant="outline" onClick={() => (stopRequested.current = true)}>
              Arrêter après le compte en cours
            </Button>
          ) : finished ? (
            <Button onClick={close}>Fermer</Button>
          ) : (
            <>
              <Button variant="outline" onClick={close}>
                Annuler
              </Button>
              <Button variant="destructive" onClick={run} disabled={!ready}>
                <Trash2 /> Supprimer {total} compte{total > 1 ? "s" : ""}
              </Button>
            </>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
