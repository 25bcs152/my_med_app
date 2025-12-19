'use client';

import { useMemo } from 'react';
import { initializeFirebase } from './config';
import { FirebaseProvider } from './provider';
import type { FirebaseApp } from 'firebase/app';
import type { Auth } from 'firebase/auth';
import type { Firestore } from 'firebase/firestore';

export function FirebaseClientProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const firebaseContext = useMemo(() => {
    return initializeFirebase();
  }, []);

  if (!firebaseContext.firebaseApp) {
    return <>{children}</>;
  }

  return <FirebaseProvider value={firebaseContext}>{children}</FirebaseProvider>;
}
