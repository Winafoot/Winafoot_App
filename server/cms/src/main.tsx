import React from "react"
import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";

import "./index.css"
import App from "./App";
import { installThirdPartyGuard } from "./third_party_guard";

// Avant le rendu : le back-office n'envoie aucune donnée à des services tiers de journalisation.
installThirdPartyGuard(window);

ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
    <React.StrictMode>
        <BrowserRouter basename={"/"}>
            <App/>
        </BrowserRouter>
    </React.StrictMode>
)
