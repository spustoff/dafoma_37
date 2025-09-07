//
//  NetworkManager.swift
//  TaskOrbit Ano
//
//  Created by Assistant on 9/6/25.
//

import Foundation
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isConnected = true
    @Published var isLoading = false
    
    private init() {
        startNetworkMonitoring()
    }
    
    // MARK: - Network Monitoring
    private func startNetworkMonitoring() {
        // For now, we'll assume we're always connected
        // In a real app, you would use Network framework to monitor connectivity
        isConnected = true
    }
    
    // MARK: - Generic Network Request
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String] = [:],
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        
        guard let url = URL(string: endpoint) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Add default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add custom headers
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if error is DecodingError {
                    return NetworkError.decodingError
                } else {
                    return NetworkError.requestFailed
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Specific API Methods (Placeholder for future use)
    func syncTasks() -> AnyPublisher<[Task], NetworkError> {
        // Placeholder for syncing tasks with backend
        return Just(Task.sampleTasks)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }
    
    func syncProjects() -> AnyPublisher<[Project], NetworkError> {
        // Placeholder for syncing projects with backend
        return Just(Project.sampleProjects)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }
    
    func syncUsers() -> AnyPublisher<[User], NetworkError> {
        // Placeholder for syncing users with backend
        return Just(User.sampleUsers)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Upload/Download Methods
    func uploadImage(_ imageData: Data, to endpoint: String) -> AnyPublisher<String, NetworkError> {
        // Placeholder for image upload functionality
        return Just("https://example.com/uploaded-image.jpg")
            .setFailureType(to: NetworkError.self)
            .delay(for: .seconds(2), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func downloadFile(from url: String) -> AnyPublisher<Data, NetworkError> {
        guard let fileURL = URL(string: url) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: fileURL)
            .map(\.data)
            .mapError { _ in NetworkError.requestFailed }
            .eraseToAnyPublisher()
    }
}

// MARK: - HTTP Methods
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case requestFailed
    case unauthorized
    case serverError
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .requestFailed:
            return "Request failed"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError:
            return "Server error"
        case .networkUnavailable:
            return "Network unavailable"
        }
    }
}

// MARK: - Network Configuration
struct NetworkConfiguration {
    static let baseURL = "https://api.taskorbit.com/v1"
    static let timeout: TimeInterval = 30.0
    static let maxRetries = 3
    
    // API Endpoints
    struct Endpoints {
        static let tasks = "/tasks"
        static let projects = "/projects"
        static let users = "/users"
        static let analytics = "/analytics"
        static let upload = "/upload"
        static let auth = "/auth"
    }
}
