/// <reference types="vite/client" />
import { useCallback, useMemo } from "react";

import {
    AppBar,
    Authenticator,
    CircularProgressCenter,
    Drawer,
    FireCMS,
    FireCMSi18nProvider,
    ModeControllerProvider,
    NavigationRoutes,
    Scaffold,
    SideDialogs,
    SnackbarProvider,
    useBuildLocalConfigurationPersistence,
    useBuildModeController,
    useBuildNavigationController,
    useValidateAuthenticator,
    type CMSView,
    type EntityCollection
} from "@firecms/core";
import {
    FirebaseAuthController,
    FirebaseSignInProvider,
    FirebaseUserWrapper,
    useFirebaseAuthController,
    useFirebaseStorageSource,
    useFirestoreDelegate,
} from "@firecms/firebase";
import { initializeApp } from "firebase/app";
import { initializeAppCheck, ReCaptchaEnterpriseProvider } from "firebase/app-check";

import { appCheckSiteKey, firebaseConfig } from "./firebase_config";
import { coachesCollection } from "./collections/coaches";
import { adminAuditCollection } from "./collections/admin_audit";
import { AdminsView } from "./views/AdminsView";
import { CreateCoachView } from "./views/CreateCoachView";
import { SecurityView } from "./views/SecurityView";
import { LoginView } from "./views/LoginView";
import { TotpSignInView } from "./views/TotpSignInView";

// L'app Firebase (par défaut, la même que `getApp()` dans callables.ts) est créée
// ICI, à l'évaluation du module, et non via `useInitialiseFirebase` : ce hook crée
// l'app dans un effet, puis `useFirebaseAuthController` appelle `getAuth()` pendant
// le rendu suivant, AVANT que le callback `onFirebaseInit` (un effet) ne s'exécute.
// Auth démarrerait donc ses requêtes sans jeton App Check. Ici App Check est actif
// avant tout rendu React, donc avant toute instance Auth / Firestore / Functions.
// `initializeApp` et `initializeAppCheck` ne sont exécutés qu'une fois par chargement
// de page (StrictMode ne ré-évalue pas les modules).
const firebaseApp = initializeApp(firebaseConfig);

if (appCheckSiteKey) {
    if (import.meta.env.DEV && ["localhost", "127.0.0.1"].includes(location.hostname)) {
        // Jeton de débogage (uniquement en dev ET sur localhost : même un build lancé avec
        // NODE_ENV=development ne peut pas l'activer sur wina-admin.web.app) : généré au premier lancement, affiché dans la console du
        // navigateur, à enregistrer dans la console Firebase (App Check > Applications).
        // Doit être posé avant le tout premier `initializeAppCheck`.
        // Object.assign : cette globale n'est pas déclarée dans les types publics du SDK.
        Object.assign(self, { FIREBASE_APPCHECK_DEBUG_TOKEN: true });
    }
    initializeAppCheck(firebaseApp, {
        provider: new ReCaptchaEnterpriseProvider(appCheckSiteKey),
        isTokenAutoRefreshEnabled: true
    });
} else {
    console.warn("App Check désactivé : appCheckSiteKey est vide dans firebase_config.ts.");
}

function App() {

    // Accès réservé aux administrateurs Wina : custom claim `admin` (vue « Administrateurs » ou
    // scripts/set-admin.ts) et adresse vérifiée. `getIdTokenResult(true)` force le rafraîchissement
    // du jeton pour qu'un claim fraîchement attribué soit pris en compte sans
    // attendre l'expiration (une heure).
    const winaAuthenticator: Authenticator<FirebaseUserWrapper> = useCallback(async ({
        user,
        authController
    }) => {
        if (user == null) {
            return false;
        }

        const tokenResult = await user.firebaseUser?.getIdTokenResult(true);

        if (tokenResult?.claims?.admin !== true) {
            throw new Error("Accès réservé aux administrateurs Wina.");
        }

        // Les règles Firestore et les callables d'administration exigent aussi une adresse vérifiée :
        // le lien reçu par e-mail (invitation ou réinitialisation du mot de passe) la vérifie.
        if (tokenResult?.claims?.email_verified !== true) {
            throw new Error("Adresse e-mail non vérifiée : utilisez le lien reçu par e-mail pour définir votre mot de passe, puis reconnectez-vous.");
        }

        authController.setExtra({ role: "admin" });
        return true;
    }, []);

    const collections = useMemo<EntityCollection[]>(() => [coachesCollection, adminAuditCollection], []);

    const views = useMemo<CMSView[]>(() => [{
        path: "creer-coach",
        name: "Créer un coach",
        description: "Créer un compte coach avec le mot de passe choisi (aucun e-mail n'est envoyé).",
        view: <CreateCoachView/>,
    }, {
        path: "administrateurs",
        name: "Administrateurs",
        description: "Inviter, modifier et supprimer les comptes administrateurs du back-office.",
        view: <AdminsView/>,
    }, {
        path: "securite",
        name: "Sécurité du compte",
        description: "Activer le second facteur (code d'une application d'authentification).",
        view: <SecurityView/>,
    }], []);

    // Contrôleur du mode clair / sombre.
    const modeController = useBuildModeController();

    // Les administrateurs se connectent par e-mail + mot de passe (comptes créés depuis la vue
    // « Administrateurs »). Pas de fournisseur tiers.
    const signInOptions: FirebaseSignInProvider[] = ["password"];

    const authController: FirebaseAuthController = useFirebaseAuthController({
        firebaseApp,
        signInOptions
    });

    const userConfigPersistence = useBuildLocalConfigurationPersistence();

    const firestoreDelegate = useFirestoreDelegate({
        firebaseApp
    });

    const storageSource = useFirebaseStorageSource({
        firebaseApp
    });

    const {
        authLoading,
        canAccessMainView,
        notAllowedError
    } = useValidateAuthenticator({
        authController,
        authenticator: winaAuthenticator,
        dataSourceDelegate: firestoreDelegate,
        storageSource
    });

    const navigationController = useBuildNavigationController({
        disabled: authLoading,
        collections,
        views,
        authController,
        dataSourceDelegate: firestoreDelegate
    });

    return (
        <FireCMSi18nProvider locale="fr">
            <SnackbarProvider>
                <ModeControllerProvider value={modeController}>
                    <FireCMS
                        navigationController={navigationController}
                        authController={authController}
                        userConfigPersistence={userConfigPersistence}
                        dataSourceDelegate={firestoreDelegate}
                        storageSource={storageSource}
                    >
                        {({
                            loading
                        }) => {

                            if (loading || authLoading) {
                                return <CircularProgressCenter size={"large"}/>;
                            }

                            if (!canAccessMainView) {
                                // Compte avec second facteur : le contrôleur garde l'erreur
                                // « multi-factor-auth-required » (aucun utilisateur connecté tant
                                // que le code n'est pas validé) : TotpSignInView demande le code.
                                if (authController.user == null &&
                                    authController.authProviderError?.code === "auth/multi-factor-auth-required") {
                                    return <TotpSignInView error={authController.authProviderError}
                                                           onCancel={authController.signOut}/>;
                                }

                                return <LoginView authController={authController}
                                                  firebaseApp={firebaseApp}
                                                  notAllowedError={notAllowedError}/>;
                            }

                            return <Scaffold
                                autoOpenDrawer={false}>
                                <AppBar title={"Wina — Back-office"}/>
                                <Drawer/>
                                <NavigationRoutes/>
                                <SideDialogs/>
                            </Scaffold>;
                        }}
                    </FireCMS>
                </ModeControllerProvider>
            </SnackbarProvider>
        </FireCMSi18nProvider>
    );

}

export default App;
