import SwiftUI

class PaginationController<T>: ObservableObject {
    @Published var items: [T] = [] {
        didSet { updatePagedItems() }
    }

    @Published var pagedItems: [T] = []
    @Published var currentPage: Int = 0 {
        didSet { updatePagedItems() }
    }

    let itemsPerPage: Int

    init(itemsPerPage: Int) {
        self.itemsPerPage = itemsPerPage
    }

    var totalPages: Int {
        max(1, (items.count + itemsPerPage - 1) / itemsPerPage)
    }

    var visiblePageRange: [Int] {
        var pages: [Int] = []

        if totalPages <= 7 {
            pages = Array(0..<totalPages)
        } else {
            pages.append(0)
            if currentPage > 3 { pages.append(-1) }

            let start = max(1, currentPage - 1)
            let end = min(totalPages - 2, currentPage + 1)
            pages.append(contentsOf: start...end)

            if currentPage < totalPages - 4 { pages.append(-1) }

            pages.append(totalPages - 1)
        }

        return pages
    }

    func goToPage(_ page: Int) {
        let clampedPage = min(max(0, page), totalPages - 1)
        if clampedPage != currentPage {
            currentPage = clampedPage
        } else {
            updatePagedItems()
        }
    }

    private func updatePagedItems() {
        let start = currentPage * itemsPerPage
        let end = min(start + itemsPerPage, items.count)
        if start < end {
            pagedItems = Array(items[start..<end])
        } else {
            pagedItems = []
        }
    }
}
