#  ReactiveRepo ↔️

### The repository pattern library for Swift Combine
Here to assist your Swift development by syncing, fetching, inserting, and deleting your entity objects.

- [Installation](#installation)
- [Setup](#setup)
- [Fetching](#fetching)
- [Syncing](#syncing)
- [Deleting](#deleting)
- [Changes](#changes)

## Installation

### Swift Package Manager

Install via [Swift Package Manager](https://swift.org/package-manager/).

Use ReactiveRepo as a dependency by adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/mrdanb/ReactiveRepo.git", .upToNextMajor(from: "1.0.0"))
]
```

## Setup

### 🗃 CoreData
```swift
// 1. Setup your CoreData stack as usual.
let context = Dependencies.shared.persistentContainer.viewContext
context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

// 2. Create a `Source` for your data. In this case we will use ReactiveRepo's `HTTPSource`.
let url = URL(string: "http://www.mocky.io/v2/")!
let source = HTTPSource(baseURL: url)

// 3. Initialize the repository.
// Here you will need to declare your response and entity types.
// For this example we are using `Response` and `User` in your implementation these might be different.
//
// As well as the response and entity types you will need to provide a `NSPersistentContainer`
// and the `HTTPSource` we created above.
repository = CoreDataRepository<Response, User>(persistentContainer: Dependencies.shared.persistentContainer,
                                                source: source).eraseToAnyRepository()
```

### 📱 In-memory
```swift
// 1. In order to setup an in-memory repository you only  need to provide a `Source`.
// This can be any implementation of `Source`. We could use the `HTTPSource` as in the example above.
// Or, as in this example below, you can extend `UserDefaults` to implement ReactiveRepo's `Source` protocol.
// This allows us to pass use `UserDefaults` with the in-memory repository.

let repository = InMemoryRepository<Response, Score>(source: UserDefaults.standard)

extension UserDefaults: Source {
    public func data(for key: String, parameters: [String : String]? = nil) -> AnyPublisher<Data, Error> {
        guard let data = self.data(forKey: key) else {
            return Fail(error: RepositoryError.objectNotFound).eraseToAnyPublisher()
        }
        return Just(data)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
```

## 🔄 Syncing
Syncing allows you to update your repository with data from a given source. 
When you ask the Repository to `sync` it does the following:
* Queries the source you provided to return some `Data` for a given key
* Decodes that data in to your  `Response` type
* Serializes the response to your  `Entity` type
* Stores the results

The resulting type from a `sync` is  a `Changes` object. The `Changes` type lists everything that  has been inserted, updated or deleted during the sync. See [Changes](#Changes)

```swift
let repository: AnyRepository<Response, User> = …

cancellable = repository.sync(from: "/example-endpoint").sink(receiveCompletion: { result in
    switch result {
    case .failure(let error):
        print("Failed to sync: \(error.localizedDescription)")
    case .finished:
        print("Finished sync")
    }
}, receiveValue: { changes in
    print(changes)
})
```

### Serializing
When setting up your repository, the `Response` type you provide must be a `Serializable` type. This means the repository can serialize the response in to the `Entity` your repository is handling.
If your `Response` and `Entity` type are the same (i.e. you wish to store the response) you can use the default implementation. You can do this by simply adding the `Serializable` protocol to your type 
```swift
extension UserResponse: Serializable { }
```

Otherwise it is up to you to provide an implementation that generates the entites you are storing. 

For example, if you are using the `CoreDataRepository`  your implementation will need to generate the managed objects. An example might look as follows:
```swift
extension UserResponse: Serializing {
    func serialize(context: NSManagedObjectContext) -> [User] {
        let user = User(context: context, response: self)
        return [user]
    }
}
```
Once the entites have been created return an array of the newly created objects. 

## ⬇️ Fetching
Performing a fetch will return all objects in the repository.
You can also pass in a predicate to query the repository for a subset of your entities.  

```swift
let repository: AnyRepository<Response, User> = …

// Fetch all users
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

// Fetch premium users
cancellable = repository.get(predicate: NSPredicate(format: "isPremium = true)).sink(receiveCompletion: { result in
    switch result {
    case .failure(let error):
        print("Failed to fetch: \(error.localizedDescription)")
    case .finished:
        print("Finished fetch")
    }
}, receiveValue: { premiumUsers in
    print(premiumUsers)
})
```

## 🗑 Deleting
To delete an item you can calll the `delete(item:)` method and pass in the entity you would like to removed from the repository. 
```swift
let repository: AnyRepository<Response, User> = …

let item: User
cancellable = repository.delete(item: user).sink(receiveCompletion: { result in
    switch result {
    case .failure(let error):
        print("Failed to delete: \(error.localizedDescription)")
    case .finished:
        print("Finished delete")
    }
}, receiveValue: { deletedUser in
    print(deletedUser)
})
```

## Chaining 🔗
As `ReactiveRepo` is built on top of Swift Combine you get the powerful advantages that come with the Combine operators. 

Where Combine really shines is when using operations in combination. The same is true for  `ReactiveRepo`.

Here's an example of how you might chain some common repository operations:
```swift
// Delete user with name "Jim"
cancellable =
    repository.get(predicate: NSPredicate(format: "name = jim"))
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
    }, receiveValue: { jim in
        print(jim)
    })
```

## 🔀 Changes
When performing a sync the result success type will be a `Changes` object.
```swift
struct Changes<Entity>
```
This struct holds  entities that have been inserted, deleted or updated.

You can access these by using the three collections accessors: `changes.inserted`, `changes.deleted` and  `changes.updated`

Or by using the helper method `changes(for type:)`:
```swift
let inserted = changes.changes(for: .inserted)
```
