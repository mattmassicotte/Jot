import Foundation

enum JSONWebTokenError: Error {
	case signatureInvalid
	case structureInvalid
	case base64DecodingFailed
	case algorithmMismatch(JSONWebTokenAlgorithm, JSONWebTokenAlgorithm)
	case algorithmUnsupported(JSONWebTokenAlgorithm)
}

public enum JSONWebTokenAlgorithm: String, Codable, Hashable, Sendable {
	case HS256
	case HS384
	case HS512
	case RS256
	case RS384
	case RS512

	case ES256
	case ES384
	case ES512
	
	case PS256
	case PS384
	case PS512
	
	case none
	
	public func check(_ other: JSONWebTokenAlgorithm) throws {
		if self != other {
			throw JSONWebTokenError.algorithmMismatch(self, other)
		}
	}
}

public struct JSONWebTokenHeader: Codable, Hashable, Sendable {
	public var algorithm: JSONWebTokenAlgorithm
	public var type: String?
	public var keyId: String?
	public var jwk: JSONWebKey?
		
	enum CodingKeys: String, CodingKey {
		case algorithm = "alg"
		case type = "typ"
		case keyId = "kid"
		case jwk = "jwk"
	}
	
	public init(algorithm: JSONWebTokenAlgorithm, type: String? = nil, keyId: String? = nil, jwk: JSONWebKey? = nil) {
		self.algorithm = algorithm
		self.type = type
		self.keyId = keyId
		self.jwk = jwk
	}
}

public enum JSONWebTokenAudience: Hashable, Sendable {
	case single(String)
	case array([String])
}

extension JSONWebTokenAudience: Codable {
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

public protocol JSONWebTokenPayload: Codable {
	/// Issuer
	var iss: String? { get }
	/// Subject
	var sub: String? { get }
	/// Audience
	var aud: JSONWebTokenAudience? { get }
	/// Unique Code
	var jti: String? { get }
	/// Not Before
	var nbf: Date? { get }
	/// Created At
	var iat: Date? { get }
	/// Expires At
	var exp: Date? { get }
}

extension JSONWebTokenPayload {
	public var iss: String? { nil }
	public var sub: String? { nil }
	public var aud: JSONWebTokenAudience? { nil }
	public var jti: String? { nil }
	public var nbf: Date? { nil }
	public var iat: Date? { nil }
	public var exp: Date? { nil }
}

public typealias JSONWebTokenSigner = (JSONWebTokenAlgorithm, Data) throws -> Data
public typealias JSONWebTokenValidator = (JSONWebTokenAlgorithm, _ message: Data, _ signature: Data) throws -> Bool

public struct JSONWebToken<Payload: JSONWebTokenPayload> {
	public let header: JSONWebTokenHeader
	public let payload: Payload
	
	public init(header: JSONWebTokenHeader, payload: Payload) {
		self.header = header
		self.payload = payload
	}
	
	public func encode(with signer: JSONWebTokenSigner) throws -> String {
		let encoder = JSONEncoder.jsonWebTokenEncoder
		
		let headerString = try encoder.encode(header).base64EncodedURLEncodedString()
		let payloadString = try encoder.encode(payload).base64EncodedURLEncodedString()
		
		let inputData = [headerString, payloadString].joined(separator: ".")
		let signatureData = try signer(header.algorithm, Data(inputData.utf8))

		let signature = signatureData.base64EncodedURLEncodedString()
		
		return [headerString, payloadString, signature].joined(separator: ".")
	}
}

extension JSONWebToken: Equatable where Payload: Equatable {}
extension JSONWebToken: Hashable where Payload: Hashable {}
extension JSONWebToken: Sendable where Payload: Sendable {}

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
		
		self.header = try decoder.decode(JSONWebTokenHeader.self, from: headerData)
		self.payload = try decoder.decode(Payload.self, from: payloadData)
		
		let message = Data(components.dropLast().joined(separator: ".").utf8)
		
		guard try validator(self.header.algorithm, message, signatureData) else {
			throw JSONWebTokenError.signatureInvalid
		}
	}
}
