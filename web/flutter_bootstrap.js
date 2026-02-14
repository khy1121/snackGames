{{flutter_js}}
{{flutter_build_config}}

// Flutter Service Worker를 비활성화하고 커스텀 sw.js 사용
// serviceWorkerSettings를 제거하여 flutter_service_worker.js 등록을 방지
_flutter.loader.load({
  // serviceWorkerSettings 생략 → Flutter SW 비활성화
});
