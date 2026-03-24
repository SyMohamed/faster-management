/**
 * auth.js — Shared authentication guard for FASTER Lab workspace.
 * Include this script in <head> of every sub-page (BEFORE any other scripts).
 * Redirects to index.html if the user has not signed in.
 *
 * Also exposes helper globals for sub-pages:
 *   window.FASTER_USER  — display name (e.g. "Waleed Ahmad")
 *   window.FASTER_UNAME — username (e.g. "waleed")
 *   window.FASTER_ROLE  — "admin" | "member"
 *   window.FASTER_IS_ADMIN — boolean
 */
(function () {
  var AUTH_KEY  = 'faster_auth_v1';
  var USER_KEY  = 'faster_user_v1';
  var UNAME_KEY = 'faster_uname_v1';
  var ROLE_KEY  = 'faster_role_v1';

  if (sessionStorage.getItem(AUTH_KEY) !== 'ok') {
    try { sessionStorage.setItem('faster_redirect', location.href); } catch(e){}
    location.replace('index.html');
    return; // stop execution
  }

  // Expose session info for sub-page scripts
  window.FASTER_USER  = sessionStorage.getItem(USER_KEY) || '';
  window.FASTER_UNAME = sessionStorage.getItem(UNAME_KEY) || '';
  window.FASTER_ROLE  = sessionStorage.getItem(ROLE_KEY) || 'member';
  window.FASTER_IS_ADMIN = window.FASTER_ROLE === 'admin';

  // Auto-set admin session flag for sub-pages that check it
  if (window.FASTER_IS_ADMIN) {
    sessionStorage.setItem('fa', '1');
  }
})();
