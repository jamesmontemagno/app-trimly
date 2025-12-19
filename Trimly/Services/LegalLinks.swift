import Foundation

enum LegalLinks {
	/// Hosted legal pages for TrimTally. Uses hash-based routing for GitHub Pages compatibility.
	private static let base = "https://trimtally.app/#"
	
	static let privacyPolicy: URL = {
		guard let url = URL(string: "\(base)/privacy") else {
			fatalError("Invalid privacy policy URL")
		}
		return url
	}()
	
	static let termsOfService: URL = {
		guard let url = URL(string: "\(base)/terms") else {
			fatalError("Invalid terms of service URL")
		}
		return url
	}()
}
