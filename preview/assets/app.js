/**
 * Sound of Safety — static demo mirroring app flows (Netlify-ready).
 * localStorage demo auth + mock /check-url style results; optional real API.
 */

const PHRASE_SAFE = 'الرابط آمن';
const PHRASE_UNSAFE = 'تحذير، هذا الرابط غير آمن';

const LS = {
  session() {
    return {
      users: JSON.parse(localStorage.getItem('sos_demo_users') || '[]'),
      history: JSON.parse(localStorage.getItem('sos_demo_history') || '[]'),
      settings: JSON.parse(
        localStorage.getItem('sos_demo_settings') ||
          '{"apiBase":"","clipboardMonitor":true,"loggedUser":null,"pendingSignup":null}'
      ),
    };
  },
  saveSettings(s) {
    localStorage.setItem('sos_demo_settings', JSON.stringify(s));
  },
  saveHistory(h) {
    localStorage.setItem('sos_demo_history', JSON.stringify(h.slice(0, 200)));
  },
  saveUsers(u) {
    localStorage.setItem('sos_demo_users', JSON.stringify(u));
  },
};

function escapeHtml(text) {
  const d = document.createElement('div');
  d.textContent = text;
  return d.innerHTML;
}

function simpleHash(pw) {
  let h = 0;
  for (let i = 0; i < pw.length; i++) {
    h = (Math.imul(31, h) + pw.charCodeAt(i)) | 0;
  }
  return String(h);
}

function navigateShow(id) {
  document.querySelectorAll('.screen').forEach((el) => {
    const on = el.id === id;
    el.classList.toggle('active', on);
    el.setAttribute('aria-hidden', on ? 'false' : 'true');
  });
  const tabBar = document.getElementById('tabBar');
  const onMain = id === 'main-check' || id === 'main-history' || id === 'main-settings';
  if (tabBar) tabBar.hidden = !onMain;
}

function speakArabic(text) {
  if (!window.speechSynthesis) return;
  speechSynthesis.cancel();
  const u = new SpeechSynthesisUtterance(text);
  u.lang = 'ar-SA';
  const ar = speechSynthesis.getVoices().filter((v) => v.lang.startsWith('ar'));
  if (ar.length) u.voice = ar[0];
  speechSynthesis.speak(u);
}

function mockCheckRemote(urlStr) {
  const s = (urlStr || '').trim().toLowerCase();
  const suspicious =
    /phish|malware|login-verify|fake-bank|steal-wallet|evil-|\.zip(\?|$)/i.test(s);
  if (suspicious) {
    return Promise.resolve({
      is_safe: false,
      confidence: 0.88,
      reasons: [
        'نمط ضمن قائمة تهديدات تجريبية في العرض التوضيحي.',
        'يُفضّل التحقق عبر المصدر الرسمي قبل إدخال بيانات.',
      ],
    });
  }
  return Promise.resolve({
    is_safe: true,
    confidence: 0.92,
    reasons: [
      'لا تطابق تقريبي مع أنماط شائعة في العرض التوضيحي.',
      'الفحص الحقيقي يتم عبر خادمك في التطبيق الأصلي.',
    ],
  });
}

function renderHistory() {
  const { history } = LS.session();
  const ul = document.getElementById('historyList');
  const empty = document.getElementById('historyEmpty');
  ul.innerHTML = '';

  if (!history.length) {
    empty.hidden = false;
    return;
  }
  empty.hidden = true;

  history.forEach((item) => {
    const li = document.createElement('li');
    li.className = 'history-item';
    const badgeClass = item.is_safe ? 'safe' : 'unsafe';
    const badgeText = item.is_safe ? 'آمن' : 'غير آمن';
    li.innerHTML =
      `<p class="url-line">${escapeHtml(item.url)}<span class="badge-mini ${badgeClass}">${badgeText}</span></p>` +
      `<p class="meta">${Math.round(item.confidence * 100)}% ثقة · ${escapeHtml(item.at)}</p>`;
    ul.appendChild(li);
  });
}

function addHistoryEntry(url, result) {
  const { history } = LS.session();
  const row = {
    url,
    is_safe: result.is_safe,
    confidence: result.confidence,
    at: new Date().toLocaleString('ar-SA', { hour: '2-digit', minute: '2-digit', dateStyle: 'medium' }),
  };
  history.unshift(row);
  LS.saveHistory(history);
}

const state = { authTab: 'login' };
let lastClipboard = '';

async function tryLiveApi(baseRaw, url) {
  const base = baseRaw.trim().replace(/\/$/, '');
  const endpoint = `${base}/check-url`;
  const res = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({ url }),
  });
  if (!res.ok) throw new Error('HTTP');
  const j = await res.json();
  if (typeof j.is_safe !== 'boolean' || typeof j.confidence !== 'number') throw new Error('shape');
  return {
    is_safe: j.is_safe,
    confidence: j.confidence,
    reasons: Array.isArray(j.reasons) ? j.reasons : [],
  };
}

function updateTabCurrent(id) {
  document.querySelectorAll('.tab-bar button').forEach((b) => {
    b.setAttribute('aria-current', b.id === id ? 'page' : 'false');
  });
}

function restoreMainFromSession() {
  const u = LS.session().settings.loggedUser;
  document.getElementById('welcomeName').textContent = u ? u.username || '' : '';
}

function wireTabs() {
  document.getElementById('tab-check').onclick = () => {
    navigateShow('main-check');
    updateTabCurrent('tab-check');
  };
  document.getElementById('tab-history').onclick = () => {
    navigateShow('main-history');
    updateTabCurrent('tab-history');
    renderHistory();
  };
  document.getElementById('tab-settings').onclick = () => {
    navigateShow('main-settings');
    updateTabCurrent('tab-settings');
    loadSettingsUi();
  };
}

function wireAuth() {
  const authLogin = document.getElementById('authLoginPane');
  const authReg = document.getElementById('authRegisterPane');

  document.getElementById('tabLogin').onclick = () => {
    state.authTab = 'login';
    authLogin.hidden = false;
    authReg.hidden = true;
    document.getElementById('tabLogin').setAttribute('aria-selected', 'true');
    document.getElementById('tabRegister').setAttribute('aria-selected', 'false');
  };
  document.getElementById('tabRegister').onclick = () => {
    state.authTab = 'register';
    authLogin.hidden = true;
    authReg.hidden = false;
    document.getElementById('tabRegister').setAttribute('aria-selected', 'true');
    document.getElementById('tabLogin').setAttribute('aria-selected', 'false');
  };

  document.getElementById('btnRegisterContinue').onclick = () => doRegister();
  document.getElementById('btnOtpVerify').onclick = () => doOtp();
  document.getElementById('btnOtpBack').onclick = () => navigateShow('auth');
  document.getElementById('btnLoginSubmit').onclick = () => doLogin();
}

function doRegister() {
  const username = document.getElementById('regUsername').value.trim();
  const email = document.getElementById('regEmail').value.trim().toLowerCase();
  const pw = document.getElementById('regPassword').value;
  const pw2 = document.getElementById('regPassword2').value;
  const errEl = document.getElementById('regError');
  errEl.textContent = '';

  if (!username || !email.includes('@')) errEl.textContent = 'تحقق من الاسم والبريد.';
  else if (pw.length < 8) errEl.textContent = 'كلمة المرور يجب ألا تقل عن ٨ أحرف.';
  else if (pw !== pw2) errEl.textContent = 'كلمة المرور وتأكيدها غير متطابقتين.';

  if (errEl.textContent) return;

  const { users } = LS.session();
  if (users.some((u) => u.email === email)) {
    errEl.textContent = 'البريد مسجَّل مسبقاً.';
    return;
  }

  const otp = String(Math.floor(100000 + Math.random() * 900000));
  const signup = { username, email, passwordHash: simpleHash(pw), otp };

  const settings = LS.session().settings;
  settings.pendingSignup = signup;
  LS.saveSettings(settings);

  document.getElementById('otpEmail').textContent = email;
  document.getElementById('otpHint').innerHTML =
    `<strong>للعرض التجريبي فقط:</strong> رمز التحقق هو <code>${otp}</code>`;
  document.getElementById('otpInput').value = '';
  navigateShow('otp');
}

function doOtp() {
  const settings = LS.session().settings;
  const pending = settings.pendingSignup;
  const entered = document.getElementById('otpInput').value.trim();
  const err = document.getElementById('otpError');
  err.textContent = '';

  if (!pending) {
    err.textContent = 'لا يوجد تسجيل قيد المعالجة. أعد المحاولة من التسجيل.';
    return;
  }
  if (entered !== pending.otp) {
    err.textContent = 'الرمز غير صحيح.';
    return;
  }

  let { users } = LS.session();
  users.push({
    username: pending.username,
    email: pending.email,
    passwordHash: pending.passwordHash,
    verified: true,
  });
  LS.saveUsers(users);

  settings.loggedUser = { username: pending.username, email: pending.email };
  settings.pendingSignup = null;
  LS.saveSettings(settings);

  document.getElementById('welcomeName').textContent = pending.username;
  navigateShow('main-check');
  updateTabCurrent('tab-check');
}

function doLogin() {
  const email = document.getElementById('loginEmail').value.trim().toLowerCase();
  const pw = document.getElementById('loginPassword').value;
  const errEl = document.getElementById('loginError');
  errEl.textContent = '';

  const { users } = LS.session();
  const user = users.find((u) => u.email === email && u.verified);
  if (!user || user.passwordHash !== simpleHash(pw)) {
    errEl.textContent = 'بريد أو كلمة مرور غير صحيحة.';
    return;
  }

  const settings = LS.session().settings;
  settings.loggedUser = { username: user.username, email: user.email };
  LS.saveSettings(settings);

  document.getElementById('welcomeName').textContent = user.username;
  navigateShow('main-check');
  updateTabCurrent('tab-check');
}

function wireCheck() {
  document.getElementById('btnCheckUrl').onclick = async () => {
    const inp = document.getElementById('checkUrlInput');
    const url = inp.value.trim();
    const zone = document.getElementById('checkResultZone');
    const errEl = document.getElementById('checkError');

    zone.hidden = true;
    errEl.textContent = '';
    document.getElementById('feedbackThanks').hidden = true;

    if (!url) {
      errEl.textContent = 'أدخل رابطاً للتحقق.';
      return;
    }

    const loading = document.getElementById('checkLoading');
    loading.hidden = false;
    document.getElementById('btnCheckUrl').disabled = true;

    let raw;
    try {
      await new Promise((r) => setTimeout(r, 600));
      const settings = LS.session().settings;
      raw = settings.apiBase ? await tryLiveApi(settings.apiBase, url).catch(() => null) : null;
      if (!raw) raw = await mockCheckRemote(url);
    } catch {
      errEl.textContent = 'تعذّر الفحص. جرّب لاحقاً.';
      loading.hidden = true;
      document.getElementById('btnCheckUrl').disabled = false;
      return;
    }

    loading.hidden = true;
    document.getElementById('btnCheckUrl').disabled = false;

    const isSafe = raw.is_safe;
    const badge = document.getElementById('resultBadge');
    badge.textContent = isSafe ? 'آمن SAFE' : 'غير آمن UNSAFE';
    badge.className = `result-badge ${isSafe ? 'result-safe' : 'result-unsafe'}`;
    badge.setAttribute('aria-label', isSafe ? 'نتيجة: آمن' : 'نتيجة: غير آمن');

    document.getElementById('confidenceLine').textContent =
      `نسبة الثقة: ${Math.round(Number(raw.confidence) * 100)}%`;

    const reasons = Array.isArray(raw.reasons) ? raw.reasons : [];
    document.getElementById('reasonsList').innerHTML = reasons
      .map((x) => `<li>${escapeHtml(String(x))}</li>`)
      .join('');

    zone.hidden = false;
    addHistoryEntry(url, raw);
    renderHistory();
    speakArabic(isSafe ? PHRASE_SAFE : PHRASE_UNSAFE);

    document.getElementById('feedbackSafe').onclick = () => submitFeedback(url, true);
    document.getElementById('feedbackUnsafe').onclick = () => submitFeedback(url, false);
  };

  document.getElementById('btnSpeakAgain').onclick = () => {
    const inp = document.getElementById('checkUrlInput').value.trim();
    if (!inp) {
      speakArabic('أدخل رابطاً ثم استخدم تحقق من الرابط.');
      return;
    }
    mockCheckRemote(inp).then((r) => speakArabic(r.is_safe ? PHRASE_SAFE : PHRASE_UNSAFE));
  };
}

function submitFeedback(url, reportedSafe) {
  const fb = JSON.parse(localStorage.getItem('sos_demo_feedback') || '[]');
  fb.unshift({ url, reportedSafe, at: new Date().toISOString() });
  localStorage.setItem('sos_demo_feedback', JSON.stringify(fb.slice(0, 50)));
  document.getElementById('feedbackThanks').hidden = false;
  speakArabic(
    reportedSafe ? 'شكراً، تم تسجيل ملاحظتك كرابط يبدو آمناً.' : 'شكراً، تم تسجيل ملاحظتك.'
  );
}

function wireHistory() {
  document.getElementById('btnClearHistory').onclick = () => {
    LS.saveHistory([]);
    renderHistory();
  };
}

function loadSettingsUi() {
  const s = LS.session().settings;
  document.getElementById('setApi').value = s.apiBase || '';
  document.getElementById('setClipboard').checked = s.clipboardMonitor !== false;
}

function wireSettings() {
  document.getElementById('btnSaveApi').onclick = () => {
    const s = LS.session().settings;
    const v = document.getElementById('setApi').value.trim();
    const msgEl = document.getElementById('apiSaveNote');

    if (v.length && !(v.startsWith('http://') || v.startsWith('https://'))) {
      msgEl.textContent = 'استخدم عنواناً يبدأ بـ https:// أو http://';
      return;
    }
    try {
      if (v) new URL(v);
    } catch {
      msgEl.textContent = 'عنوان غير صالح.';
      return;
    }

    s.apiBase = v;
    LS.saveSettings(s);
    msgEl.textContent = v
      ? 'تم الحفظ. سيتم استدعاء …/check-url عند وجود عنوان (قد تحتاج CORS على الخادم).'
      : 'تم المسح. يُستخدم محاكي محلي للعرض فقط.';
  };

  document.getElementById('setClipboard').onchange = () => {
    const s = LS.session().settings;
    s.clipboardMonitor = document.getElementById('setClipboard').checked;
    LS.saveSettings(s);
  };

  document.getElementById('btnLogout').onclick = () => {
    const s = LS.session().settings;
    s.loggedUser = null;
    LS.saveSettings(s);
    lastClipboard = '';
    navigateShow('auth');
    document.getElementById('tabBar').hidden = true;
  };
}

function trimDisplay(t) {
  const m = 72;
  if (t.length <= m) return t;
  return `${t.slice(0, m)}…`;
}

function showClipboardWarning(text) {
  mockCheckRemote(text).then((result) => {
    if (!result.is_safe && document.visibilityState === 'visible') {
      speakArabic(PHRASE_UNSAFE);
      const banner = document.getElementById('clipboardBanner');
      banner.textContent = `تنبيه الحافظة (محاكاة): الرابط يبدو غير آمناً — «${trimDisplay(text)}» — ثقة تقريبية ${Math.round(result.confidence * 100)}%.`;
      banner.classList.add('show');
    }
  });
}

async function probeClipboard() {
  const s = LS.session().settings;
  const banner = document.getElementById('clipboardBanner');
  banner.classList.remove('show');
  banner.textContent = '';

  if (!s.loggedUser || s.clipboardMonitor === false) return;

  let text;
  try {
    text = await navigator.clipboard.readText();
  } catch {
    return;
  }

  text = text.trim();
  const looksLike = /(^https?:\/\/)|(^\w+\.\w+)/i.test(text) && /\./.test(text) && text.length > 6;

  if (!looksLike || text === lastClipboard) return;
  lastClipboard = text;
  await new Promise((r) => setTimeout(r, 400));
  showClipboardWarning(text);
}

function wireClipboard() {
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') probeClipboard();
  });
  window.addEventListener('focus', () => probeClipboard());
}

function bootstrap() {
  navigateShow('splash');
  speechSynthesis.addEventListener('voiceschanged', () => {});

  setTimeout(() => {
    const settings = LS.session().settings;
    navigateShow(settings.loggedUser ? 'main-check' : 'auth');
    document.getElementById('tabBar').hidden = !settings.loggedUser;

    wireTabs();
    wireAuth();
    wireCheck();
    wireHistory();
    wireSettings();
    wireClipboard();

    updateTabCurrent('tab-check');

    if (settings.loggedUser) restoreMainFromSession();
    renderHistory();
    loadSettingsUi();

    probeClipboard();
  }, 2000);
}

bootstrap();
