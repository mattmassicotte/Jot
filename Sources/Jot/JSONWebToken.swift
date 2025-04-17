import Foundation

enum JSONWebTokenError : Error {
	case signatureInvalid
	case structureInvalid
	case base64DecodingFailed
	case algorithmMismatch(JSONWebTokenAlgorithm, JSONWebTokenAlgorithm)
}

public enum JSONWebTokenAlgorithm : String, Codable, Hashable, Sendable {
	case none
	case ES256
	case HS256
	
	public func check(_ other: JSONWebTokenAlgorithm) throws {
		if self != other {
			throw JSONWebTokenError.algorithmMismatch(self, other)
		}
	}
}

public protocol JSONWebTokenHeader : Codable {
	var alg: JSONWebTokenAlgorithm { get }
	var typ: String? { get }
	var kid: String? { get }
	var jwk: JSONWebKey? { get }
}

extension JSONWebTokenHeader {
	public var typ: String? { nil }
	public var kid: String? { nil }
	public var jwk: JSONWebKey? { nil }
}

public enum JSONWebTokenAudience : Hashable, Sendable {
	case single(String)
	case array([String])
}

extension JSONWebTokenAudience : Codable {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		
		if let string = try? container.decode(String.self) {
			self = .single(string)
			return
		}
		
		if let array = try? container.decode([String].self) {
			self = .array(array)
			return
		}
		
		throw DecodingError.typeMismatch(
			JSONWebTokenAudience.self,
			DecodingError.Context.init(
				codingPath: container.codingPath,
				debugDescription: "Audience value could not be decoded",
				underlyingError: nil
			)
		)
	}
	
	public func encode(to encoder: any Encoder) throws {
		switch self {
		case let .single(string):
			try string.encode(to: encoder)
		case let .array(array):
			try array.encode(to: encoder)
		}
	}
}

//public struct ConcretePayload<Claims: Codable> : Codable {
//	var issuer: String?
//	var subject: String?
//	var audience: JSONWebTokenAudience?
//	var uniqueCode: String?
//	var notBefore: Date?
//	var createdAt: Date?
//	var expiresAt: Date?
//	var customClaims: Claims
//	
//	enum CodingKeys: String, CodingKey {
//		case issuer = "iss"
//		case subject = "sub"
//		case audience = "aud"
//		case uniqueCode = "jti"
//		case notBefore = "nbf"
//		case createdAt = "iat"
//		case expiresAt = "exp"
//	}
//	
//	public init(from decoder: any Decoder) throws {
//		<#code#>
//	}
//	
//	public func encode(to encoder: any Encoder) throws {
//		var container = encoder.container(keyedBy: CodingKeys.self)
//		try container.encodeIfPresent(self.issuer, forKey: .issuer)
//		try container.encodeIfPresent(self.subject, forKey: .subject)
//		try container.encodeIfPresent(self.audience, forKey: .audience)
//		try container.encodeIfPresent(self.uniqueCode, forKey: .uniqueCode)
//		try container.encodeIfPresent(self.notBefore, forKey: .notBefore)
//		try container.encodeIfPresent(self.createdAt, forKey: .createdAt)
//		try container.encodeIfPresent(self.expiresAt, forKey: .expiresAt)
//		
//		try customClaims.encode(to: encoder)
//	}
//}

public protocol JSONWebTokenPayload : Codable {
	var issuer: String? { get }
	var subject: String? { get }
	var audience: JSONWebTokenAudience? { get }
	var uniqueCode: String? { get }
	var notBefore: Date? { get }
	var createdAt: Date? { get }
	var expiresAt: Date? { get }
}

extension JSONWebTokenPayload {
	public var issuer: String? { nil }
	public var subject: String? { nil }
	public var audience: JSONWebTokenAudience? { nil }
	public var uniqueCode: String? { nil }
	public var notBefore: Date? { nil }
	public var createdAt: Date? { nil }
	public var expiresAt: Date? { nil }
}

public typealias JSONWebTokenSigner = (JSONWebTokenAlgorithm, Data) throws -> Data
public typealias JSONWebTokenValidator = (JSONWebTokenAlgorithm, _ message: Data, _ signature: Data) throws -> Bool

public struct JSONWebToken<Header: JSONWebTokenHeader, Payload: JSONWebTokenPayload> {
	public let header: Header
	public let payload: Payload
	
	public init(header: Header, payload: Payload) {
		self.header = header
		self.payload = payload
	}
	
	public func encode(with signer: JSONWebTokenSigner) throws -> String {
		let encoder = JSONEncoder.jsonWebTokenEncoder
		
		let headerString = try encoder.encode(header).base64EncodedURLEncodedString()
		let payloadString = try encoder.encode(payload).base64EncodedURLEncodedString()
		
		let inputData = [headerString, payloadString].joined(separator: ".")
		let signatureData = try signer(header.alg, Data(inputData.utf8))

		let signature = signatureData.base64EncodedURLEncodedString()
		
		return [headerString, payloadString, signature].joined(separator: ".")
	}
}

extension JSONWebToken : Equatable where Header : Equatable, Payload : Equatable {}
extension JSONWebToken : Hashable where Header : Hashable, Payload : Hashable {}
extension JSONWebToken : Sendable where Header : Sendable, Payload : Sendable {}

extension JSONWebToken {
	public init(encodedString: String, validator: JSONWebTokenValidator) throws {
		let components = encodedString.components(separatedBy: ".")
		guard components.count == 3 else {
			throw JSONWebTokenError.structureInvalid
		}
		
		guard
			let headerData = Data(base64URLEncoded: components[0]),
			let payloadData = Data(base64URLEncoded: components[1]),
			let signatureData = Data(base64URLEncoded: components[2])
		else {
			throw JSONWebTokenError.base64DecodingFailed
		}
		
		let decoder = JSONDecoder.jsonWebTokenDecoder
		
		self.header = try decoder.decode(Header.self, from: headerData)
		self.payload = try decoder.decode(Payload.self, from: payloadData)
		
		let message = Data(components.dropLast().joined(separator: ".").utf8)
		
		guard try validator(self.header.alg, message, signatureData) else {
			throw JSONWebTokenError.signatureInvalid
		}
	}
}
