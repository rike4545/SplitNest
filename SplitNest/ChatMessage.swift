//
//  ChatMessage.swift
//  SplitNest
//
//  Created by Bryan on 12/2/25.
//


// AiAssistantService.swift

import Foundation

struct ChatMessage: Identifiable, Hashable {
    enum Sender {
        case user
        case assistant
    }

    let id: UUID
    let text: String
    let sender: Sender
    let date: Date

    init(id: UUID = UUID(), text: String, sender: Sender, date: Date = Date()) {
        self.id = id
        self.text = text
        self.sender = sender
        self.date = date
    }
}

protocol AiAssistantService {
    func respond(to messages: [ChatMessage]) async throws -> String
}

/// Mock implementation – swap this out with a real LLM-backed service.
struct MockAiAssistantService: AiAssistantService {
    func respond(to messages: [ChatMessage]) async throws -> String {
        // Very simple rule-based mock for now
        let lastUserMessage = messages.last(where: { $0.sender == .user })?.text ?? ""

        if lastUserMessage.lowercased().contains("rent") {
            return "Based on typical shared houses, a common split is 40/30/30 for the largest room and two smaller rooms. You can also try equal split if all rooms are similar."
        } else if lastUserMessage.lowercased().contains("who owes") {
            return "To see who owes whom in detail, open the Expenses tab. A fuller AI-powered breakdown could list each roommate and their net balance."
        } else if lastUserMessage.lowercased().contains("remind") {
            return "Here’s a friendly nudge you can use: “Hey! Just a quick reminder to send your part of the shared bills when you get a moment 😊.”"
        }

        return "I’m your housemate assistant. Ask me things like:\n\n• “Who owes what this month?”\n• “How should we fairly split rent?”\n• “Draft a polite reminder about utilities.”"
    }
}
