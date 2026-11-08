"use client";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { errorMessage, getCoachNote, setCoachNote, type CoachNote } from "@/lib/callables";
import { formatDateTime } from "@/lib/utils";

const MAX_LENGTH = 4000;

/** Note interne sur un coach (« remise accordée », « à rappeler »…) : visible des administrateurs uniquement. */
export function CoachNoteCard({ uid }: { uid: string }) {
  const [saved, setSaved] = useState<CoachNote | null>(null);
  const [text, setText] = useState("");
  const [busy, setBusy] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);

  useEffect(() => {
    getCoachNote({ uid })
      .then((note) => {
        setSaved(note);
        setText(note.text);
      })
      .catch((e) => setLoadError(errorMessage(e, "Lecture de la note impossible.")));
  }, [uid]);

  const save = async () => {
    setBusy(true);
    try {
      const note = await setCoachNote({ uid, text });
      setSaved(note);
      setText(note.text);
      toast.success(note.text === "" ? "Note effacée." : "Note enregistrée.");
    } catch (e) {
      toast.error(errorMessage(e, "Enregistrement impossible."));
    } finally {
      setBusy(false);
    }
  };

  const dirty = saved != null && text.trim() !== saved.text;
  return (
    <Card className="mb-6">
      <CardHeader>
        <CardTitle>Note interne</CardTitle>
        <CardDescription>Visible uniquement dans le back-office. Évitez les informations sensibles.</CardDescription>
      </CardHeader>
      <CardContent className="grid gap-3">
        {loadError ? (
          <p className="text-sm text-destructive">{loadError}</p>
        ) : (
          <>
            <textarea
              aria-label="Note interne"
              className="min-h-24 w-full rounded-md border bg-background px-3 py-2 text-sm shadow-xs outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:opacity-60"
              value={text}
              maxLength={MAX_LENGTH}
              disabled={busy || saved == null}
              placeholder="Ex. : remise de 1 mois accordée le 12/11, à rappeler en janvier."
              onChange={(e) => setText(e.target.value)}
            />
            <div className="flex flex-wrap items-center justify-between gap-2">
              <p className="text-xs text-muted-foreground">
                {saved?.updatedAt ? `Modifiée le ${formatDateTime(saved.updatedAt)} par ${saved.updatedBy ?? "—"}` : "Aucune note."} · {text.length}/{MAX_LENGTH}
              </p>
              <Button onClick={save} loading={busy} disabled={!dirty}>
                Enregistrer
              </Button>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}
