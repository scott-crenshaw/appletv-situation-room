import Foundation

/// Minimal RSS/Atom parser for headline extraction.
/// Parses <item>/<entry> elements for title, link, pubDate.
/// Deliberately simple — no external dependencies.
class SimpleRSSParser: NSObject, XMLParserDelegate {
    private var items: [NewsItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var insideItem = false

    private let source: String
    private let category: NewsItem.NewsCategory

    private static let dateFormatters: [DateFormatter] = {
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",     // RFC 822
            "EEE, dd MMM yyyy HH:mm:ss zzz",
            "yyyy-MM-dd'T'HH:mm:ssZ",           // ISO 8601
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
        ]
        return formats.map { format in
            let df = DateFormatter()
            df.dateFormat = format
            df.locale = Locale(identifier: "en_US_POSIX")
            return df
        }
    }()

    private init(source: String, category: NewsItem.NewsCategory) {
        self.source = source
        self.category = category
    }

    static func parse(data: Data, source: String, category: NewsItem.NewsCategory) -> [NewsItem] {
        let parser = SimpleRSSParser(source: source, category: category)
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()
        return parser.items
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        currentElement = elementName

        if elementName == "item" || elementName == "entry" {
            insideItem = true
            currentTitle = ""
            currentLink = ""
            currentPubDate = ""
        }

        // Atom feeds use <link href="..."/>
        if insideItem && elementName == "link", let href = attributes["href"] {
            currentLink = href
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        switch currentElement {
        case "title": currentTitle += string
        case "link": currentLink += string
        case "pubDate", "published", "updated": currentPubDate += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "item" || elementName == "entry" {
            let title = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else {
                insideItem = false
                return
            }

            let pubDateStr = currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines)
            let date = Self.dateFormatters.lazy.compactMap { $0.date(from: pubDateStr) }.first

            items.append(NewsItem(
                title: title,
                source: source,
                publishedAt: date,
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category
            ))
            insideItem = false
        }
    }
}
