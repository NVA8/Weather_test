//
//  WeatherRepository.swift
//  weather_app
//
//  Created by Valeriy Nikitin on 2023-10-08.
//

import Foundation
import CoreLocation

protocol WeatherRepositoryProtocol {
    func weather(for city: String) async throws -> WeatherBundle
    func weather(for coordinate: CLLocationCoordinate2D) async throws -> WeatherBundle
}

struct WeatherRepository: WeatherRepositoryProtocol {
    private let api: WeatherAPIClient
    private let geocoder = CLGeocoder()
    
    init(api: WeatherAPIClient = .shared) {
        self.api = api
    }
    
    func weather(for city: String) async throws -> WeatherBundle {
        let current = try await api.currentWeather(for: city)
        let coordinate = CLLocationCoordinate2D(latitude: current.coord.lat, longitude: current.coord.lon)
        let forecast = try await api.forecast(for: coordinate)
        let location = try await resolveLocationName(for: coordinate, fallback: current.name, country: current.sys.country)
        return convert(current: current, forecast: forecast, location: location)
    }
    
    func weather(for coordinate: CLLocationCoordinate2D) async throws -> WeatherBundle {
        async let currentResponse = api.currentWeather(for: coordinate)
        async let forecastResponse = api.forecast(for: coordinate)
        async let location = resolveLocationName(for: coordinate, fallback: "", country: nil)
        let current = try await currentResponse
        let forecast = try await forecastResponse
        let resolved = try await location
        return convert(current: current, forecast: forecast, location: resolved)
    }
    
    private func resolveLocationName(for coordinate: CLLocationCoordinate2D, fallback: String, country: String?) async throws -> WeatherLocation {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemark = try await geocoder.reverseGeocodeLocation(location).first
        let city = placemark?.locality ?? fallback
        let region = placemark?.administrativeArea
        let countryName = placemark?.country ?? country
        return WeatherLocation(city: city, region: region, country: countryName, coordinate: coordinate)
    }
    
    private func convert(current: CurrentWeatherResponse, forecast: ForecastResponse, location: WeatherLocation) -> WeatherBundle {
        let currentWeather = CurrentWeather(
            temperature: current.main.temp,
            description: current.weather.first?.description.capitalized ?? "",
            condition: WeatherCondition(iconCode: current.weather.first?.icon ?? ""),
            humidity: current.main.humidity,
            pressure: current.main.pressure * 0.750062, // hPa -> mmHg
            windSpeed: current.wind.speed,
            windDirection: current.wind.deg,
            feelsLike: forecast.current.feels_like
        )
        
        let hourly = forecast.hourly.prefix(24).map {
            HourlyWeather(
                time: $0.dt,
                temperature: $0.temp,
                condition: WeatherCondition(iconCode: $0.weather.first?.icon ?? ""),
                pop: $0.pop
            )
        }
        
        let daily = forecast.daily.prefix(7).map {
            DailyWeather(
                date: $0.dt,
                min: $0.temp.min,
                max: $0.temp.max,
                condition: WeatherCondition(iconCode: $0.weather.first?.icon ?? ""),
                sunrise: $0.sunrise,
                sunset: $0.sunset
            )
        }
        
        return WeatherBundle(
            location: location,
            current: currentWeather,
            hourly: hourly,
            daily: daily,
            fetchedAt: Date()
        )
    }
}
