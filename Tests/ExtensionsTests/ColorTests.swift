// MIT License
//
// Copyright (c) 2023 Connor Ricks
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#if canImport(UIKit)
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
    
    func test_jsonWithInvalidColor_decodedToColor_throwsError() throws {
        let data = #"{"dog":0.75,"cat":0.5,"cow":0.5,"horse":0.5}"#.data(using: .utf8)!
        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(Color.self, from: data))
    }
}
#endif
