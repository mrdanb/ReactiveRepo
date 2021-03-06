import UIKit
import Combine
import ReactiveRepo
import CoreData

final class UsersViewController: UIViewController {

    var repository: AnyRepository<UserResponse, User>!
    private var cancellable: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Setup your CoreData stack as usual.
        let context = Dependencies.shared.persistentContainer.viewContext
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        // 2. Create a `Source` for your data. In this case we will use ReactiveRepo's `HTTPSource`.
        let url = URL(string: "http://www.mocky.io/v2")!
        let source = HTTPSource(baseURL: url)

        // 3. Initialize the repository.
        // Here you will need to declare your response and entity types.
        // For this example we are using `UserResponse` and `User` in your implementation these might be different.
        //
        // As well as the response and entity types you will need to provide a `NSPersistentContainer`
        // and the `HTTPSource` we created earlier.
        repository = CoreDataRepository<UserResponse, User>(persistentContainer: Dependencies.shared.persistentContainer,
                                                            source: source).eraseToAnyRepository()
    }

    private func fetch() {
        cancellable = repository.get().sink(receiveCompletion: { result in
            switch result {
            case .failure(let error):
                print("Failed to fetch: \(error.localizedDescription)")
            case .finished:
                print("Finished fetch")
            }
        }, receiveValue: { users in
            print(users)
        })
    }

    private func sync() {
        cancellable = repository.sync(from: Endpoints.user.path).sink(receiveCompletion: { result in
            switch result {
            case .failure(let error):
                print("Failed to sync: \(error.localizedDescription)")
            case .finished:
                print("Finished sync")
            }
        }, receiveValue: { changes in
            print(changes)
        })
    }

    private func delete() {
        cancellable =
            repository.get()
            .compactMap { $0.first }
            .flatMap { user -> AnyPublisher<User, Error> in
                return self.repository.delete(item: user)
            }.sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    print("Failed to delete: \(error.localizedDescription)")
                case .finished:
                    print("Finish delete")
                }
            }, receiveValue: { deleted in
                print(deleted)
            })
    }

    @IBAction func performSync(_ sender: UIButton) {
        sync()
    }

    @IBAction func performFetch(_ sender: UIButton) {
        fetch()
    }

    @IBAction func performDelete(_ sender: UIButton) {
        delete()
    }
}

