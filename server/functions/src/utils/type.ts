import { firestore } from "firebase-admin";

type NumberNullable = number | undefined | null;
type StringNullable = string | undefined | null;
type BooleanNullable = boolean | undefined | null;
type DateNullable = Date | undefined | null;
type TimestampNullable = firestore.Timestamp | undefined | null;
type GeoPointNullable = firestore.GeoPoint | undefined | null;
type DocumentReferenceNullable = firestore.DocumentReference | undefined | null;
type ObjectNullable = object | undefined | null;
type ArrayNullable = any[] | undefined | null;
type StringArrayNullable = string[] | undefined | null;
type MapNullable = Map<any, any> | undefined | null;
type AnyNullable = any | undefined | null;

export {
  NumberNullable,
  StringNullable,
  BooleanNullable,
  DateNullable,
  TimestampNullable,
  GeoPointNullable,
  DocumentReferenceNullable,
  ObjectNullable,
  ArrayNullable,
  StringArrayNullable,
  MapNullable,
  AnyNullable,
};
