// Listes du profil coach / équipe, partagées par la collection « Coachs » et le
// formulaire de création.
//
// MIROIR de lib/models/coach_profile.dart (app : enums TeamCategory et
// TeamDivision), à tenir synchronisé à la main. Les clés sont le contrat de
// données (`enum.name`, écrit tel quel dans users/{uid}.category / .division) :
// ne jamais les renommer ; l'ordre est celui des listes déroulantes de l'app.
// functions/src/callables/admin/create_coach.ts porte une copie des clés.

export const TEAM_CATEGORIES: Record<string, string> = {
  u6: "U6",
  u7: "U7",
  u8: "U8",
  u9: "U9",
  u10: "U10",
  u11: "U11",
  u12: "U12",
  u13: "U13",
  u14: "U14",
  u15: "U15",
  u16: "U16",
  u17: "U17",
  u18: "U18",
  u19: "U19",
  seniors: "Séniors",
  veterans: "Vétérans",
};

export const TEAM_DIVISIONS: Record<string, string> = {
  r1: "Régional 1",
  r2: "Régional 2",
  r3: "Régional 3",
  d1: "Départemental 1",
  d2: "Départemental 2",
  d3: "Départemental 3",
  d4: "Départemental 4",
  d5: "Départemental 5",
  d6: "Départemental 6",
  d7: "Départemental 7",
  d8: "Départemental 8",
};

// Format du club = users/{uid}.teamFormat : nombre de joueurs sur le terrain.
// Il fixe le plafond d'effectif appliqué par firestore.rules (maxPlayers) :
// 5 -> 9, 8 -> 14, 11 -> 20. Posé uniquement à la création du compte.
export const TEAM_FORMATS: { value: number; label: string }[] = [
  { value: 5, label: "Foot à 5 — 9 joueurs max" },
  { value: 8, label: "Foot à 8 — 14 joueurs max" },
  { value: 11, label: "Foot à 11 — 20 joueurs max" },
];

// Aligné sur maxLength du nom d'équipe adverse dans l'app (coup_denvoi_step1) ;
// la même borne est revérifiée côté callable.
export const TEAM_NAME_MAX_LENGTH = 40;
