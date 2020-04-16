import Foundation
import ReactiveRepo

struct Score: Equatable, Decodable {
    let points: Int
    let correctAnswers: Int
    let incorrectAnswers: Int
}
