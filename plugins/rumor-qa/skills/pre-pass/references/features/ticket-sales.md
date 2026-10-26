# Ticket sales (and paid tables)

Linear project "Ticket Sales" (P-RUM-49, lead Prazul) + PRD "PRD — Ticket/Table
Sales". Detailed design in two Google Docs linked from RUM-8348. Prod is behind
the `ticket-sales` flag (staff + one tester). Paid tables were never built
(RUM-11119 cancelled); free table requests shipped in the Tao project instead.

## Agreed behaviour (summary)

- Ticket type: name, optional description, price ($0 allowed), optional
  quantity. One ticket = one person. Lead may buy extras for plus-ones and edit
  their details later. No transfers or resale in V1.
- Separate comp request form (host approves) and paid form; ticket link is not
  the RSVP form. Hosts can record "Paid – External" / "Comped": they count
  against inventory, not payouts.
- Fees: platform fee 5–8% (admin-set) + Stripe fee passed through; buyer sees
  the breakdown. Host custom fee + Rumor fee must add up to the shown fee to the
  cent (RUM-13219).
- Stripe Tax, host is merchant of record. Payouts 3–7 business days after the
  event; admin can pay trusted hosts early.
- Refunds by host or admin only; policy shown at checkout; no self-refund.
- Host: Sales tab (orders, refunds, tickets, visits, conversion), Payments
  page, net payout. Guest: ticket with QR. Door: one check-in row per ticket
  with a paid marker.

## Bug classes

1. State mixes (the biggest): request then buy (RUM-9321), buy then comp
   (RUM-9320), buy then re-invite (RUM-9268), buy then guest-list ticket
   (RUM-10117), Cancel RSVP after paying (RUM-13169), comp guest sees GA
   (RUM-9508).
2. Gates skipped on another path: phone verification (RUM-9265), event
   password on the ticket link (RUM-9528), terms on an event with none
   (RUM-9263).
3. Inventory/orders: quantity change after verification makes two sales
   (RUM-9264); ticket type made on mobile can't be bought (RUM-9325).
4. Stripe setup shown to the wrong person or at the wrong time: $0.50 minimum
   error at guest checkout (RUM-13315), "Setup Paused" (RUM-13123), "not on sale
   yet" because the host never finished setup (RUM-13117), setup mid-flow
   restarts event creation (RUM-9267), ZIP required with no reason (RUM-13116).
5. Analytics wrong: page visits and conversion (RUM-9324).
6. Never tested by QA, found by code audit: concurrent buyers, double refunds,
   client-clock holds, hard-coded `$` (RUM-9145, RUM-9119, RUM-9159, RUM-9160).
   Run `stress.md` in full for this feature.
