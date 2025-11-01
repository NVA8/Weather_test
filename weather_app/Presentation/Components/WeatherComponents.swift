//
//  WeatherComponents.swift
//  weather_app
//
//  Created by Valeriy Nikitin on 2023-10-08.
//

import SwiftUI

struct CurrentWeatherCard: View {
    let weather: CurrentWeather
    let fetchedAt: Date
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(weather.description)
                        .font(.title2.weight(.semibold))
                        .opacity(0.85)
                    Text("Обновлено \(formatter.string(from: fetchedAt))")
                        .font(.footnote)
                        .opacity(0.6)
                }
                Spacer()
                WeatherIcon(condition: weather.condition)
                    .frame(width: 72, height: 72)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text(Int(weather.temperature).description)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                Text("°C")
                    .font(.title2).opacity(0.7)
            }
            
            HStack(spacing: 16) {
                MetricLabel(icon: "wind", title: "Ветер", value: formatted(weather.windSpeed, unit: "м/с"))
                MetricLabel(icon: "humidity", title: "Влажность", value: formatted(weather.humidity, unit: "%"))
                MetricLabel(icon: "thermometer", title: "Ощущается", value: formatted(weather.feelsLike, unit: "°C"))
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func formatted(_ value: Double, unit: String) -> String {
        let number = Int(round(value))
        return "\(number)\(unit)"
    }
}

struct MetricLabel: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.footnote)
                .opacity(0.6)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WeatherIcon: View {
    let condition: WeatherCondition
    @State private var wave: Double = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = (sin(timeline.date.timeIntervalSinceReferenceDate / 2) + 1) / 2
            ZStack {
                icon
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white.opacity(0.9), Color.white.opacity(0.3))
                    .scaleEffect(0.9 + phase * 0.1)
                    .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 12)
            }
            .animation(.easeInOut(duration: 2.0), value: phase)
        }
    }
    
    private var icon: Image {
        switch condition {
        case .clear: return Image(systemName: "sun.max.fill")
        case .clouds: return Image(systemName: "cloud.fill")
        case .rain: return Image(systemName: "cloud.rain.fill")
        case .drizzle: return Image(systemName: "cloud.drizzle.fill")
        case .thunderstorm: return Image(systemName: "cloud.bolt.rain.fill")
        case .snow: return Image(systemName: "cloud.snow.fill")
        case .atmosphere: return Image(systemName: "cloud.fog.fill")
        case .unknown: return Image(systemName: "questionmark.circle.fill")
        }
    }
}

struct HourlyForecastView: View {
    let hourly: [HourlyWeather]
    
    private let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Прогноз на сутки")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(hourly) { hour in
                        VStack(spacing: 12) {
                            Text(hourFormatter.string(from: hour.time))
                                .font(.footnote)
                                .opacity(0.7)
                            WeatherIcon(condition: hour.condition)
                                .frame(height: 28)
                            Text("\(Int(round(hour.temperature)))°")
                                .font(.headline)
                            HStack(spacing: 4) {
                                Image(systemName: "drop.fill")
                                    .font(.caption2)
                                Text("\(Int(round(hour.pop * 100)))%")
                                    .font(.caption2)
                            }
                            .opacity(0.6)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

struct DailyForecastView: View {
    let daily: [DailyWeather]
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Недельный прогноз")
                .font(.headline)
            ForEach(daily) { day in
                HStack(spacing: 16) {
                    Text(dayFormatter.string(from: day.date).capitalized)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    WeatherIcon(condition: day.condition)
                        .frame(width: 32, height: 32)
                    Text("\(Int(round(day.min)))° / \(Int(round(day.max)))°")
                        .font(.headline)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

struct HistoryTimelineView: View {
    let history: [WeatherHistoryEntry]
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("История запросов")
                .font(.headline)
            ForEach(history) { item in
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.city)
                            .font(.headline)
                        Text(formatter.string(from: item.date))
                            .font(.caption)
                            .opacity(0.6)
                    }
                    Spacer()
                    WeatherIcon(condition: item.condition)
                        .frame(width: 28, height: 28)
                    Text("\(Int(round(item.temperature)))°")
                        .font(.headline)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

struct RefreshFloatingButton: View {
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                }
            }
            .frame(width: 48, height: 48)
            .background(Color.white.opacity(0.18), in: Circle())
            .overlay(
                Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView("Загружаем прогноз…")
                .progressViewStyle(.circular)
                .tint(.white)
            Text("Подбираем лучшие данные с сервера OpenWeather.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .opacity(0.6)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

struct ErrorStateView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
            Button("Повторить") {
                retryAction()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.18), in: Capsule())
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

struct PlaceholderStateView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
            Text("Введите город или используйте геолокацию,\nчтобы увидеть магию прогноза.")
                .multilineTextAlignment(.center)
                .opacity(0.7)
        }
        .padding(36)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}
