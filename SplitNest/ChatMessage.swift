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
