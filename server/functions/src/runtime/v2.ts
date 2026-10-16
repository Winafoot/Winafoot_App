import * as path from "path";
import { type Response } from "express";
import { type Request, type CallableRequest } from "firebase-functions/v2/https";
import { type FirestoreEvent, type QueryDocumentSnapshot, type Change, type DocumentSnapshot } from "firebase-functions/v2/firestore";
import { type LegacyDocumentChange, type LegacyEventContext, type LegacyWrittenEventContext } from "./firebase";

type DefaultHandler<TArgs extends any[] = any[], TResult = any> = (...args: TArgs) => TResult;

function loadDefaultHandler<THandler extends DefaultHandler>(modulePath: string): THandler {
  const fullPath = path.join(__dirname, "..", modulePath);
  return require(fullPath).default as THandler;
}

export function callableAdapter<TData = any, TResult = any>(modulePath: string) {
  return async (request: CallableRequest<TData>): Promise<TResult> => {
    const handler = loadDefaultHandler<(data: TData) => Promise<TResult> | TResult>(modulePath);
    return handler(request.data);
  };
}

export function requestAdapter(modulePath: string) {
  return async (request: Request, response: Response): Promise<void> => {
    const handler = loadDefaultHandler<(request: Request, response: Response) => Promise<void> | void>(modulePath);
    await handler(request, response);
  };
}

export function documentCreatedAdapter<T = any>(modulePath: string) {
  return async (event: FirestoreEvent<QueryDocumentSnapshot | undefined>): Promise<void> => {
    if (event.data == null) {
      return;
    }

    const handler = loadDefaultHandler<(snapshot: QueryDocumentSnapshot, context: LegacyEventContext) => Promise<void> | void>(modulePath);
    await handler(event.data, { params: event.params ?? {} });
  };
}

export function documentDeletedAdapter<T = any>(modulePath: string) {
  return async (event: FirestoreEvent<DocumentSnapshot | undefined>): Promise<void> => {
    if (event.data == null) {
      return;
    }

    const handler = loadDefaultHandler<(snapshot: DocumentSnapshot, context: LegacyEventContext) => Promise<void> | void>(modulePath);
    await handler(event.data, { params: event.params ?? {} });
  };
}

export function documentUpdatedAdapter<T = any>(modulePath: string) {
  return async (event: FirestoreEvent<Change<DocumentSnapshot> | undefined>): Promise<void> => {
    if (event.data == null) {
      return;
    }

    const handler = loadDefaultHandler<(snapshot: LegacyDocumentChange<DocumentSnapshot>, context: LegacyEventContext) => Promise<void> | void>(modulePath);
    await handler(
      {
        before: event.data.before,
        after: event.data.after,
      },
      { params: event.params ?? {} }
    );
  };
}

export function documentWrittenAdapter<T = any>(modulePath: string) {
  return async (event: FirestoreEvent<Change<DocumentSnapshot> | undefined>): Promise<void> => {
    if (event.data == null) {
      return;
    }

    const handler = loadDefaultHandler<(snapshot: LegacyDocumentChange<DocumentSnapshot>, context: LegacyWrittenEventContext) => Promise<void> | void>(modulePath);
    await handler(
      {
        before: event.data.before,
        after: event.data.after,
      },
      { params: event.params ?? {}, eventTime: event.time, eventId: event.id }
    );
  };
}
