//
//  SplitNestTheme 2.swift
//  SplitNest
//
//  Created by Bryan on 12/2/25.
//


// SplitNestTheme.swift

import SwiftUI

#if os(iOS)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

struct SplitNestTheme {
    /// Warm coral with a hint of tangerine
    static let primary = Color(red: 0.98, green: 0.38, blue: 0.30) // #FA614D
    /// Mint accent for secondary emphasis
    static let accent = Color(red: 0.18, green: 0.70, blue: 0.64) // #2DB3A3
    /// Deep ink for high-contrast text
    static let ink = Color(red: 0.12, green: 0.13, blue: 0.17) // #1E212B
    /// Soft sand for light surfaces
    static let sand = Color(red: 0.98, green: 0.95, blue: 0.90) // #FAF2E6
    /// Cool wash for ambient glow
    static let sky = Color(red: 0.88, green: 0.94, blue: 0.97) // #E1EFF7

    /// Background that works on both iOS and macOS
    static let background: Color = {
        #if os(iOS)
        return Color(uiColor: .systemBackground)
        #elseif os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.white
        #endif
    }()

    static let textPrimary: Color = .primary
    static let textSecondary: Color = .secondary

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                sky.opacity(0.75),
                sand.opacity(0.35),
                background
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                primary.opacity(0.9),
                accent.opacity(0.75)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func cardBackground(for scheme: ColorScheme) -> AnyShapeStyle {
        if scheme == .dark {
            return AnyShapeStyle(Color.white.opacity(0.08))
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.95),
                    Color.white.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Typography

    static func titleFont() -> Font {
        .system(size: 30, weight: .bold, design: .rounded)
    }

    static func sectionFont() -> Font {
        .system(size: 18, weight: .semibold, design: .rounded)
    }

    static func bodyFont() -> Font {
        .system(size: 15, weight: .regular, design: .rounded)
    }

    static func captionFont() -> Font {
        .system(size: 12, weight: .medium, design: .rounded)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .background(
                SplitNestTheme.heroGradient
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: SplitNestTheme.primary.opacity(0.22), radius: configuration.isPressed ? 2 : 8, x: 0, y: 4)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct PillTag: View {
    let text: String

    var body: some View {
        Text(LocalizedStringKey(text))
            .font(SplitNestTheme.captionFont())
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .background(SplitNestTheme.accent.opacity(0.18))
            .foregroundColor(SplitNestTheme.accent)
            .clipShape(Capsule())
    }
}

struct SplitNestCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(SplitNestTheme.cardBackground(for: scheme))
                    .shadow(color: Color.black.opacity(scheme == .dark ? 0.18 : 0.06), radius: 8, x: 0, y: 4)
            )
    }
}

struct SplitNestSectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey(title))
                .font(SplitNestTheme.sectionFont())
                .foregroundColor(SplitNestTheme.textPrimary)
            if let subtitle {
                Text(LocalizedStringKey(subtitle))
                    .font(SplitNestTheme.captionFont())
                    .foregroundColor(SplitNestTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SplitNestStatPill: View {
    let label: String
    let value: String
    let accent: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(accent.opacity(0.2))
                .frame(width: 10, height: 10)
            Text(LocalizedStringKey(label))
                .font(SplitNestTheme.captionFont())
                .foregroundColor(SplitNestTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(accent)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(accent.opacity(0.08))
        )
    }
}

