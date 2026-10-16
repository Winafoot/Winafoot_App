import { firestore } from "firebase-admin";
/**
 * Module du socle commun des projets.
 */
interface InterfaceRootRepository<M> {
  collectionName: string;
  converter: firestore.FirestoreDataConverter<M>;

  collection: firestore.CollectionReference<M>;
  get(id: string): Promise<firestore.DocumentSnapshot<M>>;
  add(data: M): Promise<firestore.DocumentReference<M>>;
  update(id: string, data: firestore.UpdateData<M>): Promise<firestore.WriteResult>;
  delete(id: string): Promise<firestore.WriteResult>;
  set(id: string, data: Partial<M>, options: firestore.SetOptions): Promise<firestore.WriteResult>;
  setWithMerge(id: string, data: Partial<M>): Promise<firestore.WriteResult>;
  getDocumentReference(id: string): firestore.DocumentReference<M>;
  fromDocumentReference(docRef: firestore.DocumentReference<M>): Promise<firestore.DocumentSnapshot<M>>;
}

/**
 * @example
 * export class SampleRepository extends RootRepository<SampleModel> {
 *  private static _instance: SampleRepository = new SampleRepository();
 *
 *  constructor() {
 *    super("sample", SampleModelConverter);
 *
 *    if (SampleRepository._instance) {
 *      throw new Error("Use SampleRepository.getInstance() instead of new.");
 *    }
 *    SampleRepository._instance = this;
 *  }
 *
 *  public static get instance(): SampleRepository {
 *    return SampleRepository._instance;
 *  }
 * }
 */
class RootRepository<M> implements InterfaceRootRepository<M> {
  collectionName: string;
  converter: firestore.FirestoreDataConverter<M>;

  constructor(collectionName: string, converter: firestore.FirestoreDataConverter<M>) {
    this.collectionName = collectionName;
    this.converter = converter;
  }

  public get collection(): firestore.CollectionReference<M> {
    return firestore().collection(this.collectionName).withConverter(this.converter);
  }

  public get(id: string): Promise<firestore.DocumentSnapshot<M>> {
    return this.collection.doc(id).get();
  }

  public add(data: M): Promise<firestore.DocumentReference<M>> {
    return this.collection.add({...data});
  }

  public update(id: string, data: firestore.UpdateData<M>): Promise<firestore.WriteResult> {
    return this.collection.doc(id).update(data as any);
  }

  public delete(id: string): Promise<firestore.WriteResult> {
    return this.collection.doc(id).delete();
  }

  public set(id: string, data: Partial<M>, options: firestore.SetOptions = { merge: true }): Promise<firestore.WriteResult> {
    return this.collection.doc(id).set({...data}, options);
  }

  public setWithMerge(id: string, data: Partial<M>): Promise<firestore.WriteResult> {
    return this.collection.doc(id).set({...data}, { merge: true });
  }

  public getDocumentReference(id: string): firestore.DocumentReference<M> {
    return this.collection.doc(id);
  }

  public fromDocumentReference(docRef: firestore.DocumentReference<M>): Promise<firestore.DocumentSnapshot<M>> {
    return docRef.withConverter(this.converter).get();
  }
}

export { RootRepository, InterfaceRootRepository };
