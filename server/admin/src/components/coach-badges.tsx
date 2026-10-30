import { Badge } from "@/components/ui/badge";
import { SUBSCRIPTION_LABELS, type Coach } from "@/lib/data";

export function CoachStatusBadge({ coach }: { coach: Coach }) {
  if (coach.disabled) return <Badge variant="destructive">Désactivé</Badge>;
  if (coach.profilCompleted === false) return <Badge variant="warning">Profil incomplet</Badge>;
  return <Badge>Actif</Badge>;
}

export function SubscriptionBadge({ coach }: { coach: Coach }) {
  const status = coach.subscription?.status;
  if (status == null) return <span className="text-muted-foreground">—</span>;
  const variant = status === "active" || status === "trial" ? "default" : status === "grace" ? "warning" : "secondary";
  return <Badge variant={variant}>{SUBSCRIPTION_LABELS[status]}</Badge>;
}
