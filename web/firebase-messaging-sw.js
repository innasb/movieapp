importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: 'AIzaSyBpX6V_I7fuBtjwTGfUhhbLT-mDgg4K6hg',
  appId: '1:965440046912:web:1c6e1459bc0465fa10dca5',
  messagingSenderId: '965440046912',
  projectId: 'watchy-ce045',
  authDomain: 'watchy-ce045.firebaseapp.com',
  storageBucket: 'watchy-ce045.firebasestorage.app',
  databaseURL: 'https://watchy-ce045-default-rtdb.firebaseio.com',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("Background message received. ", payload);
});
