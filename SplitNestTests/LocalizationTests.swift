import Foundation
import Testing
@testable import SplitNest

@MainActor
struct LocalizationTests {
    @Test func bundledLanguagesResolveTranslatedLabels() throws {
        let expected = ["es": "Inicio", "fr": "Accueil", "de": "Start", "pt-BR": "Início", "ja": "ホーム"]
        for (language, home) in expected {
            let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
            let bundle = try #require(Bundle(path: path))
            #expect(bundle.localizedString(forKey: "Home", value: nil, table: "Localizable") == home)
            let format = bundle.localizedString(forKey: "%@ pays %@ %@.", value: nil, table: "Localizable")
            let result = String(format: format, arguments: ["Alex", "Sam", "12 EUR"])
            #expect(result.contains("Alex"))
            #expect(result.contains("Sam"))
            #expect(result.contains("12 EUR"))
            #expect(!result.contains("%@"))
        }
    }

    @Test func insightsRecognizeSupportedLanguages() {
        let balances = ["Who owes whom?", "¿Quién debe a quién?", "Qui doit de l’argent à qui ?", "Wer schuldet wem Geld?", "Quem deve a quem?", "誰が誰に払う？"]
        for question in balances {
            #expect(AiAssistantStore.Topic.matching(question) == .balances)
        }
        let budgets = ["How much did we spend?", "¿Cuánto gastamos?", "Combien avons-nous dépensé ?", "Wie viel haben wir ausgegeben?", "Quanto gastamos?", "今月はいくら使った？"]
        for question in budgets {
            #expect(AiAssistantStore.Topic.matching(question) == .budget)
        }
        #expect(AiAssistantStore.Topic.matching("Hello") == nil)
    }
}
