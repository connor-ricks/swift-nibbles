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

import SwiftUI

extension EdgeInsets {
    /// A value that represents an `EdgeInsets` with zero around all edges.
    public static let zero: EdgeInsets = .init(padding: 0)

    /// Creates `EdgeInsets` using the provided `padding` for all edges.
    ///
    /// - Parameter padding: The value to be used for each edge.
    public init(padding: CGFloat) {
        self.init(
            top: padding,
            leading: padding,
            bottom: padding,
            trailing: padding
        )
    }

    /// Creates `EdgeInsets` using the provided `vertical` and `horizontal` values.
    /// 
    /// - Parameters:
    ///   - vertical: The value to be used for both the `top` and `bottom` edges.
    ///   - horizontal: The value to be used for both the `leading` and `trailing` edges.
    public init(vertical: CGFloat, horizontal: CGFloat) {
        self.init(
            top: vertical,
            leading: horizontal,
            bottom: vertical,
            trailing: horizontal
        )
    }
}
