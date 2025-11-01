//
//  WeatherDashboardViewModel.swift
//  weather_app
//
//  Created by Valeriy Nikitin on 2023-10-08.
//

import Foundation
import Combine
import CoreLocation

@MainActor
final class WeatherDashboardViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var weather: WeatherBundle?
    @Published var history: [WeatherHistoryEntry] = []
    @Published var authorizationState: LocationService.AuthorizationState = .notDetermined
    
    private let repository: WeatherRepositoryProtocol
    private let historyStore: WeatherHistoryStoreProtocol
    private let locationService: LocationService
    private var cancellables = Set<AnyCancellable>()
    private var pendingLocationRequest = false
    
    init(
        repository: WeatherRepositoryProtocol = WeatherRepository(),
        historyStore: WeatherHistoryStoreProtocol = WeatherHistoryStore(),
        locationService: LocationService = LocationService()
    ) {
        self.repository = repository
        self.historyStore = historyStore
        self.locationService = locationService
        bindLocation()
    }
    
    func onAppear() {
        loadHistory()
        authorizationState = locationService.state
    }
    
    func search() {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        Task {
            await loadWeather(for: trimmed, recordHistory: true)
        }
    }
    
    func useCurrentLocation() {
        pendingLocationRequest = true
        locationService.requestAuthorization()
    }
    
    func refresh() {
        guard let weather else { return }
        Task {
            await loadWeather(for: weather.location.coordinate, recordHistory: false)
        }
    }
    
    private func bindLocation() {
        locationService.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                authorizationState = state
            }
            .store(in: &cancellables)
        
        locationService.$lastKnownLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coordinate in
                guard let self else { return }
                if pendingLocationRequest {
                    pendingLocationRequest = false
                    Task {
                        await self.loadWeather(for: coordinate, recordHistory: true)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadHistory() {
        do {
            history = try historyStore.load().sorted { $0.date > $1.date }
        } catch {
            print("History load error: \(error.localizedDescription)")
        }
    }
    
    private func persistHistory() {
        do {
            try historyStore.save(history)
        } catch {
            print("History save error: \(error.localizedDescription)")
        }
    }
    
    private func recordHistory(from bundle: WeatherBundle) {
        let entry = WeatherHistoryEntry(
            date: bundle.fetchedAt,
            city: bundle.location.displayName,
            temperature: bundle.current.temperature,
            condition: bundle.current.condition
        )
        history.removeAll { $0.city == entry.city }
        history.insert(entry, at: 0)
        history = Array(history.prefix(12))
        persistHistory()
    }
    
    private func loadWeather(for coordinate: CLLocationCoordinate2D, recordHistory: Bool) async {
        await load {
            try await repository.weather(for: coordinate)
        } postProcess: { bundle in
            if recordHistory {
                recordHistory(from: bundle)
            }
        }
    }
    
    private func loadWeather(for query: String, recordHistory: Bool) async {
        await load {
            try await repository.weather(for: query)
        } postProcess: { bundle in
            if recordHistory {
                recordHistory(from: bundle)
            }
        }
    }
    
    private func load(
        _ action: () async throws -> WeatherBundle,
        postProcess: (WeatherBundle) -> Void
    ) async {
        isLoading = true
        errorMessage = nil
        do {
            let bundle = try await action()
            weather = bundle
            postProcess(bundle)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
