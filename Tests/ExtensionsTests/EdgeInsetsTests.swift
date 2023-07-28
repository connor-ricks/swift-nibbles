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

@testable import Extensions
import XCTest
import SwiftUI

class EdgeInsetsTests: XCTestCase {
    func test_zeroStaticProperty_initializesCorrectInsets() {
        let expected = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let actual = EdgeInsets.zero
        XCTAssertEqual(expected, actual)
    }

    func test_singleInsetInitializer_initializesCorrectInsets() {
        let expected = EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        let actual = EdgeInsets(padding: 10)
        XCTAssertEqual(expected, actual)
    }

    func test_axisInsetsInitializer_initializesCorrectInsets() {
        let expected = EdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5)
        let actual = EdgeInsets.init(vertical: 10, horizontal: 5)
        XCTAssertEqual(expected, actual)
    }
}
