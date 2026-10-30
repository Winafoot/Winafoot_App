"use client";
import { useState } from "react";
import { toast } from "sonner";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { createCoach, errorMessage } from "@/lib/callables";
import { PASSWORD_SPECIAL_CHARACTERS, passwordPolicyViolations } from "@/lib/password-policy";
import { TEAM_CATEGORIES, TEAM_DIVISIONS, TEAM_FORMATS, TEAM_NAME_MAX_LENGTH } from "@/lib/team-options";

const NONE = "__none__";

function OptionalSelect({
  id,
  label,
  options,
  value,
  onChange,
  disabled,
}: {
  id: string;
  label: string;
  options: Record<string, string>;
  value: string;
  onChange: (value: string) => void;
  disabled: boolean;
}) {
  return (
    <div className="grid gap-2">
      <Label htmlFor={id}>{label}</Label>
      <Select value={value || NONE} onValueChange={(v) => onChange(v === NONE ? "" : v)} disabled={disabled}>
        <SelectTrigger id={id}>
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value={NONE}>Non renseigné</SelectItem>
          {Object.entries(options).map(([key, text]) => (
            <SelectItem key={key} value={key}>
              {text}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
}

export default function CreateCoachPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [firstname, setFirstname] = useState("");
  const [teamFormat, setTeamFormat] = useState("");
  const [teamName, setTeamName] = useState("");
  const [category, setCategory] = useState("");
  const [division, setDivision] = useState("");
  const [busy, setBusy] = useState(false);

  // Même règle que createCoach : le bouton reste inactif tant qu'elle n'est pas remplie.
  const missing = passwordPolicyViolations(password);

  const submit = async () => {
    setBusy(true);
    try {
      await createCoach({
        email,
        password,
        firstname: firstname.trim() || undefined,
        teamFormat: Number(teamFormat),
        teamName: teamName.trim() || undefined,
        category: category || undefined,
        division: division || undefined,
      });
      toast.success(`Compte créé pour ${email}.`);
      setEmail("");
      setPassword("");
      setFirstname("");
      setTeamFormat("");
      setTeamName("");
      setCategory("");
      setDivision("");
    } catch (e) {
      toast.error(errorMessage(e, "La création a échoué."));
    } finally {
      setBusy(false);
    }
  };

  return (
    <>
      <PageHeader
        title="Créer un compte coach"
        description="Renseignez l'adresse e-mail et le mot de passe du coach, puis transmettez-lui ces identifiants : aucun e-mail n'est envoyé à la création. Il se connecte directement avec eux, puis complète son profil dans l'application."
      />
      <Card className="max-w-xl">
        <CardContent className="grid gap-4 pt-5">
          {/* Identifiants du COACH, pas de l'administrateur connecté : le navigateur ne doit ni y remplir les
              identifiants enregistrés, ni proposer de les enregistrer. */}
          <div className="grid gap-2">
            <Label htmlFor="coach-email">Adresse e-mail du coach</Label>
            <Input id="coach-email" type="email" name="coach-email" autoComplete="off" value={email} onChange={(e) => setEmail(e.target.value)} disabled={busy} />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="coach-password">Mot de passe du coach</Label>
            <Input
              id="coach-password"
              type="password"
              name="coach-new-password"
              autoComplete="new-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              aria-invalid={password.length > 0 && missing.length > 0}
              disabled={busy}
            />
            <p className={password.length > 0 && missing.length > 0 ? "text-sm text-destructive" : "text-sm text-muted-foreground"}>
              {password.length > 0 && missing.length > 0
                ? `Il manque : ${missing.join(", ")}.`
                : "Au moins 6 caractères, avec une minuscule, une majuscule, un chiffre et un caractère spécial."}{" "}
              Caractères spéciaux acceptés : {[...PASSWORD_SPECIAL_CHARACTERS].join(" ")}
            </p>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="coach-name">Nom complet du coach (optionnel)</Label>
            <Input id="coach-name" name="coach-name" autoComplete="off" value={firstname} onChange={(e) => setFirstname(e.target.value)} disabled={busy} />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="coach-format">Format du club</Label>
            <Select value={teamFormat} onValueChange={setTeamFormat} disabled={busy}>
              <SelectTrigger id="coach-format">
                <SelectValue placeholder="Choisir un format" />
              </SelectTrigger>
              <SelectContent>
                {TEAM_FORMATS.map(({ value, label }) => (
                  <SelectItem key={value} value={String(value)}>
                    {label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="coach-team">Nom de l&apos;équipe (optionnel)</Label>
            <Input id="coach-team" name="coach-team-name" autoComplete="off" maxLength={TEAM_NAME_MAX_LENGTH} value={teamName} onChange={(e) => setTeamName(e.target.value)} disabled={busy} />
          </div>
          <OptionalSelect id="coach-category" label="Catégorie (optionnel)" options={TEAM_CATEGORIES} value={category} onChange={setCategory} disabled={busy} />
          <OptionalSelect id="coach-division" label="Division (optionnel)" options={TEAM_DIVISIONS} value={division} onChange={setDivision} disabled={busy} />
          <Button onClick={submit} loading={busy} disabled={email.trim().length === 0 || missing.length > 0 || teamFormat === ""}>
            Créer le compte
          </Button>
        </CardContent>
      </Card>
    </>
  );
}
