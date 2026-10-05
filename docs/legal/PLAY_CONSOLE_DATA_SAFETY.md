# Google Play Console answers — DRAFT

Google Play asks every app for a **Data safety** form, a **privacy policy
URL**, and — for apps aimed at children — the **Families** declarations.
These answers match the current app (no internet permission, nothing leaves
the device). They must be updated when parent accounts are switched on.

## Data safety (current version)

| Question | Answer | Why |
|---|---|---|
| Does your app collect or share any of the required user data types? | **No** | Play counts data as "collected" only when it is sent off the device. The app has no internet permission and stores everything locally. |
| Is all user data encrypted in transit? | Not applicable (no data transmitted) | |
| Do you provide a way for users to request that their data is deleted? | Yes — in-app: delete a child or reset progress in the grown-ups area; uninstalling deletes everything | |

## Data safety (after parent accounts are switched on) — to fill later

| Data type | Collected | Shared | Purpose | Optional? |
|---|---|---|---|---|
| Email address (parent) | Yes | No | Account management | Yes (accounts are optional) |
| Name (child's first name) | Yes | No | App functionality (sync) | Yes |
| App interactions / in-app activity (results, progress, play time) | Yes | No | App functionality (sync) | Yes |
| Device or other IDs (random per-install ID) | Yes | No | App functionality (sync) | Yes |
| Photos | **No** (never uploaded) | No | — | — |

Encrypted in transit: Yes. Deletion: in-app and on request.

## Target audience and content (Families)

- Target age groups: **5 and under, 6-8** (choose what matches the
  curriculum; Year 1 is about 5-6 years old).
- Ads: **No ads.**
- The app does not use any third-party SDK that collects data from children.
- Privacy policy URL: required — publish the reviewed
  `PRIVACY_POLICY_DRAFT.md` (Section A) on a web page you control, for
  example a free GitHub Pages or Google Sites page, and paste its link.
- Teacher Approved / Families policy: the grown-ups gate protects settings
  and photo selection; there are no external links or purchases for
  children.
