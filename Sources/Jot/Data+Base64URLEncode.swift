import Foundation

extension Data {
	func base64EncodedURLEncodedString() -> String {
		base64EncodedString()
			.replacingOccurrences(of: "+", with: "-")
			.replacingOccurrences(of: "/", with: "_")
			.replacingOccurrences(of: "=", with: "")
	}

	init?(base64URLEncoded string: String) {
		let paddingCount = string.utf8.count % 4
		
		let input = string
			.replacingOccurrences(of: "-", with: "+")
			.replacingOccurrences(of: "_", with: "/")
			.appending(String(repeating: "=", count: paddingCount))
		
		self.init(base64Encoded: input)
	}
}
