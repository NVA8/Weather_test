//
//  AnimatedWeatherBackground.swift
//  weather_app
//
//  Created by Valeriy Nikitin on 2023-10-08.
//

import SwiftUI
import UIKit

struct AnimatedWeatherBackground: View {
    var condition: WeatherCondition?
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let gradient = gradientForCondition(condition, time: time)
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(gradient,
                                          startPoint: CGPoint(x: 0, y: size.height),
                                          endPoint: CGPoint(x: size.width, y: 0))
                )
                
                // Add subtle moving particles to give a sense of atmosphere.
                let particleCount = 80
                let baseAngle = time.truncatingRemainder(dividingBy: .pi * 2)
                
                for index in 0..<particleCount {
                    let progress = Double(index) / Double(particleCount)
                    let x = cos(baseAngle + progress * .pi * 2) * 40 + Double(size.width) * progress
                    let y = (sin(baseAngle * 0.8 + progress * .pi * 2) + 1) * Double(size.height) * 0.5
                    let rect = CGRect(x: x, y: y, width: 2, height: 2)
                    context.fill(Path(ellipseIn: rect), with: .color(particleColor(for: condition)))
                }
            }
        }
    }
    
    private func gradientForCondition(_ condition: WeatherCondition?, time: Double) -> Gradient {
        let phase = 0.5 * sin(time / 10) + 0.5
        switch condition {
        case .clear:
            return Gradient(colors: [
                Color(red: 0.20, green: 0.41, blue: 0.89),
                Color(red: 0.87, green: 0.62, blue: 1.0).opacity(0.7)
            ].map { $0.mix(with: .black, factor: phase * 0.25) })
        case .clouds:
            return Gradient(colors: [
                Color(red: 0.36, green: 0.44, blue: 0.61),
                Color(red: 0.16, green: 0.20, blue: 0.30)
            ].map { $0.mix(with: .black, factor: phase * 0.2) })
        case .rain, .drizzle:
            return Gradient(colors: [
                Color(red: 0.24, green: 0.32, blue: 0.54),
                Color(red: 0.07, green: 0.07, blue: 0.12)
            ])
        case .snow:
            return Gradient(colors: [
                Color(red: 0.75, green: 0.84, blue: 0.94),
                Color(red: 0.35, green: 0.46, blue: 0.70)
            ])
        case .thunderstorm:
            return Gradient(colors: [
                Color(red: 0.16, green: 0.19, blue: 0.33),
                Color(red: 0.05, green: 0.06, blue: 0.10)
            ])
        case .atmosphere:
            return Gradient(colors: [
                Color(red: 0.38, green: 0.56, blue: 0.70),
                Color(red: 0.15, green: 0.20, blue: 0.30)
            ])
        default:
            return Gradient(colors: [
                Color(red: 0.24, green: 0.33, blue: 0.58),
                Color(red: 0.10, green: 0.14, blue: 0.22)
            ])
        }
    }
    
    private func particleColor(for condition: WeatherCondition?) -> Color {
        switch condition {
        case .clear: return Color.white.opacity(0.6)
        case .snow: return Color.white.opacity(0.8)
        case .thunderstorm: return Color.yellow.opacity(0.5)
        default: return Color.white.opacity(0.3)
        }
    }
}

private extension Color {
    func mix(with color: Color, factor: Double) -> Color {
        let factor = max(0, min(1, factor))
        let from = UIColor(self)
        let to = UIColor(color)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        from.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        to.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(
            red: Double(r1 + (r2 - r1) * factor),
            green: Double(g1 + (g2 - g1) * factor),
            blue: Double(b1 + (b2 - b1) * factor),
            opacity: Double(a1 + (a2 - a1) * factor)
        )
    }
}
