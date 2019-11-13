import NIOHTTP1

extension HTTPHeaders: ExpressibleByDictionaryLiteral {
    /// See `ExpressibleByDictionaryLiteral`
    public init(dictionaryLiteral elements: (String, String)...) {
        var headers = HTTPHeaders()
        for (key, val) in elements {
            headers.add(name: key, value: val)
        }
        self = headers
    }
}
