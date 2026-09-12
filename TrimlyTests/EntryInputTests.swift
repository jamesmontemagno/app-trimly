import Foundation
import Testing
@testable import TrimTally

struct EntryInputTests {
    @Test func localizedDecimalValues() {
        #expect(EntryInput.weight("80.5", locale: Locale(identifier: "en_US")) == 80.5)
        #expect(EntryInput.weight("80,5", locale: Locale(identifier: "fr_FR")) == 80.5)
        #expect(EntryInput.weight("80,5", locale: Locale(identifier: "es_ES")) == 80.5)
    }

    @Test func rejectsInvalidValues() {
        for text in ["", "hello", "NaN", "Infinity", "-5", "0", "80kg", "80.5.2", "1,234", "80e2"] {
            #expect(EntryInput.weight(text, locale: Locale(identifier: "en_US")) == nil)
        }
    }
}
