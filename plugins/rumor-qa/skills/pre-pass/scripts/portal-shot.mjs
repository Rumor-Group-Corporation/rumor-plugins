// Open the UAT host portal as a QA host session and screenshot one page.
// Usage: node portal-shot.mjs <session-label> <path> <out.png>
// The web login keeps Continue disabled until Turnstile passes, so we log in by API (uat.mjs login with
// roleHint 'host') and hand Playwright the cookies the portal sets. Playwright comes from grapevine/apps/web.
import { createRequire } from 'node:module';
import { join } from 'node:path';
import { sessions } from './uat.mjs';

const WEB = process.env.GRAPEVINE_WEB ?? join(process.env.HOME, 'rumor/grapevine/apps/web');
const { chromium } = createRequire(join(WEB, 'package.json'))('@playwright/test');
const BASE = 'https://betahost.therumor.com';
const [label, path, out] = process.argv.slice(2);
const s = sessions()[label];
if (!s?.hostId) throw new Error(`${label} is not a host session`);

const browser = await chromium.launch();
const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
const { hostname } = new URL(BASE);
await ctx.addCookies([
  ['access-token', s.token], ['refresh-token', 'prepass-no-refresh'],
  ['company-details', JSON.stringify(s.hostDetails ?? { id: s.hostId })],
  ['roles', JSON.stringify((s.roles || []).map((r) => ({ roleName: r.roleName, roleStatus: r.roleStatus })))],
  ['host-id', s.hostId], ['current-user-role', 'host'], ['isWaitlistedHost', 'false'],
  ['profile-completed', 'true'], ['onboarding-completed', 'true'],
].map(([name, value]) => ({ name, value, domain: hostname, path: '/', secure: true, sameSite: 'Lax' })));
const page = await ctx.newPage();
await page.goto(BASE + path, { waitUntil: 'networkidle', timeout: 60000 }).catch((e) => console.log('goto', e.message));
await page.waitForTimeout(4000);
await page.keyboard.press('Escape').catch(() => {});
await page.screenshot({ path: out });
console.log(page.url());
console.log((await page.locator('body').innerText()).slice(0, 2500));
await browser.close();
