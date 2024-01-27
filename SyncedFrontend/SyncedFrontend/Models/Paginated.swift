struct Paginated<T: Codable>: Codable {
    var items: [T]
    var total: Int?
    var limit: Int?
    var page: Int?
    var next: String?
    var previous: String?
}
