// UAT-only API helper for /pre-pass. Never prints codes or tokens.
// Sessions are kept in $PREPASS_DIR (default: cwd)/.prepass-sessions.json, mode 0600.
// Run it from your scratch folder, never from a repo.
import { randomUUID } from 'node:crypto';
import { readFileSync, writeFileSync, existsSync, chmodSync } from 'node:fs';
import { join } from 'node:path';

export const API = 'https://uatapi.therumor.com';
export const TEST_PHONE = /^\+1[2-9]\d{2}55501\d{2}$/;
const SESS = join(process.env.PREPASS_DIR ?? process.cwd(), '.prepass-sessions.json');

export const sessions = () => (existsSync(SESS) ? JSON.parse(readFileSync(SESS, 'utf8')) : {});
const save = (s) => { writeFileSync(SESS, JSON.stringify(s), { mode: 0o600 }); chmodSync(SESS, 0o600); };
export const tok = (label) => {
  const s = sessions()[label];
  if (!s) throw new Error(`no session for ${label}: run login() first`);
  return s.token;
};
const assertTestPhone = (phone) => { if (!TEST_PHONE.test(phone)) throw new Error('not a UAT test phone'); };

export async function call(method, path, body, token) {
  if (!path.startsWith('/')) throw new Error('path must start with /');
  const r = await fetch(API + path, {
    method,
    headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await r.text();
  let json; try { json = JSON.parse(text); } catch { json = text; }
  return { status: r.status, json };
}

// One-line result for logs: "409 The table changed… code=APPLICATION_VERSION_CONFLICT"
export const short = (r) => `${r.status} ${r.json?.message ?? ''}${r.json?.data?.code ? ' code=' + r.json.data.code : ''}`;

// client 'web' + roleHint 'host' = host portal login (code 00+last4); anything else = member/app (last4).
export async function login(label, phone, { client = 'web', roleHint } = {}) {
  assertTestPhone(phone);
  const code = client === 'web' && roleHint ? `00${phone.slice(-4)}` : phone.slice(-4);
  const common = { phoneNumber: phone, purpose: 'login', clientType: client, ...(roleHint ? { roleHint } : {}) };
  const s = await call('POST', '/users/v1/auth/otp/send', common);
  if (s.status >= 300) return { ok: false, step: 'send', status: s.status, msg: s.json?.message };
  const v = await call('POST', '/users/v1/auth/otp/verify', {
    ...common, code, ...(client === 'web' ? { sessionScopeId: `web:${randomUUID().replace(/-/g, '')}` } : {}),
  });
  const d = v.json?.data;
  if (v.status >= 300 || !d?.token) return { ok: false, step: 'verify', status: v.status, msg: v.json?.message };
  const all = sessions();
  all[label] = { phone, token: d.token, hostId: d.hostDetails?.id, userId: d.user?.id ?? d.userId, roles: d.roles, hostDetails: d.hostDetails };
  save(all);
  return { ok: true, roles: (d.roles || []).map((r) => `${r.roleName}:${r.roleStatus}`), hostId: d.hostDetails?.id ?? null };
}

// Member account: starts non_member NEW_APPLICANT, no Instagram. App login works at once.
export async function signupMember(phone, firstName, lastName, email) {
  assertTestPhone(phone);
  await call('POST', '/notifications/v1/communication/send-verification-code', { phoneNumber: phone, source: 'mobile' });
  await call('POST', '/notifications/v1/communication/verify-code', { phoneNumber: phone, code: phone.slice(-4) });
  return call('POST', '/users/v1/auth/member-sign-up', {
    firstName, lastName, email, phoneNumber: phone, dateOfBirth: '1995-05-05', platform: 'ios', instagramValidated: false,
    address: { address: 'New York, NY, USA', placeId: 'ChIJOwg_06VPwokRYv534QaPC8g' },
  });
}

// Host account: starts NEW_APPLICANT; web login answers "Host not found" until staff approve it.
export async function signupHost(phone, firstName, lastName, companyName, email) {
  assertTestPhone(phone);
  return call('POST', '/users/v1/auth/host-sign-up', { firstName, lastName, companyName, email, phoneNumber: phone, eventsPerYear: 12, source: 'mobile' });
}

// Guest-list CSV as the given host session. Returns the CSV text (contains test contacts only).
export async function exportGuests(label, eventId) {
  const start = await call('GET', `/events/v1/guest/event/${eventId}/export`, null, tok(label));
  const job = start.json?.data?.jobId ?? start.json?.data?.id;
  if (!job) return { ok: false, status: start.status, msg: start.json?.message };
  for (let i = 0; i < 20; i++) {
    const r = await call('GET', `/events/v1/export-jobs/${job}/status`, null, tok(label));
    const d = r.json?.data;
    if (d?.downloadUrl) return { ok: true, csv: await (await fetch(d.downloadUrl)).text() };
    if (d?.status === 'FAILED' || r.status >= 400) return { ok: false, status: r.status, msg: r.json?.message };
    await new Promise((res) => setTimeout(res, 3000));
  }
  return { ok: false, msg: 'export timed out' };
}
