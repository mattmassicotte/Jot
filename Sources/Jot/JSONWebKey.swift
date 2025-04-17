import Foundation

/// Model of a JSON Web Key.
///
/// Defined by: https://datatracker.ietf.org/doc/html/rfc7517
public struct JSONWebKey: Hashable, Sendable {
	public enum EllipticCurve : String, Hashable, Codable, Sendable {
		case P256 = "P-256"
	}
	
	public struct EllipticCurveParameters : Hashable, Sendable {
		public let curve: EllipticCurve
		public let x: Data
		public let y: Data
		
		public init(curve: EllipticCurve, x: Data, y: Data) {
			self.curve = curve
			self.x = x
			self.y = y
		}
	}
	
	public enum KeyType : Hashable, Sendable {
		case rsa
		case ec(EllipticCurveParameters)
	}
	
	public enum KeyUse : RawRepresentable, Hashable, Sendable {
		case signature
		case encryption
		case custom(String)
		
		public init?(rawValue: String) {
			switch rawValue {
			case "sig":
				self = .signature
			case "enc":
				self = .encryption
			default:
				self = .custom(rawValue)
			}
		}
		
		public var rawValue: String {
			switch self {
			case .encryption:
				"enc"
			case .signature:
				"sig"
			case let .custom(value):
				value
			}
		}
	}
	
	public let keyType: KeyType
	public let use: KeyUse?
	public let id: String?
	
	public init(keyType: KeyType, use: KeyUse? = nil, id: String? = nil) {
		self.keyType = keyType
		self.use = use
		self.id = id
	}
	
	public init(params: EllipticCurveParameters, use: KeyUse? = nil, id: String? = nil) {
		self.init(keyType: .ec(params), use: use, id: id)
	}
}

extension JSONWebKey : Codable {
	enum CodingKeys: String, CodingKey {
		case keyType = "kty"
		case use
		case id = "kid"
		case curve = "crv"
		case ecX = "x"
		case ecY = "y"
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		if let string = try container.decodeIfPresent(String.self, forKey: .use) {
			self.use = KeyUse(rawValue: string)
		} else {
			self.use = nil
		}
		
		self.id = (try container.decodeIfPresent(String.self, forKey: .id)) ?? nil
		
		let keyType = try container.decode(String.self, forKey: .keyType)
		
		switch keyType {
		case "RSA", "rsa":
			self.keyType = .rsa
		case "EC", "ec":
			let curve = try container.decode(EllipticCurve.self, forKey: .curve)
			let ecX = try container.decode(Data.self, forKey: .ecX)
			let ecY = try container.decode(Data.self, forKey: .ecY)
			
			self.keyType = .ec(EllipticCurveParameters(curve: curve, x: ecX, y: ecY))
		default:
			throw DecodingError.typeMismatch(
				JSONWebKey.self,
				DecodingError.Context.init(
					codingPath: container.codingPath,
					debugDescription: "Key type not decodable",
					underlyingError: nil
				)
			)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		switch keyType {
		case .rsa:
			try container.encode("RSA", forKey: .keyType)
		case let .ec(params):
			try container.encode("EC", forKey: .keyType)
			
			try container.encode(params.curve, forKey: .curve)
			try container.encode(params.x, forKey: .ecX)
			try container.encode(params.y, forKey: .ecY)
		}
		
		if let use {
			try container.encode(use.rawValue, forKey: .use)
		}
		
		if let id {
			try container.encode(id, forKey: .id)
		}
	}
}
