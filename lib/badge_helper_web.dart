import 'dart:js' as js;

void setAppBadgeHelper(int count) {
  js.context.callMethod('eval', ["if(navigator.setAppBadge) { navigator.setAppBadge($count); }"]);
}

void clearAppBadgeHelper() {
  js.context.callMethod('eval', ["if(navigator.clearAppBadge) { navigator.clearAppBadge(); }"]);
}
