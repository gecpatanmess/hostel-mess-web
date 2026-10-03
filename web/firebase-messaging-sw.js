importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

const firebaseConfig = {
  apiKey: "AIzaSyCJ2ebzZpVt3rQKMSSRkuH-zh13xu3N6rw",
  appId: "1:947094039187:android:6c2a8906468742c8bdbb66",
  messagingSenderId: "947094039187",
  projectId: "hostel-mess-21845",
  databaseURL: "https://hostel-mess-21845-default-rtdb.firebaseio.com"
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  // 1. Setup notification options
  const notificationTitle = payload.notification?.title || 'Hostel Mess Update';
  const notificationOptions = {
    body: payload.notification?.body || 'New message from mess.',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    vibrate: [200, 100, 200]
  };

  // 2. Set App Badge using Badging API (Free)
  if (navigator.setAppBadge) {
    // Optionally you can track the count in IndexedDB, but for simplicity, we set it to 1
    // or you can retrieve a count from the payload if sent by the server.
    navigator.setAppBadge(1).catch((error) => {
      console.error('Error setting app badge:', error);
    });
  }

  // 3. Show notification
  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Clear badge when the user clicks the notification
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  if (navigator.clearAppBadge) {
    navigator.clearAppBadge().catch(console.error);
  }
  // Open the app
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then(windowClients => {
      for (var i = 0; i < windowClients.length; i++) {
        var client = windowClients[i];
        if (client.url === '/' && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
