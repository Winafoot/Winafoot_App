import { firestore } from "firebase-admin";
/**
 * Module du socle commun des projets.
 */
interface InterfaceSubCollectionRepository<M> {
  subCollectionName: string;
  converter: firestore.FirestoreDataConverter<M>;

  collectionReference: firestore.CollectionReference<M>;
  getCollectionReferenceFromParent(parent: firestore.DocumentReference): firestore.CollectionReference<M>;
  deleteCollectionFromParent(parent: firestore.DocumentReference): Promise<firestore.WriteResult[]>;
  get(parent: firestore.DocumentReference, id: string): Promise<firestore.DocumentSnapshot<M>>;
  add(parent: firestore.DocumentReference, data: M): Promise<firestore.DocumentReference<M>>;
  update(parent: firestore.DocumentReference, id: string, data: firestore.UpdateData<M>): Promise<firestore.WriteResult>;
  set(parent: firestore.DocumentReference, id: string, data: Partial<M>, options: firestore.SetOptions): Promise<firestore.WriteResult>;
  delete(parent: firestore.DocumentReference, id: string): Promise<firestore.WriteResult>;
  getDocumentReference(parent: firestore.DocumentReference, id: string): firestore.DocumentReference<M>;
  fromDocumentReference(parent: firestore.DocumentReference, id: string): firestore.DocumentReference<M>;
}

/**
 * @example
 * export class SampleRepository extends SubCollectionRepository<SampleModel> {
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
class SubCollectionRepository<M> implements InterfaceSubCollectionRepository<M> {
  subCollectionName: string;
  converter: firestore.FirestoreDataConverter<M>;

  constructor(subCollectionName: string, converter: firestore.FirestoreDataConverter<M>) {
    this.subCollectionName = subCollectionName;
    this.converter = converter;
  }

  public get collectionReference(): firestore.CollectionReference<M> {
    return firestore().collection(this.subCollectionName).withConverter(this.converter);
  }

  public getCollectionReferenceFromParent(parent: firestore.DocumentReference): firestore.CollectionReference<M> {
    return parent.collection(this.subCollectionName).withConverter(this.converter);
  }

  public async deleteCollectionFromParent(parent: firestore.DocumentReference<firestore.DocumentData>): Promise<firestore.WriteResult[]> {
    const snapshot: firestore.QuerySnapshot<M> = await this.getCollectionReferenceFromParent(parent).get();
    const batch: firestore.WriteBatch = firestore().batch();

    snapshot.docs.forEach((doc: firestore.QueryDocumentSnapshot<M>) => {
      batch.delete(doc.ref);
    });
    return batch.commit();
  }

  public get(parent: firestore.DocumentReference, id: string): Promise<firestore.DocumentSnapshot<M>> {
    return this.getCollectionReferenceFromParent(parent).doc(id).get();
  }

  public add(parent: firestore.DocumentReference, data: M): Promise<firestore.DocumentReference<M>> {
    return this.getCollectionReferenceFromParent(parent).add({...data});
  }

  public set(parent: firestore.DocumentReference, id: string, data: Partial<M>, options: firestore.SetOptions = { merge: true }): Promise<firestore.WriteResult> {
    return this.getCollectionReferenceFromParent(parent).doc(id).set({...data}, options);
  }

  public update(parent: firestore.DocumentReference, id: string, data: firestore.UpdateData<M>): Promise<firestore.WriteResult> {
    return this.getCollectionReferenceFromParent(parent).doc(id).update(data as any);
  }

  public delete(parent: firestore.DocumentReference, id: string): Promise<firestore.WriteResult> {
    return this.getCollectionReferenceFromParent(parent).doc(id).delete();
  }

  public getDocumentReference(parent: firestore.DocumentReference, id: string): firestore.DocumentReference<M> {
    return this.getCollectionReferenceFromParent(parent).doc(id);
  }

  public fromDocumentReference(parent: firestore.DocumentReference, id: string): firestore.DocumentReference<M> {
    return this.getCollectionReferenceFromParent(parent).doc(id);
  }
}

export { SubCollectionRepository, InterfaceSubCollectionRepository };
