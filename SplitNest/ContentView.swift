//
//  ContentView.swift
//  SplitNest
//
//  Created by Bryan on 12/2/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        RootTabView()
    }
}

#Preview {
    ContentView()
        .environmentObject(HouseholdStore())
        .environmentObject(AiAssistantStore(service: MockAiAssistantService()))
}
