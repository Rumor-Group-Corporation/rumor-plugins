# Stress: money, inventory, races

Sarah and Gemma never test these. Chris's code audit (RUM-9113 to RUM-9179,
tagged MONEY / SEC / DATA) found them instead. Do both: read the code for each,
then attack your own `QA-pre-pass` events on UAT through the API.

Only on events you created. Stripe test mode only. Parallel calls: at most ~20
at once, never a loop without a stop.

## Attacks

| Attack | How | Past bug |
|---|---|---|
| Two buyers, last ticket | Set quantity 1; fire 2–10 checkouts at once | RUM-9145: paid order lost seats to another buyer's unpaid hold |
| Double refund | Send the same refund twice at once, and again after it succeeded | RUM-9119: no idempotency on host refund |
| Double submit | Same request/RSVP/table application twice at once | duplicates, two rows for one guest |
| Expired hold | Start checkout, wait past the hold, pay | RUM-9159: hold expiry used the phone's clock |
| Change the device clock | Simulator clock forward/back during a hold | same |
| Quantity edits | Raise or lower quantity after verification, after payment | RUM-9264: two separate sales |
| Price edges | $0, $0.11, $0.49/$0.50 (Stripe minimum), large amounts, a fee that does not divide evenly | RUM-13315: Stripe minimum error shown to guests |
| Fee split | Host fee + Rumor fee must equal the shown fee to the cent; check rounding on every quantity 1..10 | RUM-13219 |
| Currency | Any non-USD host or price display | RUM-9160: hard-coded `$` |
| Capacity of a group | Table of exactly 10 (head + 9), 9, 11; extras after approval | spec: exactly 10 |
| Sold out then refund | Does inventory come back once, not twice? | |
| Cancel after paying | Guest-side cancel, host-side cancel, event cancel | RUM-13169 |
| Approval races | Host approves on portal and declines on app at the same moment | RUM-13072 test plan |
| Bypass the UI | Call the endpoint directly as a role that should be refused; skip a step (verification, terms, password) | RUM-9265, RUM-9528 |

## Read the code for

- A check-then-write without a lock, unique constraint or transaction.
- Money computed in floats, or rounded in two places.
- Idempotency keys missing on Stripe calls and webhooks; webhook handled twice.
- Counts derived on read in one place and stored in another.
- Time from the client.
- Authorization checked in the UI but not the endpoint.

Report each as: what you sent, what came back, what the DB shows after
(UAT SQL), and the line of code that allows it.
