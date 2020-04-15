import UIKit
import Combine
import ReactiveRepo
import CoreData

class ViewController: UIViewController {

    private let identifier = "5e96e3cf3000007800b6d8f0"

    var repository: CoreDataRepository<UserResponse, User>?
    private var cancellable: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Setup your CoreData stack as usual.
        let context = Dependencies.shared.persistentContainer.viewContext
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        // 2. Create a `Source` for your data. In this case we will use Croupier's `HTTPSource`.
        let url = URL(string: "http://www.mocky.io/v2/")!
        let source = HTTPSource(baseURL: url)

        // 3. Initialize the repository.
        // Here you will need to declare your response and entity types.
        // For this example we are using `UserResponse` and `User` in your implementation these might be different.
        //
        // As well as the response and entity types you will need to provide a `ContextProvider`.
        // This is a very simple protocol that is capable of providing a `mainContext` as well as
        // creating a new background context. Here we are simply providing the persistentContainer as we have
        // extended `NSPersistentContainer` to act as a `ContextProvider` (see below).
        repository = CoreDataRepository<UserResponse, User>(persistentContainer: Dependencies.shared.persistentContainer, source: source)

        fetch()
    }

    private func fetch() {
        cancellable = repository?.get(predicate: nil).sink(receiveCompletion: { result in
            //
        }, receiveValue: { users in
            if let user = users.first {
                print(user.identifier)
                print(user.name)
                print(user.age)
            }
        })
    }

    private func sync() {
        cancellable = repository?.sync(from: identifier).sink(receiveCompletion: { result in
            switch result {
            case .failure(let error):
                print("Failed to sync: \(error.localizedDescription)")
            case .finished:
                print("Synced successfully")
            }
        }, receiveValue: { changes in
            print(changes)
        })
    }

    @IBAction func performSync(_ sender: UIButton) {
        sync()
    }
}

