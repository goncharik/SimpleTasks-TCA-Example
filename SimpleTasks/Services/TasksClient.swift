import Combine
import ComposableArchitecture
import Foundation
import KeychainAccess

// MARK: - API models

struct AuthToken: Decodable, Equatable {
    let token: String
}

enum TaskPriority: String, CaseIterable, Hashable, Codable {
    case low = "Low"
    case medium = "Normal"
    case high = "High"
}

struct Task: Decodable, Equatable, Identifiable {
    var id: Int
    var title: String
    var dueBy: TimeInterval?
    var priority: TaskPriority

    init(id: Int, title: String, dueBy: TimeInterval?, priority: TaskPriority) {
        self.id = id
        self.title = title
        self.dueBy = dueBy
        self.priority = priority
    }
}

struct ListMeta: Decodable, Equatable {
    let current: Int
    let limit: Int
    let count: Int
}

struct TasksResponse: Decodable, Equatable {
    let tasks: IdentifiedArrayOf<Task>
    let meta: ListMeta
}

struct TaskResponse: Decodable, Equatable {
    let task: Task
}

struct TaskRequest: Encodable {
    var title: String
    var dueBy: Int?
    var priority: TaskPriority
}

// MARK: - API client interface

struct TasksClient {
    var login: (String, String) -> Effect<AuthToken, Failure>
    var register: (String, String) -> Effect<AuthToken, Failure>

    var tasks: (Int) -> Effect<TasksResponse, Failure>
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
                .mapDefaultError()
                .eraseToEffect()
        },
        register: { (email, password) -> Effect<AuthToken, Failure> in
            var request = URLRequest.jsonRequest(
                url: URL(string: baseUrl + "/users")!,
                method: .post,
                body: ["email": email, "password": password]
            )

            return URLSession.shared.dataTaskPublisher(for: request)
                .mapToDataWithFailure()
                .decode(type: AuthToken.self, decoder: JSONDecoder())
                .mapDefaultError()
                .eraseToEffect()
        },

        tasks: { (pageNumber) -> Effect<TasksResponse, Failure> in
            let token = Keychain.live.token
            var request = URLRequest.jsonRequest(
                url: URL(string: baseUrl + "/tasks?page=\(pageNumber)")!,
                method: .get,
                token: token
            )

            return URLSession.shared.dataTaskPublisher(for: request)
                .mapToDataWithFailure()
                .decode(type: TasksResponse.self, decoder: JSONDecoder())
                .mapDefaultError()
                .eraseToEffect()
        },
        createTask: { (taskRequest) -> Effect<Task, Failure> in
            let token = Keychain.live.token
            var request = URLRequest.jsonRequest(
                url: URL(string: baseUrl + "/tasks")!,
                method: .post,
                body: taskRequest,
                token: token
            )

            return URLSession.shared.dataTaskPublisher(for: request)
                .mapToDataWithFailure()
                .decode(type: TaskResponse.self, decoder: JSONDecoder())
                .map(\.task)
                .print()
                .mapDefaultError()
                .eraseToEffect()
        },
        updateTask: { (id, taskRequest) -> Effect<Task, Failure> in
            let token = Keychain.live.token
            var request = URLRequest.jsonRequest(
                url: URL(string: baseUrl + "/tasks/\(id)")!,
                method: .put,
                body: taskRequest,
                token: token
            )

            return URLSession.shared.dataTaskPublisher(for: request)
                .mapToDataWithFailure()
                .decode(type: TaskResponse.self, decoder: JSONDecoder())
                .map(\.task)
                .mapDefaultError()
                .eraseToEffect()
        },
        deleteTask: { (id) -> Effect<Void, Failure> in
            let token = Keychain.live.token
            var request = URLRequest.jsonRequest(
                url: URL(string: baseUrl + "/tasks/\(id)")!,
                method: .delete,
                token: token
            )

            return URLSession.shared.dataTaskPublisher(for: request)
                .mapToDataWithFailure()
                .map { _ in () }
                .mapDefaultError()
                .eraseToEffect()
        }
    )

    static var mock: TasksClient {
        TasksClient { _,_ in
            fatalError("Unmocked")
        } register: { _,_ in
            fatalError("Unmocked")
        } tasks: { _ in
            fatalError("Unmocked")
        } createTask: { _ in
            fatalError("Unmocked")
        } updateTask: { _,_ in
            fatalError("Unmocked")
        } deleteTask: { _ in
            fatalError("Unmocked")
        }
    }
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

extension Publisher {
    func mapDefaultError() -> Publishers.MapError<Self, TasksClient.Failure> {
        mapError { error in
            if let error = error as? TasksClient.Failure {
                return error
            }
            return TasksClient.Failure(message: error.localizedDescription)
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
    static func jsonRequest(url: URL, method: URLMethod, token: String? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    static func jsonRequest<Body: Encodable>(url: URL, method: URLMethod, body: Body, token: String? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
