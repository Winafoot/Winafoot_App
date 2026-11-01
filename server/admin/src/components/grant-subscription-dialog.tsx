"use client";
import { useState } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { errorMessage, setCoachSubscription } from "@/lib/callables";
import { OFFER_DAYS, OFFER_TEAMS } from "@/lib/offer-options";
import { formatDate } from "@/lib/utils";

/** Offre (ou prolonge) un abonnement à un coach, sans passer par les stores : comptes de test, invités. */
export function GrantSubscriptionDialog({
  open,
  onOpenChange,
  uid,
  label,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  uid: string;
  label: string;
}) {
  const [days, setDays] = useState("30");
  const [teams, setTeams] = useState("1");
  const [busy, setBusy] = useState(false);

  const submit = async () => {
    setBusy(true);
    try {
      const { untilMs } = await setCoachSubscription({ uid, action: "grant", teams: Number(teams), days: Number(days) });
      toast.success(untilMs == null ? "Abonnement offert." : `Abonnement offert jusqu'au ${formatDate(new Date(untilMs))}.`);
      onOpenChange(false);
    } catch (e) {
      toast.error(errorMessage(e, "Attribution impossible."));
    } finally {
      setBusy(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={(next) => !busy && onOpenChange(next)}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Offrir un abonnement</DialogTitle>
          <DialogDescription>
            {label} aura accès à l&apos;app sans passer par l&apos;abonnement des stores. La durée part d&apos;aujourd&apos;hui ; vous pourrez le retirer à tout moment.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-2">
          <Label htmlFor="offer-days">Durée</Label>
          <Select value={days} onValueChange={setDays} disabled={busy}>
            <SelectTrigger id="offer-days">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {Object.entries(OFFER_DAYS).map(([key, text]) => (
                <SelectItem key={key} value={key}>
                  {text}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        <div className="grid gap-2">
          <Label htmlFor="offer-teams">Équipes incluses</Label>
          <Select value={teams} onValueChange={setTeams} disabled={busy}>
            <SelectTrigger id="offer-teams">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {Object.entries(OFFER_TEAMS).map(([key, text]) => (
                <SelectItem key={key} value={key}>
                  {text}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={busy}>
            Annuler
          </Button>
          <Button onClick={submit} loading={busy}>
            Offrir l&apos;abonnement
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
