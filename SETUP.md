# Setup

This session has no macOS/Xcode available, so the Swift source is written
directly (under `Medreminder/`) but no `.xcodeproj` has been generated or
verified by a real build. Do this once on your Mac to turn it into a
working Xcode project.

## Option A — XcodeGen (fastest)

If you have [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed
(`brew install xcodegen`):

```sh
cd Medreminder   # repo root, where project.yml lives
xcodegen generate
open Medreminder.xcodeproj
```

That reads `project.yml` and produces the `.xcodeproj` referencing the
existing `Medreminder/` source folder — no manual file dragging needed.

## Option B — Manual Xcode project (no extra tools)

1. Xcode → File → New → Project → iOS → **App**.
2. Product Name: `Medreminder`. Interface: **SwiftUI**. Storage: **None**
   (this repo manages the `ModelContainer` itself in `MedreminderApp.swift`).
3. Save it in a scratch location — you'll only keep the generated
   `Medreminder.xcodeproj`, not its template source files.
4. In the new project, delete the template's `ContentView.swift` (and
   `Item.swift` if present).
5. Drag this repo's `Medreminder/` folder (Models, Notifications, Support,
   Views, and `MedreminderApp.swift`) into the Xcode project navigator.
   Check **"Copy items if needed"** and make sure the **Medreminder**
   target is checked.
6. Project settings → General → set **Minimum Deployments** to iOS 17.0.
7. Signing & Capabilities → select your Apple Developer team.

## Either way, then:

1. Connect your iPhone (USB or paired Wi-Fi) and select it as the run
   destination.
2. Build & Run (⌘R).
3. On first launch, allow the notification permission prompt — that's
   what powers the due-date alert.

## What to expect

- **Today tab**: "Taken" button, last-taken timestamp, next-due date with
  a relative hint ("In 6 days" / "Overdue by 2 days").
- **History tab**: every logged dose, newest first; swipe to delete; tap
  an entry to edit its date/time or note.
- A single local notification is scheduled for 9:00 AM on the computed
  due date, and is rescheduled automatically whenever you log, edit, or
  delete a dose.

Since none of this has been compiled (no Swift/Xcode toolchain in this
environment), treat the first build as the real test — check back here if
anything doesn't compile as expected and we'll fix it.
