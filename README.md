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

// 2. Initialize the repository.
// Here you will need to declare your entity type.
// For this example we are using `User` in your implementation this might be different.
//
// As well as the entity types you will need to provide a `NSPersistentContainer` or `NSManagedObjectContext`.
repository = CoreDataRepository<User>(persistentContainer: Dependencies.shared.persistentContainer).eraseToAnyRepository()
```

### 📱 In-memory
```swift
// In order to setup an in-memory repository you need to a `Creator`.
//
// A creator is a closure that returns a new instances of the `Entity` associated with this `Repository`.
let repository = InMemoryRepository<Score>(creator: { Score() })
```

## ⬇️ Fetching
Performing a fetch will return all objects in the repository.
You can also pass in a predicate to query the repository for a subset of your entities.  

```swift
let repository: AnyRepository<User> = …

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
let repository: AnyRepository<User> = …

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

Where Combine really shines is when using operations in combination. The same is true for `ReactiveRepo`.

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
This struct holds entities that have been inserted, deleted or updated.

You can access these by using the three collections accessors: `changes.inserted`, `changes.deleted` and  `changes.updated`

Or by using the helper method `changes(for type:)`:
```swift
let inserted = changes.changes(for: .inserted)
```
