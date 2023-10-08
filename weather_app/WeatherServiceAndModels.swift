//
//  WeatherServiceAndModels.swift
//  weather_app
//
//  Created by Валерий Никитин on 08.10.2023.
//

import Foundation

class WeatherService: ObservableObject {
    let apiKey = "688e3a57c8fa654211ffbd45bd5c4d15"
    let baseURL = "https://api.openweathermap.org/data/2.5/"
    
    @Published var weatherResponse: WeatherResponse?
    @Published var error: Error?
    
    func fetchWeather(for city: String) {
        print("Запрос погоды для города: \(city)")
        
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        let urlString = "\(baseURL)weather?q=\(encodedCity)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            print("Ошибка формирования URL: \(urlString)")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.error = error
                    print("Ошибка URLSession: \(error.localizedDescription)")
                }
                return
            }
            
            if let data = data {
                DispatchQueue.main.async {
                    print("Ответ сервера: \(String(data: data, encoding: .utf8) ?? "Не удалось преобразовать данные в строку")")
                    do {
                        self.weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
                        print("Получены данные погоды: \(self.weatherResponse)")
                    } catch {
                        print("Ошибка декодирования данных: \(error.localizedDescription)")
                    }
                }
            }
        }.resume()
    }
}

struct WeatherResponse: Codable {
    let main: MainWeather
    let weather: [WeatherInfo]
    let wind: WindInfo
    let name: String
}

struct MainWeather: Codable {
    let temp: Double
    let humidity: Int
    let temp_min: Double
    let temp_max: Double
}

struct WeatherInfo: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct WindInfo: Codable {
    let speed: Double
    let deg: Int
}
