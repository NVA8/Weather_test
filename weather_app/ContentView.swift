//
//  ContentView.swift
//  weather_app
//
//  Created by Валерий Никитин on 08.10.2023.
//


import SwiftUI

struct WeatherView: View {
    @ObservedObject var weatherService = WeatherService()
    @State private var searchText = ""

    var body: some View {
        VStack {
            SearchBar(text: $searchText, onSearch: {
                weatherService.fetchWeather(for: searchText)
            })

            if let weather = weatherService.weatherResponse {
                Text("\(weather.main.temp)°C")
                Text("Влажность: \(weather.main.humidity)%")
                Text("Скорость ветра: \(weather.wind.speed) м/с")
            } else if let error = weatherService.error {
                Text("Ошибка: \(error.localizedDescription)")
            } else {
                Text("Введите название города для поиска")
            }
        }
        .padding()
    }
}

struct SearchBar: View {
    @Binding var text: String
    var onSearch: () -> Void

    var body: some View {
        HStack {
            TextField("Введите город...", text: $text)
                .onChange(of: text, perform: { value in
                    onSearch()
                })
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                    }
                )
                .padding(.horizontal, 10)
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            WeatherView()
                .navigationTitle("Погода")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
