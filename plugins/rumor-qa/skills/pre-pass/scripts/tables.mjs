// Venue table request calls (Tao). Member side under /discover, host side under /events/:eventId.
// Every write takes the version from the last read; a stale one returns 409 APPLICATION_VERSION_CONFLICT.
import { randomUUID } from 'node:crypto';
import { call, tok } from './uat.mjs';

export const tables = (eventId) => {
  const policy = (l) => call('GET', `/events/v1/discover/events/${eventId}/policy`, null, tok(l));
  return {
    policy,
    // Returns { application } for the lead OR any listed guest (see the G5 check in features/tao-venue-tables.md).
    own: (l) => call('GET', `/events/v1/discover/events/${eventId}/table-application`, null, tok(l)),
    // members = exactly size-1 people: firstName, lastName, instagram, and email or phone.
    submit: async (l, members, extra = {}) => {
      const p = (await policy(l)).json?.data;
      return call('POST', `/events/v1/discover/events/${eventId}/table-applications`,
        { members, answers: [], expectedPolicyVersion: p?.policyVersion, idempotencyKey: randomUUID(), ...extra }, tok(l));
    },
    roster: (l, id, members, version, extra = {}) =>
      call('PUT', `/events/v1/discover/table-applications/${id}/roster`, { members, expectedApplicationVersion: version, answers: [], ...extra }, tok(l)),
    cancel: (l, id, version) =>
      call('POST', `/events/v1/discover/table-applications/${id}/cancel`, { expectedApplicationVersion: version }, tok(l)),
    extras: (l, id, members, version) =>
      call('POST', `/events/v1/discover/table-applications/${id}/extras`, { members, expectedApplicationVersion: version, idempotencyKey: randomUUID() }, tok(l)),
    hostList: (l) => call('GET', `/events/v1/events/${eventId}/table-applications`, null, tok(l)),
    hostGet: (l, id) => call('GET', `/events/v1/events/${eventId}/table-applications/${id}`, null, tok(l)),
    // decision: confirm | decline | shortlist | unshortlist. Confirm needs one ticketTypeId for the whole table.
    review: (l, id, decision, version, ticketTypeId) =>
      call('POST', `/events/v1/events/${eventId}/table-applications/${id}/review`,
        { decision, expectedApplicationVersion: version, ...(ticketTypeId ? { ticketTypeId } : {}) }, tok(l)),
    // Solo request on the same event, for state mixes.
    requestAlone: (l, userId) =>
      call('POST', '/events/v1/events/request/guest',
        { userId, eventId, answers: [], limitOnePlus: 0, additionalGuests: 0, discoverSource: 'venue', rsvpType: 'individual' }, tok(l)),
  };
};

// A test guest: QA-pre-pass names, a valid handle, plus { phone } or { email }.
export const guest = (i, contact) => ({ firstName: 'QA-pre-pass', lastName: `Guest${i}`, instagram: `qaprepass_g${i}`, ...contact });
export const app = (r) => r.json?.data?.application ?? r.json?.data;
