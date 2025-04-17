import Foundation
import Testing

import Jot

struct JSONWebKeyTests {
	@Test func ecKeyCoding() throws {
		let key = JSONWebKey(
			params: .init(curve: .P256, x: Data("abc".utf8), y: Data("def".utf8)),
			use: .signature,
			id: "keyid"
		)
		
		let output = try JSONEncoder.jsonWebTokenEncoder.encode(key)
		
		let decoded = try JSONDecoder.jsonWebTokenDecoder.decode(JSONWebKey.self, from: output)
		
		#expect(key == decoded)
	}
}
