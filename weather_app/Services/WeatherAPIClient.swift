//
//  WeatherAPIClient.swift
//  weather_app
//
//  Created by Valeriy Nikitin on 2023-10-08.
//

import Foundation
import CoreLocation

struct WeatherAPIClient {
    static let shared = WeatherAPIClient()
    
    private let apiKey = "688e3a57c8fa654211ffbd45bd5c4d15"
    private let baseURL = URL(string: "https://api.openweathermap.org/data/2.5")!
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
    
    func currentWeather(for query: String) async throws -> CurrentWeatherResponse {
        let url = baseURL
            .appendingPathComponent("weather")
            .appending("q", value: query)
        return try await fetch(url: url)
    }
    
    func currentWeather(for coordinate: CLLocationCoordinate2D) async throws -> CurrentWeatherResponse {
        let url = baseURL
            .appendingPathComponent("weather")
            .appending("lat", value: "\(coordinate.latitude)")
            .appending("lon", value: "\(coordinate.longitude)")
        return try await fetch(url: url)
    }
    
    func forecast(for coordinate: CLLocationCoordinate2D) async throws -> ForecastResponse {
        let url = baseURL
            .appendingPathComponent("onecall")
            .appending("lat", value: "\(coordinate.latitude)")
            .appending("lon", value: "\(coordinate.longitude)")
            .appending("exclude", value: "minutely,alerts")
        return try await fetch(url: url)
    }
    
    private func fetch<T: Decodable>(url: URL) async throws -> T {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "appid", value: apiKey))
        queryItems.append(URLQueryItem(name: "units", value: "metric"))
        queryItems.append(URLQueryItem(name: "lang", value: "ru"))
        components.queryItems = queryItems
        
        guard let finalURL = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) == false {
            throw WeatherAPIError(code: http.statusCode)
        }
        
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - API Response Models

struct CurrentWeatherResponse: Decodable {
    struct Coordinate: Decodable {
        let lon: Double
        let lat: Double
    }
    
    struct Main: Decodable {
        let temp: Double
        let feels_like: Double
        let pressure: Double
        let humidity: Double
    }
    
    struct Wind: Decodable {
        let speed: Double
        let deg: Double
    }
    
    struct Weather: Decodable {
        let main: String
        let description: String
        let icon: String
    }
    
    struct Sys: Decodable {
        let country: String?
    }
    
    let coord: Coordinate
    let weather: [Weather]
    let main: Main
    let wind: Wind
    let name: String
    let sys: Sys
}

struct ForecastResponse: Decodable {
    struct Current: Decodable {
        let dt: Date
        let sunrise: Date
        let sunset: Date
        let temp: Double
        let feels_like: Double
        let pressure: Double
        let humidity: Double
        let wind_speed: Double
        let wind_deg: Double
        let weather: [CurrentWeatherResponse.Weather]
    }
    
    struct Hourly: Decodable {
        let dt: Date
        let temp: Double
        let pop: Double
        let weather: [CurrentWeatherResponse.Weather]
    }
    
    struct Daily: Decodable {
        struct Temp: Decodable {
            let min: Double
            let max: Double
        }
        
        let dt: Date
        let sunrise: Date
        let sunset: Date
        let temp: Temp
        let weather: [CurrentWeatherResponse.Weather]
    }
    
    let timezone: String
    let current: Current
    let hourly: [Hourly]
    let daily: [Daily]
}

struct WeatherAPIError: LocalizedError {
    let code: Int
    var errorDescription: String? {
        "Ошибка запроса (\(code))."
    }
}

// MARK: - Helpers

private extension URL {
    func appending(_ queryItem: String, value: String) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return self }
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: queryItem, value: value))
        components.queryItems = items
        return components.url ?? self
    }
}
