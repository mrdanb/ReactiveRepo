import Foundation
import Combine

extension RepositoryError {
    public enum HTTP: Error {
        case invalidURL
        case invalidParameters
    }
}

public final class HTTPSource: Source {

    private let session: URLSession
    private let baseUrl: URL

    public init(baseURL: URL, session: URLSession = URLSession.shared) {
        self.baseUrl = baseURL
        self.session = session
    }

    public func data(for key: String, parameters: [String : String]?) -> AnyPublisher<Data, Error> {
        let fullUrl = baseUrl.appendingPathComponent(key)

        guard var urlComponents = URLComponents(url: fullUrl, resolvingAgainstBaseURL: false) else {
            return Fail(outputType: Data.self, failure: RepositoryError.HTTP.invalidURL)
                .eraseToAnyPublisher()
        }
        urlComponents.queryItems = parameters?.map{ URLQueryItem(name: $0, value: $1) }

        guard let url = urlComponents.url else {
            return Fail(outputType: Data.self, failure: RepositoryError.HTTP.invalidParameters)
                .eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: url)
            .mapError { $0 }
            .map { $0.data }
            .eraseToAnyPublisher()
    }
}
