import Foundation

/// Formats translated sentences without treating household names or user text as keys.
enum L10n {
    static func format(_ key: String, _ arguments: String...) -> String {
        String(format: NSLocalizedString(key, comment: ""), locale: Locale.current, arguments: arguments)
    }
}
