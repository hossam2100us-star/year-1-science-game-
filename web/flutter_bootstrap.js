{{flutter_js}}
{{flutter_build_config}}

// No service worker: an old cached copy of the game must never hide an
// update, and nothing about the game depends on offline web caching
// (progress is kept in the browser's own storage).
_flutter.loader.load({
  onEntrypointLoaded: async (engineInitializer) => {
    const appRunner = await engineInitializer.initializeEngine();
    document.getElementById('loading')?.remove();
    await appRunner.runApp();
  },
});
