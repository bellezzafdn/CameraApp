// FilterManager.swift
import Foundation
import SceneKit
import UIKit

/// Manages the three filter textures (“6 di fiori”, “6 di stelle”, “6 di cuori”).
/// If PNG files are present in the app bundle they are loaded; otherwise the manager
/// creates simple programmatic textures at runtime (so the app works even on Windows
/// where the user cannot easily provide PNG assets).
final class FilterManager {
    static let shared = FilterManager()
    private var textures: [UIImage] = []
    private let textureNames = ["sixFlowers", "sixStars", "sixHearts"]
    
    private init() {
        loadOrGenerateTextures()
    }
    
    /// Load PNGs from the bundle; if any are missing we generate a placeholder image.
    private func loadOrGenerateTextures() {
        for name in textureNames {
            if let img = UIImage(named: name) {
                textures.append(img)
            } else {
                // Generate a simple texture programmatically.
                let generated = generateTexture(for: name)
                textures.append(generated)
                print("⚠️ FilterManager: missing \(name).png – generated fallback texture.")
            }
        }
    }
    
    /// Returns a new SCNNode containing a plane geometry with a randomly chosen texture.
    func nextRandomFilter() -> SCNNode {
        let texture = textures.randomElement() ?? UIImage()
        // Plane size approximates a playing‑card (≈ 8.5 cm × 5.5 cm).
        let plane = SCNPlane(width: 0.085, height: 0.055)
        plane.firstMaterial?.diffuse.contents = texture
        plane.firstMaterial?.isDoubleSided = true
        plane.firstMaterial?.lightingModel = .physicallyBased
        let node = SCNNode(geometry: plane)
        return node
    }
    
    // MARK: – Programmatic texture generation
    private func generateTexture(for key: String) -> UIImage {
        // 256 × 256 pt canvas with transparent background.
        let size = CGSize(width: 256, height: 256)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return UIImage() }
        // Draw the numeral "6" in the centre.
        let number = "6" as NSString
        let numberFont = UIFont.systemFont(ofSize: 180, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [.font: numberFont, .foregroundColor: UIColor.white]
        let textSize = number.size(withAttributes: attrs)
        let textRect = CGRect(x: (size.width - textSize.width) / 2,
                              y: (size.height - textSize.height) / 2,
                              width: textSize.width,
                              height: textSize.height)
        number.draw(in: textRect, withAttributes: attrs)
        // Overlay a simple pattern depending on the key.
        switch key {
        case "sixFlowers":
            drawFlowerPattern(in: ctx, canvasSize: size)
        case "sixStars":
            drawStarPattern(in: ctx, canvasSize: size)
        case "sixHearts":
            drawHeartPattern(in: ctx, canvasSize: size)
        default:
            break
        }
        // Retrieve image.
        let img = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        return img
    }
    
    // Simple flower: 5 pink circles around the centre.
    private func drawFlowerPattern(in ctx: CGContext, canvasSize: CGSize) {
        let radius: CGFloat = 12
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        ctx.setFillColor(UIColor.systemPink.cgColor)
        for i in 0..<5 {
            let angle = CGFloat(i) * (2 * .pi / 5)
            let offset = CGPoint(x: cos(angle) * 40, y: sin(angle) * 40)
            let petalCenter = CGPoint(x: center.x + offset.x, y: center.y + offset.y)
            ctx.addEllipse(in: CGRect(x: petalCenter.x - radius,
                                      y: petalCenter.y - radius,
                                      width: radius * 2,
                                      height: radius * 2))
            ctx.fillPath()
        }
    }
    
    // Simple star: 5‑pointed star using UIBezierPath.
    private func drawStarPattern(in ctx: CGContext, canvasSize: CGSize) {
        let starPath = UIBezierPath()
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let outerRadius: CGFloat = 40
        let innerRadius: CGFloat = 16
        for i in 0..<5 {
            let angle = CGFloat(i) * (2 * .pi / 5) - .pi / 2
            let outer = CGPoint(x: center.x + cos(angle) * outerRadius,
                                y: center.y + sin(angle) * outerRadius)
            let inner = CGPoint(x: center.x + cos(angle + .pi / 5) * innerRadius,
                                y: center.y + sin(angle + .pi / 5) * innerRadius)
            if i == 0 { starPath.move(to: outer) } else { starPath.addLine(to: outer) }
            starPath.addLine(to: inner)
        }
        starPath.close()
        ctx.setFillColor(UIColor.systemYellow.cgColor)
        ctx.addPath(starPath.cgPath)
        ctx.fillPath()
    }
    
    // Simple heart shape via UIBezierPath.
    private func drawHeartPattern(in ctx: CGContext, canvasSize: CGSize) {
        let heartPath = UIBezierPath()
        let width = canvasSize.width
        let height = canvasSize.height
        heartPath.move(to: CGPoint(x: width/2, y: height*0.75))
        heartPath.addCurve(to: CGPoint(x: width*0.25, y: height*0.35),
                           controlPoint1: CGPoint(x: width*0.50, y: height*0.55),
                           controlPoint2: CGPoint(x: width*0.25, y: height*0.45))
        heartPath.addArc(withCenter: CGPoint(x: width*0.35, y: height*0.35),
                         radius: width*0.10,
                         startAngle: .pi,
                         endAngle: 0,
                         clockwise: true)
        heartPath.addArc(withCenter: CGPoint(x: width*0.65, y: height*0.35),
                         radius: width*0.10,
                         startAngle: .pi,
                         endAngle: 0,
                         clockwise: true)
        heartPath.addCurve(to: CGPoint(x: width/2, y: height*0.75),
                           controlPoint1: CGPoint(x: width*0.75, y: height*0.45),
                           controlPoint2: CGPoint(x: width*0.50, y: height*0.55))
        ctx.setFillColor(UIColor.systemRed.cgColor)
        ctx.addPath(heartPath.cgPath)
        ctx.fillPath()
    }
}

// Helper extension for solid‑color placeholder (used elsewhere).
extension UIImage {
    convenience init?(color: UIColor, size: CGSize) {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        color.setFill()
        UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
        guard let cg = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else { return nil }
        self.init(cgImage: cg)
    }
}
