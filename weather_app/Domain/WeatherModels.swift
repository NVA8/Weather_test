//
//  WeatherModels.swift
//  weather_app
//
//  Created by Valeriy Nikitin on 2023-10-08.
//

import Foundation
import CoreLocation

/// Domain layer representations that power the UI.
struct WeatherBundle: Identifiable, Equatable {
    let id = UUID()
    let location: WeatherLocation
    let current: CurrentWeather
    let hourly: [HourlyWeather]
    let daily: [DailyWeather]
    let fetchedAt: Date
}

struct WeatherLocation: Equatable {
    let city: String
    let region: String?
    let country: String?
    let coordinate: CLLocationCoordinate2D
    
    var displayName: String {
        if let region, !region.isEmpty {
            return "\(city), \(region)"
        }
        return city
    }
}

struct CurrentWeather: Equatable {
    struct Metric: Equatable {
        let value: Double
        let unit: String
    }
    
    let temperature: Double
    let description: String
    let condition: WeatherCondition
    let humidity: Double
    let pressure: Double
    let windSpeed: Double
    let windDirection: Double
    let feelsLike: Double
    
    var temperatureMetric: Metric { .init(value: temperature, unit: "°C") }
    var humidityMetric: Metric { .init(value: humidity, unit: "%") }
    var windMetric: Metric { .init(value: windSpeed, unit: "м/с") }
    var pressureMetric: Metric { .init(value: pressure, unit: "мм рт. ст.") }
}

struct HourlyWeather: Identifiable, Equatable {
    let id = UUID()
    let time: Date
    let temperature: Double
    let condition: WeatherCondition
    let pop: Double
}

struct DailyWeather: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let min: Double
    let max: Double
    let condition: WeatherCondition
    let sunrise: Date
    let sunset: Date
}

enum WeatherCondition: String, Codable, CaseIterable {
    case clear, clouds, rain, drizzle, thunderstorm, snow, atmosphere, unknown
    
    init(iconCode: String) {
        switch iconCode.prefix(2) {
        case "01": self = .clear
        case "02", "03", "04": self = .clouds
        case "09": self = .drizzle
        case "10": self = .rain
        case "11": self = .thunderstorm
        case "13": self = .snow
        case "50": self = .atmosphere
        default: self = .unknown
        }
    }
}

struct WeatherHistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let city: String
    let temperature: Double
    let condition: WeatherCondition
    
    init(id: UUID = UUID(), date: Date, city: String, temperature: Double, condition: WeatherCondition) {
        self.id = id
        self.date = date
        self.city = city
        self.temperature = temperature
        self.condition = condition
    }
}
