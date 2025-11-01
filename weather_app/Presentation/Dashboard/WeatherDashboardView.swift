//
//  WeatherDashboardView.swift
//  weather_app
//
//  Created by Valeriy Nikitin on 2023-10-08.
//

import SwiftUI

struct WeatherDashboardView: View {
    @StateObject private var viewModel = WeatherDashboardViewModel()
    @Namespace private var animationNamespace
    
    var body: some View {
        ZStack {
            AnimatedWeatherBackground(condition: viewModel.weather?.current.condition)
                .ignoresSafeArea()
            
            content
        }
        .onAppear {
            viewModel.onAppear()
        }
        .preferredColorScheme(.dark)
    }
    
    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                header
                searchSection
                stateSection
            }
            .padding(.vertical, 36)
            .padding(.horizontal, 20)
        }
        .overlay(alignment: .top) {
            RefreshFloatingButton(isLoading: viewModel.isLoading) {
                viewModel.refresh()
            }
            .padding(.top, 12)
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.weather?.location.displayName ?? "Погода вокруг вас")
                .font(.system(size: 34, weight: .bold))
                .matchedGeometryEffect(id: "locationTitle", in: animationNamespace)
            
            if let country = viewModel.weather?.location.country {
                Text(country)
                    .font(.headline)
                    .opacity(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                TextField("Город, страна...", text: $viewModel.searchQuery, onCommit: {
                    viewModel.search()
                })
                .textInputAutocapitalization(.words)
                .submitLabel(.search)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                Button {
                    viewModel.search()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
            }
            
            HStack {
                Label("Моё местоположение", systemImage: "location.fill")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Button {
                    viewModel.useCurrentLocation()
                } label: {
                    Text(buttonTitleForAuthorizationState(viewModel.authorizationState))
                        .font(.footnote)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    @ViewBuilder
    private var stateSection: some View {
        if viewModel.isLoading {
            LoadingStateView()
                .transition(.opacity.combined(with: .scale))
        } else if let error = viewModel.errorMessage {
            ErrorStateView(message: error) {
                viewModel.refresh()
            }
            .transition(.opacity)
        } else if let weather = viewModel.weather {
            WeatherContentView(weather: weather, history: viewModel.history)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else {
            PlaceholderStateView()
                .transition(.opacity)
        }
    }
    
    private func buttonTitleForAuthorizationState(_ state: LocationService.AuthorizationState) -> String {
        switch state {
        case .allowed: return "Обновить"
        case .denied: return "Разрешите доступ"
        case .notDetermined: return "Запросить"
        }
    }
}

struct WeatherContentView: View {
    let weather: WeatherBundle
    let history: [WeatherHistoryEntry]
    
    var body: some View {
        VStack(spacing: 24) {
            CurrentWeatherCard(weather: weather.current, fetchedAt: weather.fetchedAt)
            HourlyForecastView(hourly: weather.hourly)
            DailyForecastView(daily: weather.daily)
            if history.isEmpty == false {
                HistoryTimelineView(history: history)
            }
        }
    }
}

struct WeatherDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherDashboardView()
            .preferredColorScheme(.dark)
    }
}
