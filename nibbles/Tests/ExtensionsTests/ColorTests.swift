@testable import Extensions
import XCTest
import SwiftUI

class ColorTests: XCTestCase {
    func test_color_encodedToData_matchesExpectedJSON() throws {
        let expectedData = #"{"alpha":0.75,"blue":0.5,"green":0.5,"red":0.5}"#.data(using: .utf8)!
        
        let color = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5, opacity: 0.75)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(color)
        
        XCTAssertEqual(expectedData, data)
    }
    
    func test_json_decodedToColor_matchesExpectedColor() throws {
        let expectedColor = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5, opacity: 0.75)
        
        let data = #"{"alpha":0.75,"blue":0.5,"green":0.5,"red":0.5}"#.data(using: .utf8)!
        let decoder = JSONDecoder()
        let color = try decoder.decode(Color.self, from: data)
        
        XCTAssertEqual(color, expectedColor)
    }
}
