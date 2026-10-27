// No financial records, auth responses or API calls are cached. This worker only
// provides an installable web-app context; records require a live server connection.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil(self.clients.claim()));
