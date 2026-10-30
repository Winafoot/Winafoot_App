import type { NextConfig } from "next";

// Export statique : le back-office est servi tel quel par Firebase Hosting, sans serveur Next.js. Toutes les
// données passent par le SDK Firebase (règles Firestore) et les callables d'administration.
const config: NextConfig = {
  output: "export",
  trailingSlash: true,
  images: { unoptimized: true },
  reactStrictMode: true,
  poweredByHeader: false,
};

export default config;
