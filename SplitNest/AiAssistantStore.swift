//
//  AiAssistantStore.swift
//  SplitNest
//
//  Created by Bryan on 12/2/25.
//


// AiAssistantStore.swift

import Foundation
import Combine

@MainActor
final class AiAssistantStore: ObservableObject {
    @Published var messages: [ChatMessage] = []

    private let service: AiAssistantService

    init(service: AiAssistantService) {
        self.service = service

        resetConversation()
    }

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = ChatMessage(text: trimmed, sender: .user)
        messages.append(userMessage)

        Task {
            do {
                let reply = try await service.respond(to: messages)
                let assistantMessage = ChatMessage(text: reply, sender: .assistant)
                messages.append(assistantMessage)
            } catch {
                let errorMsg = ChatMessage(
                    text: "Sorry, I ran into an issue responding. Try again in a moment.",
                    sender: .assistant
                )
                messages.append(errorMsg)
            }
        }
    }

    func clearConversation() {
        resetConversation()
    }

    private func resetConversation() {
        messages = [
            ChatMessage(
                text: "Hi! I’m your SplitNest house assistant. Ask me about expenses, fairness of splits, or draft messages for your roommates.",
                sender: .assistant
            )
        ]
    }
}
