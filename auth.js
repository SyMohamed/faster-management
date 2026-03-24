/**
 * auth.js — Shared authentication guard for FASTER Lab workspace.
 * Include this script in <head> of every sub-page (BEFORE any other scripts).
 * Redirects to index.html if the user has not passed the password check.
 */
(function () {
  var KEY = 'faster_auth_v1';
  if (sessionStorage.getItem(KEY) !== 'ok') {
    // Preserve the intended destination so index.html can redirect back after login
    try { sessionStorage.setItem('faster_redirect', location.href); } catch(e){}
    location.replace('index.html');
  }
})();
