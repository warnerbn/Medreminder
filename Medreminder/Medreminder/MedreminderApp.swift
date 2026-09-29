//
//  MedreminderApp.swift
//  Medreminder
//
//  Created by Brian Warner on 9/29/26.
//

import SwiftUI
import SwiftData

@main
struct MedreminderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Medication.self, DoseEvent.self])
    }
}
