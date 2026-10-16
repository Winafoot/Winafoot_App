/**
 * Module du socle commun des projets.
 */
enum GenderEnum {
  men = "men",
  women = "women",
  other = "other",
}

type GenderNullable = GenderEnum | undefined | null;

export { GenderEnum, GenderNullable };
