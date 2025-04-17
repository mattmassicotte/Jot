import Foundation

extension JSONEncoder {
	public static var jsonWebTokenEncoder: JSONEncoder {
		let encoder = JSONEncoder()
		
		encoder.dataEncodingStrategy = .custom({ data, encoder in
			var container = encoder.singleValueContainer()
			
			try container.encode(data.base64EncodedURLEncodedString())
		})
		
		encoder.dateEncodingStrategy = .custom({ date, encoder in
			var container = encoder.singleValueContainer()
			
			try container.encode(Int(date.timeIntervalSince1970))
		})
		
		encoder.outputFormatting = .sortedKeys

		return encoder
	}
}

extension JSONDecoder {
	public static var jsonWebTokenDecoder: JSONDecoder {
		let decoder = JSONDecoder()
		
		decoder.dataDecodingStrategy = .custom({ decoder in
			let container = try decoder.singleValueContainer()
			
			let base64 = try container.decode(String.self)
			
			guard let data = Data(base64URLEncoded: base64) else {
				throw JSONWebTokenError.base64DecodingFailed
			}
			
			return data
		})
		
		decoder.dateDecodingStrategy = .custom({ decoder in
			let container = try decoder.singleValueContainer()
			
			let value = try container.decode(Int.self)
			
			return Date(timeIntervalSince1970: TimeInterval(value))
		})

		return decoder
	}
}
