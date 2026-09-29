# Medreminder — Plan

Status: **in progress** — phases 1–9 done; on-device validation (phase 10) next.

## 1. Problem

Medication is taken every 14 days, but the exact day shifts often (travel),
and calendar/reminder apps can't be trusted to reflect the real last-taken
date. Other medications with daily, weekly or monthly schedules should be
tracked in the same app. Tiny personal iOS app, sideloaded via Xcode with an
existing Apple Developer account, not distributed on the App Store.

## 2. Core requirements

1. Multiple medications, each with its own schedule, managed in a
   **Medications** tab.
2. One-tap "Taken" button per medication — logs a timestamped dose.
3. Display per medication: last taken (date + time) and next due, with a
   relative hint ("in 6 days", "overdue by 2 days", "due today at 8:00 PM").
4. Local notification at each dose's reminder time.
5. Report/history screen listing every logged dose, with its medication.
6. Ability to edit (or delete) a past entry to correct mistakes.

## 3. Key decisions

| Area | Decision | Why |
|---|---|---|
| Language | Swift | Native, no reason to use anything else for a personal iOS-only app. |
| UI framework | SwiftUI | Minimal boilerplate, small codebase, easy to maintain solo. |
| Persistence | SwiftData | Native, lightweight local DB, no backend/sync needed — everything stays on-device. |
| Min iOS target | iOS 26.5 (project default) | Own devices only; lower it in Xcode if an older device needs it. |
| Frequency | Daily / weekly / monthly per medication | Covers the common schedules without a full recurrence editor. |
| Doses per day | 1x–4x, each with its own reminder time and its own Taken tap | e.g. 2x daily = morning + evening. |
| Weekly schedule | Pick weekdays + every N weeks (1–4), or "count from last dose" (last dose + N weeks) | The 14-day medication is "every 2 weeks, from last dose", so it still self-corrects after travel. |
| Monthly schedule | 1 month after the last dose (floating) | Same self-correcting behavior as the 14-day logic. |
| Daily schedule | Fixed: every day from the start date | Nothing to float. |
| Notifications | Local only (`UserNotifications`), no push server | App only needs to alert the device it's installed on. |
| Notification timing | At each dose's reminder time on its due day | Replaces the earlier fixed 9:00 AM. |
| Sync / multi-device | Out of scope | Single device, no iCloud account linkage needed. |
| Distribution | Build & run from Xcode directly onto your device using your existing Apple Developer account | App is never submitted to the App Store. |

## 4. Data model

```
Medication
- id: UUID
- name: String
- createdAt: Date
- frequency: daily | weekly | monthly
- dosesPerDay: Int            // 1...4
- doseTimes: [Int]            // minutes after midnight, one per dose
- startDate: Date             // first possible due day
- weekdays: [Int]             // weekly fixed: 1=Sun ... 7=Sat
- weekInterval: Int           // weekly: every N weeks (1...4)
- countsFromLastDose: Bool    // weekly only
- doses: [DoseEvent]          // cascade delete

DoseEvent
- id: UUID
- takenAt: Date         // timestamp the dose was recorded for
- createdAt: Date       // when the entry was created (audit trail)
- note: String?         // optional, e.g. "took a day early - travel"
- medication: Medication?
```

Derived (not stored), per medication — the next *uncovered* dose slot
(day + dose time). A slot counts as covered when that day has at least
slot-index + 1 doses logged.
- **Fixed** (daily, weekly fixed): the most recent scheduled day on or before
  today, if it still has uncovered slots (due / overdue); otherwise slot 0 of
  the next scheduled day.
- **Floating** (weekly from last dose, monthly): no doses → start date at
  slot 0; last dose's day still has uncovered slots → next slot that day;
  otherwise last dose's day + N weeks (or + 1 month) at slot 0.

## 5. Screens

**Doses** (first tab)
- Sections, empty ones hidden: **Overdue** (red), **Today** (due later today,
  or already taken today — shown with a green checkmark), **Upcoming**.
  "Nothing due today" when neither Overdue nor Today has anything.
- One card per medication, soonest first: name, due hint, next due, last
  taken, and a Taken button that locks (green checkmark) until the next dose
  unlocks on its due day; "Take early…" for from-last-dose schedules or a
  later dose due today.
- Empty state points to the Medications tab.

**History (Report)**
- Reverse-chronological list of all doses, showing the medication name
- Tap an entry → edit screen (change date/time, or delete)

**Medications**
- List of medications with a one-line schedule summary
  (e.g. "Every 2 weeks, from last dose · 1x at 9:00 AM")
- + opens the add form; tap a row to edit; swipe to delete (with confirmation;
  deletes that medication's doses too)

**Medication form**
- Name
- How often: Daily / Weekly / Monthly
- Times per day: 1x / 2x / 3x / 4x, then a time picker per dose
- Weekly: "Count from last dose" toggle, every N weeks; when not counting from
  last dose, weekday chips (S M T W T F S)
- Start date (calendar picker)
- Live preview of the next 4 due dates

**Edit entry**
- Date/time picker pre-filled with the entry's current `takenAt`
- Save / Delete / Cancel

## 6. Notifications

- Request notification permission on first launch.
- On any dose or medication change, and whenever the app comes to the
  foreground, cancel and reschedule each medication's next ~8 due slots at
  their dose times (staying under iOS's 64 pending-notification limit).
- Notification body: "Time to take <name>."

## 7. Build phases

1. ~~**Project setup**~~ — done.
2. ~~**Core logging**~~ — done (single medication).
3. ~~**Next-dose calculation**~~ — done (fixed 14 days).
4. ~~**Medication model + schedule logic**~~ — done: `Medication` model, `DoseEvent`
   relationship, schedule calculation, unit tests (daily, weekly fixed with
   N=2, weekly from last dose, monthly on the 31st, multi-dose days).
5. ~~**Medications tab**~~ — done: list, add/edit form, delete.
6. ~~**Today tab**~~ — done: per-medication cards.
7. ~~**Notifications**~~ — done: permission request, next 8 reminders per medication (60 max), rescheduled on every change and when the app opens; banners shown in-app too.
8. ~~**History + edit/delete**~~ — done (built before phase 7): list with medication names; correct or remove
   a past entry.
9. ~~**Polish**~~ — done: app icon (light/dark/tinted), "Reminders are off" banner with a Settings link; empty states on every tab; default system launch screen kept.
10. **Install & validate on device** — delete and reinstall once (existing
    doses are test data), add real medications, confirm notifications fire
    (shortened intervals during development).

## 8. Deployment to device

- Confirmed: you have a **paid Apple Developer Program account** ($99/yr),
  not just a free Apple ID. This means the app's code-signing certificate
  is valid for about **1 year** per build — no weekly reinstall needed like
  a free-account signature would require.
- Standard path: open the project in Xcode, connect the iPhone (USB or
  paired Wi-Fi), select it as the run target, and hit Run — Xcode compiles,
  signs, and installs directly onto the device. No App Store/TestFlight
  needed for a single personal device.
- Xcode's toolchain (or at least its Command Line Tools + iOS SDK, which
  install alongside the full Xcode app) is required to compile and sign a
  native Swift/SwiftUI app — there's no way around touching Apple's own
  tooling on a Mac.
- Xcode's GUI itself can be skipped in favor of Terminal (`xcodebuild` to
  build, `xcrun devicectl device install app` to push to the phone), but
  the underlying Xcode installation is still required.
- Alternative with no Xcode install at all: **Swift Playgrounds** (free,
  iPad or Mac) can create a real SwiftUI "App" project, build it, and
  deploy wirelessly to a paired iPhone. Fully capable for an app this
  small (button + list + local notifications) if a lighter workflow than
  full Xcode is preferred.

## 9. Open items / assumptions to revisit later

- No reminder escalation (repeat notifications) — can add if a single
  alert gets missed too often in practice.
- Missed fixed-schedule doses don't carry over: once a newer scheduled day
  arrives, older uncovered slots are no longer shown as overdue.
- No widget / Lock Screen complication in this plan — could be a fast
  follow-up once the core app works.
