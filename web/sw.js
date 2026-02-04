// Service Worker for PWA
// 버전 업데이트 시 이 숫자를 변경하세요!
const SW_VERSION = '2.3.9';
const CACHE_NAME = `snack-games-v${SW_VERSION}`;
const urlsToCache = [
    '/',
    '/index.html',
    '/manifest.json',
    '/favicon.png',
    '/icons/Icon-192.png',
    '/icons/Icon-512.png',
    '/icons/Icon-maskable-192.png',
    '/icons/Icon-maskable-512.png',
];

// Install event - cache resources
self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => {
                console.log('Opened cache');
                return cache.addAll(urlsToCache);
            })
            .catch((error) => {
                console.log('Cache installation failed:', error);
            })
    );
    self.skipWaiting();
});

// Activate event - clean up old caches and notify clients
self.addEventListener('activate', (event) => {
    event.waitUntil(
        (async () => {
            // Clean up old caches
            const cacheNames = await caches.keys();
            await Promise.all(
                cacheNames.map((cacheName) => {
                    if (cacheName !== CACHE_NAME) {
                        console.log('Deleting old cache:', cacheName);
                        return caches.delete(cacheName);
                    }
                })
            );

            // Notify all clients about the update (activation only)
            const clients = await self.clients.matchAll({ type: 'window' });
            console.log(`SW v${SW_VERSION} activated, notifying ${clients.length} clients`);
            clients.forEach((client) => {
                client.postMessage({
                    type: 'SW_UPDATED',
                    version: SW_VERSION,
                    message: '새 버전이 설치되었습니다!'
                });
            });
        })()
    );
    self.clients.claim();
});

// Fetch event - serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
    event.respondWith(
        caches.match(event.request)
            .then((response) => {
                // Cache hit - return response
                if (response) {
                    return response;
                }

                // Clone the request
                const fetchRequest = event.request.clone();

                return fetch(fetchRequest).then((response) => {
                    // Check if valid response
                    if (!response || response.status !== 200 || response.type !== 'basic') {
                        return response;
                    }

                    // Clone the response
                    const responseToCache = response.clone();

                    caches.open(CACHE_NAME)
                        .then((cache) => {
                            cache.put(event.request, responseToCache);
                        });

                    return response;
                }).catch((error) => {
                    console.log('Fetch failed:', error);
                    // Return offline page or fallback
                    return caches.match('/index.html');
                });
            })
    );
});

// Handle messages from clients
self.addEventListener('message', (event) => {
    if (event.data && event.data.type === 'GET_VERSION') {
        event.source.postMessage({
            type: 'SW_VERSION',
            version: SW_VERSION
        });
    }

    if (event.data && event.data.type === 'SKIP_WAITING') {
        self.skipWaiting();
    }
});
