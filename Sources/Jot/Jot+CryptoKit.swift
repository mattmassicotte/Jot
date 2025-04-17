#if canImport(CryptoKit)
import CryptoKit
import Foundation

extension Data {
	var ellipticCurveComponents: (Data, Data) {
		let size = count / 2
		
		return (prefix(size), suffix(size))
	}
}

extension JSONWebKey.EllipticCurveParameters {
	public init(p256Key: P256.Signing.PublicKey) {
		let (x, y) = p256Key.rawRepresentation.ellipticCurveComponents
		
		self.init(curve: .P256, x: x, y: y)
	}
}

extension JSONWebKey {
	public init(p256Key: P256.Signing.PublicKey, use: KeyUse? = nil, id: String? = nil) {
		let curve = EllipticCurveParameters(p256Key: p256Key)
		
		self.init(params: curve, use: use, id: id)
	}
}

extension JSONWebToken {
	public func encode(with privateKey: P256.Signing.PrivateKey) throws -> String {
		try encode { algo, data in
			try algo.check(.ES256)
			
			let digest = SHA256.hash(data: data)
			
			let sig = try privateKey.signature(for: digest)
			
			return sig.rawRepresentation
		}
	}
	
	public init(encodedString: String, key: P256.Signing.PublicKey) throws {
		try self.init(encodedString: encodedString) { algo, message, signature in
			try algo.check(.ES256)
			
			let sig = try P256.Signing.ECDSASignature(rawRepresentation: signature)
			
			return key.isValidSignature(sig, for: message)
		}
	}
}
#endif
