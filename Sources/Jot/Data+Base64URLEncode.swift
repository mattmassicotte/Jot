import Foundation

extension Data {
	func base64EncodedURLEncodedString() -> String {
		base64EncodedString()
			.replacingOccurrences(of: "+", with: "-")
			.replacingOccurrences(of: "/", with: "_")
			.replacingOccurrences(of: "=", with: "")
	}

	init?(base64URLEncoded string: String) {
		let remainder = string.utf8.count % 4
		let paddingCount = remainder == 0 ? 0 : 4 - remainder
		
		let input = string
			.replacingOccurrences(of: "-", with: "+")
			.replacingOccurrences(of: "_", with: "/")
			.appending(String(repeating: "=", count: paddingCount))
		
		print(string, "=>", input)
		
		self.init(base64Encoded: input)
	}
}
