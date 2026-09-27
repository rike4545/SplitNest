// SplitNestApp.swift

import SwiftUI
#if os(iOS)
import GoogleMobileAds
#endif

@main
struct SplitNestApp: App {
    @StateObject private var householdStore = HouseholdStore()
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var assistantStore = AiAssistantStore(service: MockAiAssistantService())

    init() {
#if os(iOS)
        let configuration = MobileAds.shared.requestConfiguration
        configuration.setPublisherFirstPartyIDEnabled(false)
        configuration.publisherPrivacyPersonalizationState = .disabled
        MobileAds.shared.start()
#endif
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(householdStore)
                .environmentObject(assistantStore)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { householdStore.scheduleReminders() }
                }
        }
    }
}
