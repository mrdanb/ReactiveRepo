import ReactiveRepo

struct ScoresResponse: Decodable {
    let scores: [Score]
}

extension ScoresResponse: Serializing {
    func serialize(context: Any?) -> [Score] {
        return scores
    }
}
