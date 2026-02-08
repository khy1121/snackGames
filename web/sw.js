// Service Worker for PWA
// 버전 업데이트 시 이 숫자를 변경하세요!
const SW_VERSION = '2.5.12';
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

// Fetch event - Network First 전략 (항상 최신 버전 우선)
self.addEventListener('fetch', (event) => {
    const url = new URL(event.request.url);
    
    // 오디오/SFX 파일은 Cache First (큰 파일, 변경 거의 없음)
    if (url.pathname.startsWith('/audio/') || url.pathname.startsWith('/sfx/')) {
        event.respondWith(
            caches.match(event.request).then((cached) => {
                if (cached) return cached;
                return fetch(event.request).then((response) => {
                    if (response && response.status === 200) {
                        const clone = response.clone();
                        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
                    }
                    return response;
                });
            })
        );
        return;
    }
    
    // 그 외 모든 리소스: Network First (최신 버전 우선, 오프라인 시 캐시)
    event.respondWith(
        fetch(event.request)
            .then((response) => {
                if (response && response.status === 200) {
                    const clone = response.clone();
                    caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
                }
                return response;
            })
            .catch(() => {
                return caches.match(event.request).then((cached) => {
                    return cached || caches.match('/index.html');
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
