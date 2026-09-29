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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: DoseEvent.self)
    }
}
