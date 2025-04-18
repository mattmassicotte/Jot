import Foundation
import Testing

import Jot

struct MockPayload : JSONWebTokenPayload, Equatable {
	let iss: String?
	let sub: String?
	let aud: JSONWebTokenAudience?
	let jti: String?
	let nbf: Date?
	let iat: Date?
	let exp: Date?
	
	let customClaim: String
}

typealias MockToken = JSONWebToken<MockPayload>

struct JSONWebTokenTests {
	@Test func headerCoding() throws {
		let header = JSONWebTokenHeader(algorithm: .ES256)
		
		let data = try JSONEncoder.jsonWebTokenEncoder.encode(header)
		let decoded = try JSONDecoder.jsonWebTokenDecoder.decode(JSONWebTokenHeader.self, from: data)
		
		#expect(header == decoded)
	}
	
	@Test func singleAudienceDecoding() throws {
		let singleString = "\"single\""
		let single = try JSONDecoder().decode(JSONWebTokenAudience.self, from: Data(singleString.utf8))
		
		#expect(single == .single("single"))
	}
	
	@Test func singleAudienceEncoding() throws {
		let single = try JSONEncoder().encode(JSONWebTokenAudience.single("single"))
		
		#expect(String(decoding: single, as: UTF8.self) == "\"single\"")
	}
	
	@Test func arrayAudienceDecoding() throws {
		let singleString = "[\"one\",\"two\"]"
		let audience = try JSONDecoder().decode(JSONWebTokenAudience.self, from: Data(singleString.utf8))
		
		#expect(audience == .array(["one", "two"]))
	}
	
	@Test func arrayAudienceEncoding() throws {
		let data = try JSONEncoder().encode(JSONWebTokenAudience.array(["one", "two"]))
		let array = try JSONDecoder().decode([String].self, from: data)
		
		#expect(array == ["one", "two"])
	}
	
	@Test func tokenCoding() throws {
		let token = MockToken(
			header: JSONWebTokenHeader(algorithm: .ES256),
			payload: MockPayload(iss: nil, sub: nil, aud: nil, jti: nil, nbf: nil, iat: nil, exp: nil, customClaim: "claim")
		)
		
		let mockSig = Data("signature!".utf8)
		
		let output = try token.encode { algo, data in
			#expect(algo == .ES256)
			
			return mockSig
		}
		
		let decoded = try MockToken(encodedString: output) { algo, message, signature in
			#expect(algo == .ES256)
			
			return signature == mockSig
		}
		
		#expect(decoded == token)
	}
	
	@Test func tokenDecode() throws {
		let tokenData = """
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJjdXN0b21DbGFpbSI6ImNsYWltIn0.Gpk1tPiut0i6rG9fXWI1cNh61me3qa8bTcEDMSwmD2I
"""
		let token = try MockToken(encodedString: tokenData) { _, _, _ in
			return true
		}
		
		#expect(token.header.algorithm == .HS256)
		#expect(token.payload.customClaim == "claim")
		#expect(token.payload.iat == Date(timeIntervalSince1970: 1516239022))
	}
}

#if canImport(CryptoKit)
import CryptoKit

extension JSONWebTokenTests {
	@Test func p256Signing() throws {
		let key = P256.Signing.PrivateKey()
		
		let token = MockToken(
			header: JSONWebTokenHeader(algorithm: .ES256),
			payload: MockPayload(iss: nil, sub: nil, aud: nil, jti: nil, nbf: nil, iat: nil, exp: nil, customClaim: "claim")
		)
		
		let output = try token.encode(with: key)
		
		let decoded = try MockToken(encodedString: output, key: key.publicKey)
		
		#expect(decoded == token)
	}
	
	@Test func tokenWithWebKey() throws {
		let key = P256.Signing.PrivateKey()
		
		let webKey = JSONWebKey(p256Key: key.publicKey)
		
		let token = MockToken(
			header: JSONWebTokenHeader(algorithm: .ES256, jwk: webKey),
			payload: MockPayload(iss: nil, sub: nil, aud: nil, jti: nil, nbf: nil, iat: nil, exp: nil, customClaim: "claim")
		)
		
		let output = try token.encode(with: key)
		
		let decoded = try MockToken(encodedString: output, key: key.publicKey)
		
		#expect(decoded == token)
	}
	
	@Test func hs256Signing() throws {
		let key = SymmetricKey(data: Data("thekey".utf8))

		let token = MockToken(
			header: JSONWebTokenHeader(algorithm: .HS256, type: "JWT"),
			payload: MockPayload(
				iss: nil,
				sub: "1234567890",
				aud: nil,
				jti: nil,
				nbf: nil,
				iat: Date(timeIntervalSince1970: 1516239022),
				exp: nil,
				customClaim: "claim"
			)
		)
		
		let encoded = try token.encode(with: key)

		let tokenData = """
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjdXN0b21DbGFpbSI6ImNsYWltIiwiaWF0IjoxNTE2MjM5MDIyLCJzdWIiOiIxMjM0NTY3ODkwIn0.qfNgobhscI9_XCANUKYW0pbo1wf-wzdJ2JWAPFy-Sek
"""

		#expect(encoded == tokenData)

		let decoded = try MockToken(encodedString: tokenData, key: key)
		
		#expect(decoded.header.algorithm == .HS256)
		#expect(decoded.payload.customClaim == "claim")
	}

	@Test func hs384Signing() throws {
		let key = SymmetricKey(data: Data("thekey".utf8))

		let tokenData = """
eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJjdXN0b21DbGFpbSI6ImNsYWltIiwiaWF0IjoxNTE2MjM5MDIyLCJzdWIiOiIxMjM0NTY3ODkwIn0.7POATYQLX8CgQL5jyZPzl-O1dhuzcpyxhgYTVOJESJl7x-4JD0QnePMl6sdHDatW
"""

		let token = try MockToken(encodedString: tokenData, key: key)
		
		#expect(token.header.algorithm == .HS384)
		#expect(token.payload.customClaim == "claim")
	}

	@Test func hs512Signing() throws {
		let key = SymmetricKey(data: Data("thekey".utf8))

		let tokenData = """
eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJjdXN0b21DbGFpbSI6ImNsYWltIiwiaWF0IjoxNTE2MjM5MDIyLCJzdWIiOiIxMjM0NTY3ODkwIn0.OVuT-eJQOrYLElNPpMJOf3iHcSgXEj9FJkh_C0hd8g9ufWdcvXxayhqgjIcckOJ3WNSkEMOATUUWiO06AujC_A
"""

		let token = try MockToken(encodedString: tokenData, key: key)
		
		#expect(token.header.algorithm == .HS512)
		#expect(token.payload.customClaim == "claim")
	}
}
#endif
