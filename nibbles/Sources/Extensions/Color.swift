import UIKit
import SwiftUI

extension Color: Codable {

    // MARK: Decodable

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let r = try container.decode(Double.self, forKey: .red)
        let g = try container.decode(Double.self, forKey: .green)
        let b = try container.decode(Double.self, forKey: .blue)
        let a = try container.decode(Double.self, forKey: .alpha)
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    // MARK: Codable

    public func encode(to encoder: Encoder) throws {
        guard let colorComponents = colorComponents else {
            throw EncodingError.invalidValue(self, .init(
                codingPath: CodingKeys.allCases,
                debugDescription: "Unable to get colorComponents from Color."
            ))
        }

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(colorComponents.red, forKey: .red)
        try container.encode(colorComponents.green, forKey: .green)
        try container.encode(colorComponents.blue, forKey: .blue)
        try container.encode(colorComponents.alpha, forKey: .alpha)
    }
    
    private var colorComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return nil
        }

        return (r, g, b, a)
    }

    // MARK: CodingKeys

    enum CodingKeys: String, CodingKey, CaseIterable {
        case red
        case green
        case blue
        case alpha
    }
}
