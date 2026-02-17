// Service Worker for PWA
// 버전 업데이트 시 이 숫자를 변경하세요!
const SW_VERSION = '2.8.2';
const CACHE_NAME = `snack-games-v${SW_VERSION}`;

// 앱 셸: 첫 로딩에 필수적인 파일만 프리캐시
const CORE_CACHE = [
    '/',
    '/index.html',
    '/manifest.json',
    '/flutter_bootstrap.js',
    '/main.dart.js',
    '/icons/Icon-192.png',
    '/icons/Icon-512.png',
];

// Install event - 핵심 파일만 프리캐시 (빠른 설치)
self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => {
                console.log('[SW] Caching core shell');
                return cache.addAll(CORE_CACHE);
            })
            .catch((error) => {
                console.log('[SW] Core cache failed:', error);
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

// Fetch event - 리소스 유형별 최적 전략
self.addEventListener('fetch', (event) => {
    const url = new URL(event.request.url);

    // 오디오/SFX 파일: Cache First (큰 파일, 변경 거의 없음)
    if (url.pathname.includes('/audio/') || url.pathname.includes('/sfx/')) {
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

    // CanvasKit WASM/JS: Cache First (대용량, 버전 고정)
    if (url.pathname.includes('/canvaskit/')) {
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

    // main.dart.js: Network First (강제 업데이트 - 항상 최신 버전 가져옴)
    if (url.pathname.endsWith('main.dart.js')) {
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
                    return caches.match(event.request);
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
