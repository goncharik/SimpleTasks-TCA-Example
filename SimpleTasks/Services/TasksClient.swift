import Combine
import ComposableArchitecture
import Foundation

// MARK: - API models

struct AuthToken: Decodable, Equatable {
    let token: String
}

enum TaskPriority: String, Codable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"
}

struct Task: Decodable, Equatable, Identifiable {
    var id: Int
    var title: String
    var dueBy: TimeInterval
    var priority: TaskPriority
}

struct TaskRequest: Encodable {
    var title: String
    var dueBy: TimeInterval
    var priority: TaskPriority
}

// MARK: - API client interface

struct TasksClient {
    var login: (String, String) -> Effect<AuthToken, Failure>
    var register: (String, String) -> Effect<AuthToken, Failure>

    var tasks: (Int) -> Effect<[Task], Failure>
    var createTask: (TaskRequest) -> Effect<Task, Failure>
    var updateTask: (Int, TaskRequest) -> Effect<Task, Failure>
    var deleteTask: (Int) -> Effect<Void, Failure>

    struct Failure: Decodable, Error, Equatable {
        let message: String
    }
}

// MARK: - API client interface

extension TasksClient {
    private static var baseUrl = "https://testapi.doitserver.in.ua/api"

    static var live = TasksClient(
        login: { (email, password) -> Effect<AuthToken, Failure> in
            var request = URLRequest.jsonRequest(
                url: URL(string: baseUrl + "/auth")!,
                method: .post,
                body: ["email": email, "password": password]
            )

            return URLSession.shared.dataTaskPublisher(for: request)
                .mapToDataWithFailure()
                .decode(type: AuthToken.self, decoder: JSONDecoder())
                .mapError { error in
                    if let error = error as? Failure {
                        return error
                    }
                    return Failure(message: "Unknown error")
                }
                .eraseToEffect()
        },
        register: { (email, password) -> Effect<AuthToken, Failure> in
            fatalError()
        },
        tasks: { (pageNumber) -> Effect<[Task], Failure> in
            fatalError()
        },
        createTask: { (taskRequest) -> Effect<Task, Failure> in
            fatalError()
        },
        updateTask: { (id, taskRequest) -> Effect<Task, Failure> in
            fatalError()
        },
        deleteTask: { (id) -> Effect<Void, Failure> in
            fatalError()
        }
    )
}

// MARK: - Helpers

extension URLSession.DataTaskPublisher {
    func mapToDataWithFailure() -> Publishers.TryMap<URLSession.DataTaskPublisher, Data> {
        return tryMap { data, response in
            if let response = response as? HTTPURLResponse,
                        !(200...299).contains(response.statusCode) {
                throw try JSONDecoder().decode(TasksClient.Failure.self, from: data)
            }
            return data
        }
    }
}

enum URLMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

extension URLRequest {
    static func jsonRequest<Body: Encodable>(url: URL, method: URLMethod, body: Body) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        return request
    }
}
