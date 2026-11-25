import UIKit

extension UIImage {
    /// Ridimensiona mantenendo le proporzioni, senza upscaling.
    func atelierDownscaled(maxDimension: CGFloat) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension, longestSide > 0 else { return self }
        let ratio = maxDimension / longestSide
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

/// Rileva il colore dominante di una foto, escludendo lo sfondo bianco quando possibile.
enum DominantColor {

    static func suggestColor(from image: UIImage) -> RGBColor? {
        let small = image.atelierDownscaled(maxDimension: 64)
        guard let cgImage = small.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drew: Bool = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress,
                                          width: width,
                                          height: height,
                                          bitsPerComponent: 8,
                                          bytesPerRow: width * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                return false
            }
            context.interpolationQuality = .low
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            return true
        }
        guard drew else { return nil }

        struct Bucket {
            var count = 0
            var red = 0.0
            var green = 0.0
            var blue = 0.0
            var saturation = 0.0
        }

        var buckets: [String: Bucket] = [:]
        var index = 0
        while index + 3 < pixels.count {
            let red = Double(pixels[index]) / 255.0
            let green = Double(pixels[index + 1]) / 255.0
            let blue = Double(pixels[index + 2]) / 255.0
            let alpha = Double(pixels[index + 3]) / 255.0
            index += 4

            guard alpha > 0.5 else { continue }
            let color = RGBColor(r: red, g: green, b: blue)
            let hsl = color.hsl
            let key = "\(Int(hsl.h / 15))-\(Int(hsl.s * 4))-\(Int(hsl.l * 4))"

            var bucket = buckets[key] ?? Bucket()
            bucket.count += 1
            bucket.red += red
            bucket.green += green
            bucket.blue += blue
            bucket.saturation += hsl.s
            buckets[key] = bucket
        }

        guard !buckets.isEmpty else { return nil }

        var bestKey: String?
        var bestWeight = -1.0
        for (key, bucket) in buckets {
            let averageSaturation = bucket.saturation / Double(bucket.count)
            // I colori saturi pesano di più: spesso lo sfondo è bianco o grigio.
            let weight = Double(bucket.count) * (0.25 + 1.6 * averageSaturation)
            if weight > bestWeight {
                bestWeight = weight
                bestKey = key
            }
        }

        guard let key = bestKey, let bucket = buckets[key], bucket.count > 0 else { return nil }
        let count = Double(bucket.count)
        return RGBColor(r: bucket.red / count, g: bucket.green / count, b: bucket.blue / count)
    }
}
