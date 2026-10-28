import Foundation

/// The only seam between the board fold and disk. Memory stays authoritative.
actor CouponStore {
    static let rootKey = "chw.root.v1"
    static let debounce: Duration = .milliseconds(300)

    private let defaults: UserDefaults
    private let directory: URL
    private let fileURL: URL
    private let backupURL: URL
    private var pending: CouponRoot?
    private var saveTask: Task<Void, Never>?

    init(suiteName: String, directory: URL) {
        let defaults = UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
        self.defaults = defaults
        self.directory = directory
        self.fileURL = directory.appendingPathComponent("coupon-root.json")
        self.backupURL = directory.appendingPathComponent("coupon-root.json.backup")
    }

    func load() -> LoadedCoupon {
        if let root = decodeFile(at: fileURL) {
            return LoadedCoupon(root: root, notice: nil)
        }
        if let root = decodeFile(at: backupURL) {
            return LoadedCoupon(
                root: root,
                notice: "The saved week was unreadable. The last good copy is back."
            )
        }
        if let data = defaults.data(forKey: Self.rootKey), let root = decode(data) {
            return LoadedCoupon(root: root, notice: nil)
        }
        return LoadedCoupon(
            root: CouponRoot(board: Board(), onboardingComplete: false),
            notice: nil
        )
    }

    /// Simulator only, and only until `chw.demo.v1` is set.
    func loadSeededIfNeeded(now: Date) -> LoadedCoupon {
        #if targetEnvironment(simulator)
        if defaults.object(forKey: DemoSeed.defaultsKey) == nil {
            let seeded = DemoSeed.root(now: now)
            defaults.set(true, forKey: DemoSeed.defaultsKey)
            do {
                try writeNow(seeded)
            } catch {
                return LoadedCoupon(
                    root: seeded,
                    notice: "The opening week is on screen. Saving it failed."
                )
            }
            return LoadedCoupon(root: seeded, notice: nil)
        }
        #endif
        return load()
    }

    func scheduleSave(_ root: CouponRoot) {
        pending = root
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: Self.debounce)
            if Task.isCancelled {
                return
            }
            self.flushPending()
        }
    }

    func flush() {
        saveTask?.cancel()
        saveTask = nil
        flushPending()
    }

    func resetAllData() {
        saveTask?.cancel()
        saveTask = nil
        pending = nil
        defaults.removeObject(forKey: Self.rootKey)
        defaults.removeObject(forKey: DemoSeed.defaultsKey)
        let manager = FileManager.default
        for url in [fileURL, backupURL] {
            if manager.fileExists(atPath: url.path) {
                do {
                    try manager.removeItem(at: url)
                } catch {
                    // A leftover file is overwritten on the next save. Reset still clears memory.
                }
            }
        }
    }

    private func flushPending() {
        guard let root = pending else {
            return
        }
        do {
            try writeNow(root)
            pending = nil
        } catch {
            return
        }
    }

    private func writeNow(_ root: CouponRoot) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(root)
        let manager = FileManager.default
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        if manager.fileExists(atPath: fileURL.path) {
            if manager.fileExists(atPath: backupURL.path) {
                try manager.removeItem(at: backupURL)
            }
            try manager.copyItem(at: fileURL, to: backupURL)
        }
        try data.write(to: fileURL, options: .atomic)
        defaults.set(data, forKey: Self.rootKey)
    }

    private func decodeFile(at url: URL) -> CouponRoot? {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            return nil
        }
        return decode(data)
    }

    private func decode(_ data: Data) -> CouponRoot? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(CouponRoot.self, from: data)
        } catch {
            return nil
        }
    }
}

struct LoadedCoupon: Equatable, Sendable {
    var root: CouponRoot
    var notice: String?
}
