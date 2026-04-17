/**
 * auth.js — Shared authentication guard for FASTER Lab workspace.
 * Include this script in <head> of every sub-page (BEFORE any other scripts).
 * Redirects to index.html if the user has not signed in.
 *
 * Exposes globals for sub-pages:
 *   window.FASTER_USER      — display name  (e.g. "Waleed Ahmad")
 *   window.FASTER_UNAME     — username      (e.g. "waleed")
 *   window.FASTER_ROLE      — "admin" | "member" | "viewer"
 *   window.FASTER_IS_ADMIN  — boolean
 *   window.FASTER_READONLY  — boolean (true for guest/viewer mode)
 *
 * Also handles dark/light theme preference (persisted in localStorage).
 */

/* ── Apply saved theme IMMEDIATELY (before first paint) ───────────────────── */
(function(){
  if(localStorage.getItem('faster_theme')==='light')
    document.documentElement.setAttribute('data-theme','light');
  else
    document.documentElement.removeAttribute('data-theme');
})();

/* ── Theme toggle logic + button injection ────────────────────────────────── */
window.FASTER_toggleTheme = function(){
  var isLight = document.documentElement.getAttribute('data-theme')==='light';
  if(isLight){
    document.documentElement.removeAttribute('data-theme');
    localStorage.setItem('faster_theme','dark');
  } else {
    document.documentElement.setAttribute('data-theme','light');
    localStorage.setItem('faster_theme','light');
  }
  var btn = document.getElementById('faster-theme-btn');
  if(btn) btn.title = isLight ? 'Switch to light mode' : 'Switch to dark mode';
  if(btn) btn.textContent = isLight ? '☀️' : '🌙';
};

document.addEventListener('DOMContentLoaded', function(){
  /* Inject the toggle button into the page's top-right nav area */
  var isLight = document.documentElement.getAttribute('data-theme')==='light';
  var btn = document.createElement('button');
  btn.id = 'faster-theme-btn';
  btn.title = isLight ? 'Switch to dark mode' : 'Switch to light mode';
  btn.textContent = isLight ? '🌙' : '☀️';
  btn.onclick = window.FASTER_toggleTheme;

  /* Try to find the header's right-side action area on any sub-page nav */
  var slot = document.querySelector('.nav-right, .nav-r, .header-right, .hdr-right, .nav-actions, [data-theme-slot]');
  if(!slot){
    /* Fallback: find the <nav> element and append to it */
    var nav = document.querySelector('nav');
    if(nav){
      var wrap = document.createElement('div');
      wrap.style.cssText='margin-left:auto;display:flex;align-items:center;gap:8px';
      wrap.appendChild(btn);
      nav.appendChild(wrap);
      return;
    }
  }
  if(slot) slot.insertBefore(btn, slot.firstChild);
});

(function () {
  var AUTH_KEY  = 'faster_auth_v1';
  var USER_KEY  = 'faster_user_v1';
  var UNAME_KEY = 'faster_uname_v1';
  var ROLE_KEY  = 'faster_role_v1';

  if (sessionStorage.getItem(AUTH_KEY) !== 'ok') {
    try { sessionStorage.setItem('faster_redirect', location.href); } catch(e){}
    location.replace('index.html');
    return;
  }

  window.FASTER_USER     = sessionStorage.getItem(USER_KEY)  || '';
  window.FASTER_UNAME    = sessionStorage.getItem(UNAME_KEY) || '';
  window.FASTER_ROLE     = sessionStorage.getItem(ROLE_KEY)  || 'member';
  window.FASTER_IS_ADMIN = window.FASTER_ROLE === 'admin';
  window.FASTER_READONLY = window.FASTER_ROLE === 'viewer';

  /* Auto-set admin flag for sub-pages (assets.html etc.) */
  if (window.FASTER_IS_ADMIN) {
    sessionStorage.setItem('fa', '1');
  }

  /* ── Read-only mode restrictions ───────────────────────────────────── */
  if (window.FASTER_READONLY) {

    document.addEventListener('DOMContentLoaded', function () {
      /* Readonly banner at bottom of page */
      var banner = document.createElement('div');
      banner.id = 'faster-readonly-banner';
      banner.style.cssText = [
        'position:fixed', 'bottom:0', 'left:0', 'right:0',
        'background:#f59e0b', 'color:#000',
        'text-align:center', 'padding:9px 16px',
        'font-size:15px', 'font-weight:600',
        'z-index:9990', 'font-family:monospace',
        'box-shadow:0 -2px 12px rgba(0,0,0,.3)'
      ].join(';');
      banner.innerHTML = '\uD83D\uDC41 View-only mode &mdash; ' +
        '<a href="index.html" style="color:inherit;text-decoration:underline">sign in as a member</a>' +
        ' to make changes';
      document.body.appendChild(banner);

      /* Add extra bottom padding so banner doesn't overlap content */
      document.body.style.paddingBottom = '48px';
    });

    /* Block all form submissions */
    document.addEventListener('submit', function (e) {
      e.preventDefault();
      e.stopImmediatePropagation();
      _readonlyToast();
    }, true);

    /* Block write button clicks (heuristic: text or onclick contains write keywords) */
    var WRITE_WORDS = ['add','creat','save','delet','remov','updat','edit',
                       'submit','approv','reject','log','export','import','new '];
    document.addEventListener('click', function (e) {
      var el = e.target.closest('button, [role="button"]');
      if (!el) return;
      var text = (el.textContent + ' ' + (el.getAttribute('onclick') || '')).toLowerCase();
      if (WRITE_WORDS.some(function(w){ return text.includes(w); })) {
        e.preventDefault();
        e.stopImmediatePropagation();
        _readonlyToast();
      }
    }, true);
  }

  function _readonlyToast() {
    var existing = document.getElementById('_ro_toast');
    if (existing) return;
    var t = document.createElement('div');
    t.id = '_ro_toast';
    t.style.cssText = [
      'position:fixed', 'top:22px', 'left:50%',
      'transform:translateX(-50%)',
      'background:#f59e0b', 'color:#000',
      'padding:10px 22px', 'border-radius:9px',
      'z-index:99999', 'font-size:15px',
      'font-family:monospace', 'font-weight:600',
      'pointer-events:none', 'transition:opacity .4s'
    ].join(';');
    t.textContent = '\uD83D\uDC41 View-only \u2014 sign in as a member to make changes';
    document.body.appendChild(t);
    setTimeout(function () {
      t.style.opacity = '0';
      setTimeout(function () { t.remove(); }, 400);
    }, 2500);
  }
})();

/* ═══════════════════════════════════════════════════════════════════════════
   IN-APP NOTIFICATION BELL — shows on every sub-page
   ═══════════════════════════════════════════════════════════════════════════ */
(function(){
  var uname = sessionStorage.getItem('faster_uname_v1');
  if(!uname) return;

  /* ── Inject bell HTML ─────────────────────────────────────────────────── */
  document.addEventListener('DOMContentLoaded', function(){
    var slot = document.querySelector('.nav-right, .nav-r, .header-right, .hdr-right, .nav-actions');
    if(!slot) return;

    var bellWrap = document.createElement('div');
    bellWrap.id = 'notif-bell-wrap';
    bellWrap.style.cssText = 'position:relative;display:inline-flex';
    bellWrap.innerHTML =
      '<button id="notif-bell-btn" style="background:var(--s2,var(--surface2,#181f2a));border:1px solid var(--b1,var(--border,#232e3d));border-radius:8px;width:34px;height:34px;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:16px;position:relative;transition:border-color .15s;flex-shrink:0" title="Notifications">🔔' +
        '<span id="notif-badge" style="display:none;position:absolute;top:-4px;right:-4px;background:#ef4444;color:#fff;font-size:9px;font-weight:700;min-width:16px;height:16px;border-radius:99px;display:flex;align-items:center;justify-content:center;font-family:monospace;padding:0 4px;border:2px solid var(--bg,#0d1117)"></span>' +
      '</button>' +
      '<div id="notif-dropdown" style="display:none;position:absolute;top:calc(100% + 6px);right:0;width:320px;max-height:400px;overflow-y:auto;background:var(--s1,var(--surface,#161b22));border:1px solid var(--b2,var(--border2,#2e3f54));border-radius:12px;box-shadow:0 12px 40px rgba(0,0,0,.5);z-index:9500;padding:6px 0">' +
        '<div style="padding:8px 14px;font-size:11px;font-weight:700;color:var(--muted,#6a7d94);text-transform:uppercase;letter-spacing:.5px;font-family:monospace;border-bottom:1px solid var(--b1,var(--border,#232e3d));display:flex;justify-content:space-between;align-items:center">Notifications<button id="notif-clear-btn" style="background:none;border:none;color:var(--muted,#6a7d94);cursor:pointer;font-size:10px;font-family:monospace">Mark all read</button></div>' +
        '<div id="notif-list"></div>' +
      '</div>';

    var themeBtn = document.getElementById('faster-theme-btn');
    if(themeBtn && themeBtn.parentNode === slot){
      slot.insertBefore(bellWrap, themeBtn);
    } else {
      slot.insertBefore(bellWrap, slot.firstChild);
    }

    document.getElementById('notif-bell-btn').onclick = function(e){
      e.stopPropagation();
      var dd = document.getElementById('notif-dropdown');
      dd.style.display = dd.style.display === 'none' ? 'block' : 'none';
    };
    document.getElementById('notif-clear-btn').onclick = function(){
      _markAllRead();
    };
    document.addEventListener('click', function(e){
      if(!e.target.closest('#notif-bell-wrap')){
        document.getElementById('notif-dropdown').style.display = 'none';
      }
    });

    _initNotifListener();
  });

  /* ── Firebase notification listener ───────────────────────────────────── */
  var _notifRef = null;
  var _notifs = {};

  function _initNotifListener(){
    var checkFB = setInterval(function(){
      if(typeof firebase === 'undefined' || !firebase.apps || !firebase.apps.length) return;
      clearInterval(checkFB);
      try {
        var db = firebase.app().database();
        _notifRef = db.ref('faster_notifications/' + uname);
        _notifRef.orderByChild('_ts').limitToLast(30).on('value', function(snap){
          _notifs = snap.val() || {};
          _renderNotifs();
        });
      } catch(e){ /* Firebase not ready yet */ }
    }, 500);
  }

  function _renderNotifs(){
    var entries = Object.entries(_notifs).map(function(kv){ return {id:kv[0], n:kv[1]}; });
    entries.sort(function(a,b){ return (b.n._ts||0) - (a.n._ts||0); });
    var unread = entries.filter(function(e){ return !e.n.read; }).length;

    var badge = document.getElementById('notif-badge');
    if(badge){
      if(unread > 0){
        badge.textContent = unread > 9 ? '9+' : unread;
        badge.style.display = 'flex';
      } else {
        badge.style.display = 'none';
      }
    }

    var list = document.getElementById('notif-list');
    if(!list) return;
    if(!entries.length){
      list.innerHTML = '<div style="padding:24px 14px;text-align:center;color:var(--muted,#6a7d94);font-size:12px">No notifications yet</div>';
      return;
    }

    list.innerHTML = entries.map(function(e){
      var n = e.n;
      var bg = n.read ? '' : 'background:var(--s2,var(--surface2,rgba(255,255,255,.03)));';
      var icon = n.type === 'approved' ? '✅' : n.type === 'done' ? '🏁' : n.type === 'rejected' ? '↩️' : n.type === 'assigned' ? '📋' : '🔔';
      var time = n._ts ? _timeAgo(n._ts) : '';
      var href = n.href || '#';
      return '<a href="' + href + '" style="display:flex;gap:10px;padding:10px 14px;text-decoration:none;color:inherit;transition:background .1s;border-bottom:1px solid var(--b1,var(--border,#232e3d));' + bg + '" onclick="window._markNotifRead(\'' + e.id + '\')" onmouseover="this.style.background=\'var(--s2,rgba(255,255,255,.05))\'" onmouseout="this.style.background=\'' + (n.read?'':'var(--s2,rgba(255,255,255,.03))') + '\'">' +
        '<div style="font-size:16px;flex-shrink:0;margin-top:2px">' + icon + '</div>' +
        '<div style="flex:1;min-width:0">' +
          '<div style="font-size:12px;color:var(--text,#e6edf3);line-height:1.4' + (n.read?'':';font-weight:600') + '">' + _escN(n.message||'Notification') + '</div>' +
          '<div style="font-size:10px;color:var(--muted,#6a7d94);font-family:monospace;margin-top:2px">' + time + '</div>' +
        '</div>' +
        (!n.read ? '<div style="width:8px;height:8px;border-radius:50%;background:#3b82f6;flex-shrink:0;margin-top:6px"></div>' : '') +
      '</a>';
    }).join('');
  }

  window._markNotifRead = function(id){
    if(!_notifRef) return;
    _notifRef.child(id + '/read').set(true);
  };

  function _markAllRead(){
    if(!_notifRef) return;
    var updates = {};
    Object.keys(_notifs).forEach(function(id){
      if(!_notifs[id].read) updates[id + '/read'] = true;
    });
    if(Object.keys(updates).length) _notifRef.update(updates);
  }

  function _timeAgo(ts){
    var diff = (Date.now() - ts) / 1000;
    if(diff < 60) return 'just now';
    if(diff < 3600) return Math.floor(diff/60) + 'm ago';
    if(diff < 86400) return Math.floor(diff/3600) + 'h ago';
    if(diff < 604800) return Math.floor(diff/86400) + 'd ago';
    return new Date(ts).toLocaleDateString();
  }

  function _escN(s){
    var d = document.createElement('div');
    d.textContent = s;
    return d.innerHTML;
  }

  /* ── Global helper to send notifications from any page ────────────────── */
  window.FASTER_notify = function(targetUname, message, type, href){
    if(!targetUname) return Promise.resolve();
    try {
      var db = firebase.app().database();
      return db.ref('faster_notifications/' + targetUname).push({
        message: message,
        type: type || 'info',
        href: href || '',
        read: false,
        _ts: Date.now()
      });
    } catch(e){ return Promise.resolve(); }
  };

  /* ── Global helper to send email notification ─────────────────────────── */
  window.FASTER_emailNotify = function(targetUname, subject, message){
    try {
      var db = firebase.app().database();
      if(!targetUname) return;
      db.ref('faster_users/' + targetUname + '/email').once('value', function(uSnap){
        var email = uSnap.val();
        if(!email) return;
        db.ref('faster_config/emailjs').once('value', function(cfgSnap){
          var cfg = cfgSnap.val();
          if(!cfg || !cfg.serviceId || !cfg.templateId || !cfg.publicKey) return;
          if(typeof emailjs === 'undefined'){
            var s = document.createElement('script');
            s.src = 'https://cdn.jsdelivr.net/npm/@emailjs/browser@4/dist/email.min.js';
            s.onload = function(){ _doSendEmail(cfg, email, subject, message); };
            document.head.appendChild(s);
          } else {
            _doSendEmail(cfg, email, subject, message);
          }
        });
      });
    } catch(e){}
  };

  function _doSendEmail(cfg, toEmail, subject, message){
    try {
      emailjs.init(cfg.publicKey);
      emailjs.send(cfg.serviceId, cfg.templateId, {
        to_email: toEmail,
        subject: subject || 'FASTER Lab Notification',
        message: message
      }).catch(function(){});
    } catch(e){}
  }
})();
