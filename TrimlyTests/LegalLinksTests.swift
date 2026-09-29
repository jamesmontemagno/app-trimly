import Foundation
import Testing
@testable import TrimTally

@MainActor
struct LegalLinksTests {
    @Test
    func privacyPolicyUsesOfficialWebsiteAndHashRoute() {
        #expect(LegalLinks.privacyPolicy.absoluteString == "https://myweighttracker.app/#/privacy")
    }

    @Test
    func termsOfServiceUsesOfficialWebsiteAndHashRoute() {
        #expect(LegalLinks.termsOfService.absoluteString == "https://myweighttracker.app/#/terms")
    }
}
