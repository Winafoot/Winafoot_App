// Gestionnaire de test pour documentWrittenAdapter : le module est chargé par `require`
// (le TypeScript des tests ne l'est pas), il consigne donc ses appels dans un global.
module.exports = {
  default: async (...args) => {
    globalThis.__capturedHandlerCalls.push(args);
  },
};
