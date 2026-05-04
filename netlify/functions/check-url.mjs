/**
 * حقيقي: فحص رابط من الخادم — طلبات HTTP فعلية + Google Safe Browsing (اختياري) + وسائل إسقاط OWASP SSRF أساسية.
 * متغيرات بيئة Netlify (اختيارية):
 *   GOOGLE_SAFE_BROWSING_API_KEY — مفتاح Google Safe Browsing v4 API
 */

import dns from 'node:dns/promises';
import net from 'node:net';

const MAX_REDIRECTS = 8;
const FETCH_TIMEOUT_MS = 12_000;
const DISALLOWED_HOSTNAMES = new Set([
  'localhost',
  'metadata.google.internal',
  'metadata',
  '0.0.0.0',
]);

function corsHeaders(extra = {}) {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    ...extra,
  };
}

function isPrivateOrReservedIPv4(parts) {
  const [a, b] = parts;
  if (a === 10) return true;
  if (a === 127) return true;
  if (a === 0) return true;
  if (a === 169 && b === 254) return true;
  if (a === 192 && b === 168) return true;
  if (a === 172 && b >= 16 && b <= 31) return true;
  if (a >= 224) return true;
  if (a === 100 && b >= 64 && b <= 127) return true;
  return false;
}

class SSRFError extends Error {
  constructor(msg) {
    super(msg);
    this.name = 'SSRFError';
  }
}

async function hostnameResolvesSafe(hostname) {
  const h = hostname.toLowerCase();
  if (DISALLOWED_HOSTNAMES.has(h)) throw new SSRFError('Hostname غير مسموح');
  if (
    /\.local$/i.test(h) ||
    h.endsWith('.internal') ||
    h.endsWith('.localhost')
  )
    throw new SSRFError('نطاق داخلي مرفوض');

  try {
    const ips = await dns.lookup(h, { all: true, verbatim: true });
    for (const { address } of ips) {
      if (net.isIPv4(address)) {
        const p = address.split('.').map(Number);
        if (isPrivateOrReservedIPv4(p)) throw new SSRFError('عنوان IP داخلي (IPv4)');
      } else if (net.isIPv6(address)) {
        const lc = address.toLowerCase();
        if (lc === '::1') throw new SSRFError('عنوان IP داخلي (IPv6)');
        if (/^fc[0-9a-f]/i.test(lc) || lc.startsWith('fd')) throw new SSRFError('IPv6 خاص محلي');
        if (lc.startsWith('fe80:')) throw new SSRFError('IPv6 محلي الرابط');
      }
    }
  } catch (e) {
    if (e instanceof SSRFError) throw e;
    throw new Error('DOMAIN_RESOLUTION_FAILED');
  }
}

function normalizeInitialUrl(raw) {
  let t = (raw || '').trim();
  if (!t) throw new Error('EMPTY');
  if (!/^https?:\/\//i.test(t)) t = `https://${t}`;
  let u;
  try {
    u = new URL(t);
  } catch {
    throw new Error('BAD_URL');
  }
  if (u.protocol !== 'http:' && u.protocol !== 'https:')
    throw new Error('UNSUPPORTED_SCHEME');
  if (!u.hostname) throw new Error('NO_HOST');
  return u;
}

async function assertUrlPassesSsrfChecks(u) {
  await hostnameResolvesSafe(u.hostname);
}

/** يفرغ جزءاً صغيراً من الجسم لتفادي تعليق الاتصالات دون تحميل ملفات ضخمة */
async function drainLimitedResponse(res, maxBytes = 16_384) {
  if (!res.body) return;
  const reader = res.body.getReader();
  let total = 0;
  try {
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      total += value?.length || 0;
      if (total >= maxBytes) break;
    }
  } finally {
    try {
      reader.releaseLock();
    } catch {
      /* ignore */
    }
  }
}

async function googleSafeBrowsingLookup(pageUrl, apiKey) {
  if (!apiKey) return null;
  const endpoint = `https://safebrowsing.googleapis.com/v4/threatMatches:find?key=${encodeURIComponent(apiKey)}`;
  const body = {
    client: { clientId: 'sound-of-safety', clientVersion: '1.0.0' },
    threatInfo: {
      threatTypes: ['MALWARE', 'SOCIAL_ENGINEERING', 'UNWANTED_SOFTWARE'],
      platformTypes: ['ANY_PLATFORM'],
      threatEntryTypes: ['URL'],
      threatEntries: [{ url: pageUrl }],
    },
  };

  const res = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (!res.ok)
    throw new Error(`SAFE_BROWSING_HTTP_${res.status}`);

  const data = await res.json();
  if (data.matches && data.matches.length) return data.matches;

  return null;
}

async function fetchWithRedirects(startUrl, reasons) {
  let current = startUrl.href;
  const chain = [];

  const controllerAbort = () => AbortSignal.timeout(FETCH_TIMEOUT_MS);

  for (let hop = 0; hop <= MAX_REDIRECTS; hop++) {
    const u = new URL(current);

    chain.push(`${u.hostname}${u.pathname}`.slice(0, 200));
    await assertUrlPassesSsrfChecks(u);

    try {
      const res = await fetch(current, {
        method: 'GET',
        redirect: 'manual',
        signal: controllerAbort(),
        headers: {
          'User-Agent':
            'SoundOfSafety/1.0 (security-analysis; https://github.com)',
          Accept: 'text/html,application/xhtml+xml,*/*;q=0.8',
        },
      });

      if ([301, 302, 303, 307, 308].includes(res.status)) {
        const loc = res.headers.get('location');
        if (!loc) {
          reasons.push(`إعادة توجيه ${res.status} بدون عنوان Location.`);
          return { ok: false, finalUrl: current, chain, status: res.status };
        }
        const next = new URL(loc, current);
        reasons.push(`إعادة توجيه ${res.status} → ${next.origin}`);
        await assertUrlPassesSsrfChecks(next);
        current = next.href;
        continue;
      }

      await drainLimitedResponse(res);

      const status = res.status;
      const ok = status >= 200 && status < 400;
      return {
        ok,
        finalUrl: current,
        chain,
        status,
        finalProto: new URL(current).protocol,
      };
    } catch (e) {
      if (e instanceof SSRFError) throw e;
      reasons.push(
        `لم يكتمل الطلب (${e.code || e.name || 'NETWORK'}): لا يمكن ضمان أن الموقع قانونياً.`,
      );
      return { ok: false, finalUrl: current, chain, error: String(e.message || e) };
    }
  }

  reasons.push('عدد كبير من إعادة التوجيه — سلوك مشبوه.');
  return { ok: false, finalUrl: current, chain, status: 0 };
}

function scoreFromFetch(fetchResult, originalUrl) {
  const reasons = [];
  let risk = 0;

  const final = fetchResult.finalUrl ? new URL(fetchResult.finalUrl) : null;
  const orig = new URL(originalUrl);

  if (final && final.protocol === 'http:') {
    risk += 0.25;
    reasons.push('الوجهة النهائية تستخدم HTTP غير المشفّر — يجب الحذر عند إدخال بيانات حساسة.');
  }

  if (final && final.protocol === 'https:') {
    reasons.push('تم الاتصال عبر HTTPS.');
  }

  if (fetchResult.status >= 400 && fetchResult.status < 500) {
    risk += 0.12;
    reasons.push(`الخادم أعاد رمز حالة ${fetchResult.status} (طلب).`);
  }

  if (fetchResult.status >= 500) {
    risk += 0.18;
    reasons.push(`الخادم أعاد خطأ ${fetchResult.status}.`);
  }

  if (fetchResult.ok && fetchResult.status >= 200 && fetchResult.status < 400) {
    reasons.push('استجابة HTTP قابلة للوصول.');
  }

  if (!fetchResult.ok && fetchResult.error && !reasons.some((x) => x.includes('لم يكتمل'))) {
    risk += 0.22;
    reasons.push('لم يُستَلم رد موثوق من الخادم (قد يكون الموقع وهمياً أو معطلاً).');
  }

  if (final && final.hostname !== orig.hostname) {
    risk += 0.15;
    reasons.push(`النطاق تغير عن الأصل (${orig.hostname} → ${final.hostname}).`);
  }

  const is_safe = risk < 0.45;
  const confidence = Math.max(0.35, Math.min(0.92, is_safe ? 0.82 - risk * 0.3 : 0.55 + risk * 0.4));

  return { is_safe, confidence, reasons };
}

export async function handler(event) {
  const hdr = corsHeaders({
    'Content-Type': 'application/json; charset=utf-8',
  });

  if (event.httpMethod === 'OPTIONS')
    return { statusCode: 204, headers: hdr, body: '' };

  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers: hdr,
      body: JSON.stringify({
        error: 'method_not_allowed',
        message_ar: 'يُسمح فقط بـ POST.',
      }),
    };
  }

  try {
    let body;
    try {
      body = JSON.parse(event.body || '{}');
    } catch {
      return {
        statusCode: 400,
        headers: hdr,
        body: JSON.stringify({
          error: 'bad_json',
          message_ar: 'جسم الطلب ليس JSON صالحاً.',
        }),
      };
    }

    const inputUrl = body.url;
    let start;
    try {
      start = normalizeInitialUrl(inputUrl);
    } catch (err) {
      return {
        statusCode: 400,
        headers: hdr,
        body: JSON.stringify({
          error: 'invalid_url',
          message_ar:
            err?.message === 'EMPTY'
              ? 'الرابط فارغ.'
              : 'عنوان غير صالح أو مخطط غير مدعوم.',
        }),
      };
    }

    const reasonsOut = [];

    /** Google Safe Browsing */
    let sbMatches = null;
    try {
      sbMatches = await googleSafeBrowsingLookup(
        start.href,
        process.env.GOOGLE_SAFE_BROWSING_API_KEY,
      );
    } catch {
      reasonsOut.push(
        '(Google Safe Browsing غير متاح للحظة؛ يُعتمد الفحص المباشر فقط أو أضِف المفتاح في Netlify)',
      );
    }

    if (sbMatches) {
      return {
        statusCode: 200,
        headers: hdr,
        body: JSON.stringify({
          is_safe: false,
          confidence: 0.97,
          reasons: [
            'مُدرَج ضمن تهديدات Google Safe Browsing (أو شبيه تقنياً).',
            ...reasonsOut,
          ].filter(Boolean),
          source_safe_browsing: true,
        }),
      };
    }

    /** فحص مباشر */
    await assertUrlPassesSsrfChecks(start);
    const fetchRes = await fetchWithRedirects(start, reasonsOut);
    let scored;

    try {
      scored = scoreFromFetch(fetchRes, start.href);
    } catch {
      scored = {
        is_safe: false,
        confidence: 0.5,
        reasons: [...reasonsOut, 'فشل تقييم الاستجابة.'],
      };
    }

    const mergedReasons = [
      ...reasonsOut,
      ...scored.reasons.filter((r) => r && !reasonsOut.includes(r)),
    ];

    const payload = {
      is_safe: scored.is_safe,
      confidence: scored.confidence,
      reasons:
        mergedReasons.length > 0
          ? mergedReasons
          : scored.is_safe
            ? ['لم تُكتشَف مؤشرات قوية للخطر في الفحص المباشر.']
            : ['لم تُجد إشارات واضحة؛ يُنصَح بحذر إضافي.'],
      meta: {
        hops: fetchRes.chain?.length ?? 0,
        final_status: fetchRes.status,
      },
    };

    return {
      statusCode: 200,
      headers: hdr,
      body: JSON.stringify(payload),
    };
  } catch (e) {
    if (e instanceof SSRFError) {
      return {
        statusCode: 403,
        headers: hdr,
        body: JSON.stringify({
          error: 'ssrf_blocked',
          message_ar: e.message || 'محاولة وصول إلى وجهة محظورة.',
        }),
      };
    }

    return {
      statusCode: 500,
      headers: hdr,
      body: JSON.stringify({
        error: 'internal_error',
        message_ar: 'خطأ خادم داخلي أثناء الفحص.',
        detail:
          process.env.NETLIFY_DEV === 'true' ||
          process.env.CONTEXT !== 'production'
            ? String(e.message || e)
            : undefined,
      }),
    };
  }
}
