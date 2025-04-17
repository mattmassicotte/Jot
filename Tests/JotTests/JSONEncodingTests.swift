import Foundation
import Testing

import Jot

struct JSONEncodingTests {
	@Test func encodeData() throws {
		let value = try JSONEncoder.jsonWebTokenEncoder.encode(Data("foo+bar/baz".utf8))
	
		#expect(String(decoding: value, as: UTF8.self) == "\"Zm9vK2Jhci9iYXo\"")
	}
	
	@Test func decodeData() throws {
		let input = "\"Zm9vK2Jhci9iYXo\""
		let value = try JSONDecoder.jsonWebTokenDecoder.decode(Data.self, from: Data(input.utf8))
		
		#expect(String(decoding: value, as: UTF8.self) == "foo+bar/baz")
	}
	
	@Test func noPadding() throws {
		let input = "\"YWJj\""
		let value = try JSONDecoder.jsonWebTokenDecoder.decode(Data.self, from: Data(input.utf8))
		
		#expect(String(decoding: value, as: UTF8.self) == "abc")
	}
	
	@Test func onePadding() throws {
		let input = "\"YWI\""
		let value = try JSONDecoder.jsonWebTokenDecoder.decode(Data.self, from: Data(input.utf8))
		
		#expect(String(decoding: value, as: UTF8.self) == "ab")
	}
	
	@Test func twoPadding() throws {
		let input = "\"YQ\""
		let value = try JSONDecoder.jsonWebTokenDecoder.decode(Data.self, from: Data(input.utf8))
		
		#expect(String(decoding: value, as: UTF8.self) == "a")
	}
}
