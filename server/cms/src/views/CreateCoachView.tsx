import { useState } from "react";
import { useSnackbarController } from "@firecms/core";
import { Button, Card, CloseIcon, IconButton, Select, SelectItem, TextField, Typography } from "@firecms/ui";
import { createCoach } from "../callables";
import { PASSWORD_SPECIAL_CHARACTERS, passwordPolicyViolations } from "../password_policy";
import { TEAM_CATEGORIES, TEAM_DIVISIONS, TEAM_FORMATS, TEAM_NAME_MAX_LENGTH } from "../team_options";

function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  return "La création a échoué.";
}

// Liste déroulante facultative : la croix remet le champ à « non renseigné ».
function OptionalSelect({
  label,
  options,
  value,
  onChange,
  disabled,
}: {
  label: string;
  options: Record<string, string>;
  value: string;
  onChange: (value: string) => void;
  disabled: boolean;
}) {
  return (
    <Select
      fullWidth
      label={label}
      value={value}
      onValueChange={onChange}
      disabled={disabled}
      endAdornment={
        value && !disabled ? (
          <IconButton size="small" onClick={() => onChange("")}>
            <CloseIcon size="small" />
          </IconButton>
        ) : undefined
      }
    >
      {Object.entries(options).map(([key, optionLabel]) => (
        <SelectItem key={key} value={key}>
          {optionLabel}
        </SelectItem>
      ))}
    </Select>
  );
}

export function CreateCoachView() {
  const snackbar = useSnackbarController();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [firstname, setFirstname] = useState("");
  // Le Select de @firecms/ui travaille en chaîne : converti en nombre à l'envoi.
  const [teamFormat, setTeamFormat] = useState("");
  const [teamName, setTeamName] = useState("");
  const [category, setCategory] = useState("");
  const [division, setDivision] = useState("");
  const [busy, setBusy] = useState(false);

  // Même règle que createCoach (politique de mot de passe du projet) : le bouton reste inactif tant
  // qu'elle n'est pas remplie, et la liste des exigences manquantes s'affiche sous le champ.
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
      snackbar.open({ type: "success", message: `Compte créé pour ${email}.` });
      setEmail("");
      setPassword("");
      setFirstname("");
      setTeamFormat("");
      setTeamName("");
      setCategory("");
      setDivision("");
    } catch (e: unknown) {
      snackbar.open({ type: "error", message: getErrorMessage(e) });
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="p-8 flex flex-col gap-4 max-w-xl">
      <Typography variant="h4">Créer un compte coach</Typography>
      <Typography variant="body2">
        Renseignez l'adresse e-mail et le mot de passe du coach, puis transmettez-lui ces
        identifiants : aucun e-mail n'est envoyé à la création. Il se connecte directement avec
        eux, puis complète son profil (équipe, catégorie, maillots) dans l'application ; l'équipe,
        la catégorie et la division saisies ici y sont pré-remplies.
      </Typography>
      <Card className="p-6 flex flex-col gap-4">
        {/* Identifiants du COACH, pas de l'administrateur connecté : le navigateur ne doit ni
            y remplir les identifiants enregistrés, ni proposer de les enregistrer. */}
        <TextField
          label="Adresse e-mail du coach"
          type="email"
          name="coach-email"
          autoComplete="off"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          disabled={busy}
        />
        <TextField
          label="Mot de passe du coach"
          type="password"
          name="coach-new-password"
          autoComplete="new-password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          error={password.length > 0 && missing.length > 0}
          disabled={busy}
        />
        <Typography variant="body2">
          {password.length > 0 && missing.length > 0
            ? `Il manque : ${missing.join(", ")}.`
            : "Au moins 6 caractères, avec une minuscule, une majuscule, un chiffre et un caractère spécial."}
          {" "}Caractères spéciaux acceptés : {[...PASSWORD_SPECIAL_CHARACTERS].join(" ")}
        </Typography>
        <TextField
          label="Nom complet du coach (optionnel)"
          name="coach-name"
          autoComplete="off"
          value={firstname}
          onChange={(e) => setFirstname(e.target.value)}
          disabled={busy}
        />
        <Select
          fullWidth
          label="Format du club"
          value={teamFormat}
          onValueChange={setTeamFormat}
          disabled={busy}
        >
          {TEAM_FORMATS.map(({ value, label }) => (
            <SelectItem key={value} value={String(value)}>
              {label}
            </SelectItem>
          ))}
        </Select>
        <TextField
          label="Nom de l'équipe (optionnel)"
          name="coach-team-name"
          autoComplete="off"
          value={teamName}
          onChange={(e) => setTeamName(e.target.value)}
          maxLength={TEAM_NAME_MAX_LENGTH}
          disabled={busy}
        />
        <OptionalSelect
          label="Catégorie (optionnel)"
          options={TEAM_CATEGORIES}
          value={category}
          onChange={setCategory}
          disabled={busy}
        />
        <OptionalSelect
          label="Division (optionnel)"
          options={TEAM_DIVISIONS}
          value={division}
          onChange={setDivision}
          disabled={busy}
        />
        <Button
          onClick={submit}
          disabled={
            busy || email.trim().length === 0 || missing.length > 0 || teamFormat === ""
          }
        >
          {busy ? "Création…" : "Créer le compte"}
        </Button>
      </Card>
    </div>
  );
}
