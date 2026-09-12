# Medreminder — Plan

Status: **planning only** — no code has been written yet. This document is the
reference to work from when implementation starts.

## 1. Problem

Medication is taken every 14 days, but the exact day shifts often (travel),
and calendar/reminder apps can't be trusted to reflect the real last-taken
date. Need a tiny personal iOS app, sideloaded via Xcode with an existing
Apple Developer account, not distributed on the App Store.

## 2. Core requirements

1. One-tap button: "I took my medication" — logs a timestamped event.
2. Display: last time the button was pressed (date + time).
3. Display: computed next due date (last dose + 14 days).
4. Local notification alert on the morning of the due date.
5. Report/history screen listing every logged dose.
6. Ability to edit (or delete) a past entry to correct mistakes.

## 3. Key decisions

| Area | Decision | Why |
|---|---|---|
| Language | Swift | Native, no reason to use anything else for a personal iOS-only app. |
| UI framework | SwiftUI | Minimal boilerplate, small codebase, easy to maintain solo. |
| Persistence | SwiftData | Native, lightweight local DB, no backend/sync needed — everything stays on-device. |
| Min iOS target | iOS 17+ | Required for SwiftData; fine since it's your own phone. |
| Dosing cadence | Fixed 14 days from the most recent logged dose | Matches "every other week," and self-corrects automatically when the day shifts — no fixed weekday logic needed. |
| Notifications | Local notification only (`UserNotifications` framework), no push server | App only needs to alert the phone it's installed on — no backend required. |
| Notification timing | One notification on the morning of the due date (e.g. 9:00 AM local time) | Per your preference — simplest option, revisit later if it's not reliable enough. |
| Sync / multi-device | Out of scope | Single phone, no iCloud account linkage needed. |
| Distribution | Build & run from Xcode directly onto your device using your existing Apple Developer account | Already available per your note; app is never submitted to the App Store. |

## 4. Data model

```
DoseEvent
- id: UUID
- takenAt: Date         // timestamp the dose was recorded for
- createdAt: Date        // when the entry was created (audit trail)
- note: String?          // optional, e.g. "took a day early - travel"
```

Derived (not stored):
- `lastDose` = the `DoseEvent` with the latest `takenAt`
- `nextDueDate` = `lastDose.takenAt` + 14 days

Editing an entry just updates its `takenAt` (and re-derives `lastDose` /
`nextDueDate` / the scheduled notification if the edited entry is the most
recent one).

## 5. Screens

**Home (Today)**
- Big "Taken" button (primary action, tap = log a `DoseEvent` with `takenAt = now`)
- "Last taken: <date, time>"
- "Next due: <date>" (with a relative hint like "in 6 days" or "overdue by 2 days")

**History (Report)**
- Reverse-chronological list of all `DoseEvent`s
- Tap an entry → edit screen (change date/time, or delete)
- Pull-to-refresh not needed (everything is local/instant)

**Edit entry**
- Date/time picker pre-filled with the entry's current `takenAt`
- Save / Delete / Cancel

## 6. Notifications

- Request notification permission on first launch.
- Whenever the most recent `DoseEvent` changes (new log, edit, or delete),
  recompute `nextDueDate` and reschedule a single local notification for
  9:00 AM on that date, cancelling any previously scheduled one.
- Notification body: something like "Time to take your medication."

## 7. Build phases

1. **Project setup** — new Xcode SwiftUI app, SwiftData model, app skeleton, run on device once to confirm signing/provisioning works.
2. **Core logging** — button, `DoseEvent` persistence, Home screen showing last-taken.
3. **Next-dose calculation** — derive and display `nextDueDate` on Home.
4. **Notifications** — permission request, scheduling, rescheduling logic.
5. **History screen** — list all entries.
6. **Edit/delete flow** — correct or remove a past entry, with rescheduling if it affects the latest dose.
7. **Polish** — empty states (no doses logged yet), app icon, launch screen.
8. **Install & validate on device** — confirm notification fires correctly across a real 14-day cycle (or a shortened test interval during development).

## 8. Open items / assumptions to revisit later

- Notification timing is fixed at "morning of due date" for now; can add a
  configurable time or a second reminder later if it proves insufficient.
- No reminder escalation (repeat notifications) — can add if a single
  morning alert gets missed too often in practice.
- No widget / Lock Screen complication in this plan — could be a fast
  follow-up once the core app works.
