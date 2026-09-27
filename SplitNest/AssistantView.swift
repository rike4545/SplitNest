//
//  AssistantView.swift
//  SplitNest
//
//  Created by Bryan on 12/2/25.
//


// AssistantView.swift

import SwiftUI

struct AssistantView: View {
    @EnvironmentObject private var assistantStore: AiAssistantStore
    @EnvironmentObject private var household: HouseholdStore
    @Environment(\.colorScheme) private var scheme
    @State private var inputText: String = ""
    @State private var showingClearConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(assistantStore.messages) { message in
                        messageBubble(message)
                    }
                }
                .padding()
            }

            Divider()

            SplitNestCard {
                HStack(spacing: 8) {
                    TextField("Ask about balances, bills, chores, or budgets…", text: $inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...3)

                    Button {
                        send()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .rotationEffect(.degrees(45))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SplitNestTheme.primary)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
        }
        .navigationTitle("Household Insights")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear") {
                    showingClearConfirmation = true
                }
            }
        }
        .confirmationDialog(
            "Clear chat history?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear History", role: .destructive) {
                assistantStore.clearConversation()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes messages from this device.")
        }
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.sender == .assistant {
                bubble(text: message.text, isUser: false)
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble(text: message.text, isUser: true)
            }
        }
    }

    private func bubble(text: String, isUser: Bool) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isUser ? AnyShapeStyle(SplitNestTheme.heroGradient) : SplitNestTheme.cardBackground(for: scheme))
            )
            .foregroundColor(isUser ? .white : SplitNestTheme.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func send() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        assistantStore.send(trimmed, household: household)
        inputText = ""
    }
}
