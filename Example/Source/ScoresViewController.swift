import UIKit
import ReactiveRepo
import Combine

final class ScoresViewController: UIViewController {

    var repository: AnyRepository<ScoresResponse, Score>!
    private var cancellable: AnyCancellable?
    var scores: [Score] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Create a `Source` for your data. In this case we will use ReactiveRepo's `HTTPSource`.
        let url = URL(string: "http://www.mocky.io/v2")!
        let source = HTTPSource(baseURL: url)

        // 2. Initialize the repository.
        // Here you will need to declare your response and entity types.
        // For this example we are using `ScoresResponse` and `Score` in your implementation these might be different.
        repository = InMemoryRepository(source: source).eraseToAnyRepository()
    }

    private func fetch() {
        cancellable = repository.get().assertNoFailure().handleEvents(receiveOutput: { scores in
            print("Assigned \(scores.count) scores to variable")
        }).assign(to: \.scores, on: self)
    }

    private func sync() {
        cancellable = repository.sync(from: Endpoints.scores.path).sink(receiveCompletion: { result in
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
        cancellable = repository.get().flatMap { scores in
            Publishers.Sequence(sequence: scores.map {
                self.repository.delete(item: $0)
            }).flatMap { $0 }.collect()
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

    @IBAction func performFetch(_ sender: UIButton) {
        fetch()
    }

    @IBAction func performSync(_ button: UIButton) {
        sync()
    }

    @IBAction func performDelete(_ button: UIButton) {
        delete()
    }
}
