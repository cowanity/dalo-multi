import SwiftUI
import AppKit
import Foundation
import Combine

extension Notification.Name {
    static let daloFocusSearch = Notification.Name("app.dalo.multi.focusSearch")
    static let daloOpenCommandPalette = Notification.Name("app.dalo.multi.commandPalette")
    static let daloOpenCloneWizard = Notification.Name("app.dalo.multi.cloneWizard")
}

struct ZaloAccount: Identifiable, Hashable {
    let id: Int
    var name: String
    var isRunning: Bool
    var iconVariant: String
    var pid: Int
    var rssKB: Int
    var elapsed: String
    var version: String
    var sourceVersion: String
    var needsUpdate: Bool
    var startupEnabled: Bool
    var isDocked: Bool
    var note: String
    var isFavorite: Bool
}

struct OriginalStatus: Hashable {
    var isRunning = false
    var pid = 0
    var rssKB = 0
    var elapsed = "-"
    var version = "?"
    var startupEnabled = false
}

struct HealthItem: Identifiable, Hashable {
    let id: Int
    var name: String
    var state: String
    var message: String
}

struct LaunchGroup: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var includeOriginal: Bool
    var cloneIDs: [Int]
    var preferredLayout: String?

    init(id: UUID = UUID(), name: String, includeOriginal: Bool = false, cloneIDs: [Int] = [], preferredLayout: String? = nil) {
        self.id = id
        self.name = name
        self.includeOriginal = includeOriginal
        self.cloneIDs = cloneIDs
        self.preferredLayout = preferredLayout
    }
}

struct ActivityEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var date = Date()
    var title: String
    var detail: String
    var kind: String
}

struct ClonePreferenceBackup: Codable {
    var id: Int
    var name: String
    var note: String
    var isFavorite: Bool
    var iconVariant: String
    var startupEnabled: Bool
    var isDocked: Bool
}

struct DaloConfigurationBackup: Codable {
    var formatVersion: Int = 1
    var appVersion: String = "1.3.0"
    var exportedAt = Date()
    var clones: [ClonePreferenceBackup]
    var groups: [LaunchGroup]
    var manualOrder: [Int]
    var settings: [String: String]
}

enum DashboardDisplayMode: String, CaseIterable, Identifiable {
    case cards
    case compact

    var id: String { rawValue }
    var label: String { self == .cards ? "Thẻ" : "Gọn" }
    var icon: String { self == .cards ? "square.grid.2x2" : "list.bullet" }
}

enum WindowLayoutMode: String, CaseIterable, Identifiable {
    case split
    case grid
    case cascade

    var id: String { rawValue }
    var label: String {
        switch self {
        case .split: return "Chia đều"
        case .grid: return "Lưới"
        case .cascade: return "Xếp tầng"
        }
    }
    var icon: String {
        switch self {
        case .split: return "rectangle.split.2x1"
        case .grid: return "square.grid.2x2"
        case .cascade: return "square.on.square"
        }
    }
}

enum SidebarPage: String, CaseIterable, Identifiable {
    case dashboard = "Tổng quan"
    case groups = "Không gian làm việc"
    case activity = "Hoạt động"
    case updates = "Cập nhật clone"
    case startup = "Khởi động"
    case health = "Sức khỏe"
    case diagnostics = "Chẩn đoán"
    case settings = "Cài đặt"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .groups: return "rectangle.3.group.fill"
        case .activity: return "waveform.path.ecg"
        case .updates: return "arrow.triangle.2.circlepath.circle.fill"
        case .startup: return "power"
        case .health: return "heart.text.square.fill"
        case .diagnostics: return "stethoscope"
        case .settings: return "gearshape.fill"
        }
    }
}

enum AccountSortMode: String, CaseIterable, Identifiable {
    case manual
    case favorites
    case name
    case id

    var id: String { rawValue }

    var label: String {
        switch self {
        case .manual: return "Thứ tự của tôi"
        case .favorites: return "Ưu tiên yêu thích"
        case .name: return "Tên A–Z"
        case .id: return "Clone ID"
        }
    }
}

struct DaloIconVariant: Identifiable, Hashable {
    let id: String
    let title: String
    let group: String

    static let all: [DaloIconVariant] = [
        .init(id:"blue", title:"Xanh dương", group:"Màu sắc cơ bản"),
        .init(id:"green", title:"Xanh lá", group:"Màu sắc cơ bản"),
        .init(id:"purple", title:"Tím", group:"Màu sắc cơ bản"),
        .init(id:"orange", title:"Cam", group:"Màu sắc cơ bản"),
        .init(id:"red", title:"Đỏ", group:"Màu sắc cơ bản"),
        .init(id:"gray", title:"Xám", group:"Màu sắc cơ bản"),
        .init(id:"doge", title:"Doge", group:"Meme"),
        .init(id:"doge_glasses", title:"Doge deal with it", group:"Meme"),
        .init(id:"cap", title:"Nón Dalo", group:"Meme"),
        .init(id:"cool_cat", title:"Mèo ngầu", group:"Meme"),
        .init(id:"pepe", title:"Pepe", group:"Meme"),
        .init(id:"crying", title:"Khóc", group:"Meme"),
        .init(id:"shiba", title:"Shiba vui", group:"Meme"),
        .init(id:"tet_blossom", title:"Tết hoa mai", group:"Sự kiện Việt Nam"),
        .init(id:"tet_lantern", title:"Tết đèn lồng", group:"Sự kiện Việt Nam"),
        .init(id:"banh_chung", title:"Bánh chưng", group:"Sự kiện Việt Nam"),
        .init(id:"national_day", title:"Quốc khánh", group:"Sự kiện Việt Nam"),
        .init(id:"non_la", title:"Nón lá", group:"Sự kiện Việt Nam"),
        .init(id:"lotus", title:"Hoa sen", group:"Sự kiện Việt Nam"),
        .init(id:"mid_autumn", title:"Trung thu", group:"Sự kiện Việt Nam"),
        .init(id:"fireworks", title:"Pháo hoa", group:"Sự kiện Việt Nam"),
        .init(id:"briefcase", title:"Cặp công việc", group:"Công việc & học tập"),
        .init(id:"laptop", title:"Laptop", group:"Công việc & học tập"),
        .init(id:"analytics", title:"Biểu đồ", group:"Công việc & học tập"),
        .init(id:"notebook", title:"Sổ tay", group:"Công việc & học tập"),
        .init(id:"idea", title:"Ý tưởng", group:"Công việc & học tập"),
        .init(id:"coffee", title:"Cà phê", group:"Công việc & học tập"),
        .init(id:"coding", title:"Lập trình", group:"Công việc & học tập"),
        .init(id:"graduation", title:"Tốt nghiệp", group:"Công việc & học tập"),
        .init(id:"controller", title:"Tay cầm", group:"Game & giải trí"),
        .init(id:"pacman", title:"Pacman", group:"Game & giải trí"),
        .init(id:"retro_handheld", title:"Máy game retro", group:"Game & giải trí"),
        .init(id:"pixel_heart", title:"Tim pixel", group:"Game & giải trí"),
        .init(id:"mushroom", title:"Nấm", group:"Game & giải trí"),
        .init(id:"star", title:"Ngôi sao", group:"Game & giải trí"),
        .init(id:"pokeball", title:"Pokeball", group:"Game & giải trí"),
        .init(id:"rocket", title:"Tên lửa", group:"Game & giải trí"),

    ]

    static func byID(_ id: String) -> DaloIconVariant {
        let aliases: [String: String] = [
            "meme_doge": "doge", "tet": "tet_blossom", "dong_son": "national_day",
            "business": "briefcase", "money": "analytics", "study": "graduation",
            "gaming": "controller", "galaxy": "rocket", "minimal_black": "gray",
            "cute": "shiba", "sleepy": "crying", "chill": "cool_cat",
            "dark_blue": "blue", "dark_green": "green", "dark_red": "red",
            "dark_purple": "purple", "dark_orange": "orange", "dark_gray": "gray",
            "pink": "red", "yellow": "orange", "teal": "green"
        ]
        let resolved = aliases[id] ?? id
        return all.first(where: { $0.id == resolved }) ?? all[0]
    }
}

struct ShellError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

enum ShellBridge {
    static func helperPath() throws -> String {
        guard let path = Bundle.main.path(forResource: "manager", ofType: "sh") else {
            throw ShellError(message: "Không tìm thấy manager.sh trong app.")
        }
        return path
    }

    static func run(_ args: [String]) async throws -> String {
        let helper = try helperPath()
        return try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let outPipe = Pipe()
            let errPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: helper)
            process.arguments = args
            process.standardOutput = outPipe
            process.standardError = errPipe

            do {
                try process.run()
            } catch {
                throw ShellError(message: "Không chạy được engine: \(error.localizedDescription)")
            }

            let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            let out = String(data: outData, encoding: .utf8) ?? ""
            let err = String(data: errData, encoding: .utf8) ?? ""

            if process.terminationStatus != 0 {
                let detail = [out, err]
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .joined(separator: "\n")
                throw ShellError(message: detail.isEmpty ? "Engine trả về lỗi \(process.terminationStatus)." : detail)
            }

            return out.trimmingCharacters(in: .whitespacesAndNewlines)
        }.value
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var accounts: [ZaloAccount] = []
    @Published var original = OriginalStatus()
    @Published var isBusy = false
    @Published var errorMessage: String?
    @Published var diagnostics = ""
    @Published var health: [HealthItem] = []
    @Published var lastRefresh = Date()
    @Published var lastExportPath = ""
    @Published var groups: [LaunchGroup] = []
    @Published var activity: [ActivityEntry] = []
    @Published var noticeMessage: String?

    private var autoRepairInProgress = false
    private var refreshInProgress = false
    private let defaults = UserDefaults.standard

    init() {
        loadGroups()
        loadActivity()
    }

    private func noteKey(_ id: Int) -> String { "account.note.\(id)" }
    private func favoriteKey(_ id: Int) -> String { "account.favorite.\(id)" }

    var originalRunning: Bool { original.isRunning }

    func refresh(showError: Bool = false) async {
        guard !isBusy, !refreshInProgress else { return }
        refreshInProgress = true
        defer { refreshInProgress = false }

        do {
            async let originalText = ShellBridge.run(["original-dashboard"])
            async let clonesText = ShellBridge.run(["list-dashboard"])
            let (oText, cText) = try await (originalText, clonesText)

            let op = oText.split(separator: "\t", omittingEmptySubsequences: false)
            if op.count >= 6 {
                original = OriginalStatus(
                    isRunning: String(op[0]) == "ON",
                    pid: Int(op[1]) ?? 0,
                    rssKB: Int(op[2]) ?? 0,
                    elapsed: String(op[3]),
                    version: String(op[4]),
                    startupEnabled: String(op[5]) == "YES"
                )
            }

            accounts = cText
                .split(separator: "\n")
                .compactMap { line in
                    let p = line.split(separator: "\t", omittingEmptySubsequences: false)
                    guard p.count >= 12, let id = Int(p[0]) else { return nil }

                    return ZaloAccount(
                        id: id,
                        name: String(p[1]),
                        isRunning: String(p[2]) == "ON",
                        iconVariant: String(p[3]).isEmpty ? "blue" : String(p[3]),
                        pid: Int(p[4]) ?? 0,
                        rssKB: Int(p[5]) ?? 0,
                        elapsed: String(p[6]),
                        version: String(p[7]),
                        sourceVersion: String(p[8]),
                        needsUpdate: String(p[9]) == "YES",
                        startupEnabled: String(p[10]) == "YES",
                        isDocked: String(p[11]) == "YES",
                        note: defaults.string(forKey: noteKey(id)) ?? "",
                        isFavorite: defaults.bool(forKey: favoriteKey(id))
                    )
                }

            lastRefresh = Date()
        } catch {
            if showError {
                errorMessage = error.localizedDescription
            }
        }
    }

    @discardableResult
    func perform(activity entry: ActivityEntry? = nil, _ work: @escaping () async throws -> Void) async -> Bool {
        guard !isBusy else { return false }
        isBusy = true

        do {
            try await work()
            isBusy = false
            if let entry {
                recordActivity(entry)
                noticeMessage = entry.title
            }
            await refresh()
            return true
        } catch {
            isBusy = false
            let message = error.localizedDescription
            errorMessage = message
            recordActivity(ActivityEntry(title: "Có lỗi xảy ra", detail: message, kind: "error"))
            return false
        }
    }

    func openOriginal() async {
        await perform(activity: ActivityEntry(title: original.isRunning ? "Đưa Zalo gốc ra trước" : "Mở Zalo gốc", detail: "Tài khoản chính", kind: "launch")) {
            if self.original.isRunning {
                _ = try await ShellBridge.run(["activate-original"])
            } else {
                _ = try await ShellBridge.run(["original"])
            }
        }
    }

    func quitOriginal() async {
        await perform(activity: ActivityEntry(title: "Tắt Zalo gốc", detail: "Tài khoản chính", kind: "quit")) {
            _ = try await ShellBridge.run(["quit-original"])
        }
    }

    func openClone(_ account: ZaloAccount) async {
        await perform(activity: ActivityEntry(title: account.isRunning ? "Đưa \(account.name) ra trước" : "Mở \(account.name)", detail: "Clone #\(account.id)", kind: "launch")) {
            if account.isRunning {
                _ = try await ShellBridge.run(["activate-clone", "\(account.id)"])
            } else {
                _ = try await ShellBridge.run(["launch", "\(account.id)"])
            }
        }
    }

    func quitClone(_ account: ZaloAccount) async {
        await perform(activity: ActivityEntry(title: "Tắt \(account.name)", detail: "Clone #\(account.id)", kind: "quit")) {
            _ = try await ShellBridge.run(["quit-clone", "\(account.id)"])
        }
    }

    func openAll() async {
        await perform(activity: ActivityEntry(title: "Mở tất cả tài khoản", detail: "Workspace", kind: "launch")) {
            _ = try await ShellBridge.run(["open-all"])
        }
    }

    func quitAllClones() async {
        await perform(activity: ActivityEntry(title: "Tắt tất cả clone", detail: "Zalo gốc không bị tắt", kind: "quit")) {
            _ = try await ShellBridge.run(["quit-all-clones"])
        }
    }

    func createClone(
        name: String,
        iconVariant: String = "blue",
        note: String = "",
        favorite: Bool = false,
        startup: Bool = false,
        dock: Bool = false
    ) async {
        await perform(activity: ActivityEntry(title: "Tạo clone \(name)", detail: "Cấu hình clone mới", kind: "create")) {
            let output = try await ShellBridge.run(["create", name])
            let fields = output.split(separator: "\t", omittingEmptySubsequences: false)
            guard fields.count >= 2, let id = Int(fields[1]) else {
                throw ShellError(message: "Clone đã tạo nhưng Manager không đọc được ID mới.")
            }

            self.defaults.set(note, forKey: self.noteKey(id))
            self.defaults.set(favorite, forKey: self.favoriteKey(id))

            if iconVariant != "blue" {
                _ = try await ShellBridge.run(["apply-icon", "\(id)", iconVariant])
            }

            if startup {
                _ = try await ShellBridge.run(["startup-set", "clone:\(id)", "1"])
            }

            if dock {
                _ = try await ShellBridge.run(["dock-add", "\(id)"])
            }

            var order = self.manualOrderIDs()
            if !order.contains(id) {
                order.append(id)
                self.setManualOrder(order)
            }
        }
    }

    func duplicateConfiguration(_ account: ZaloAccount) async {
        var candidate = "\(account.name) Copy"
        var n = 2
        let names = Set(accounts.map { $0.name.lowercased() })

        while names.contains(candidate.lowercased()) {
            candidate = "\(account.name) Copy \(n)"
            n += 1
        }

        await createClone(
            name: candidate,
            iconVariant: account.iconVariant,
            note: account.note,
            favorite: account.isFavorite,
            startup: false,
            dock: false
        )
    }

    func renameClone(_ account: ZaloAccount, to name: String) async {
        await perform(activity: ActivityEntry(title: "Đổi tên clone", detail: "\(account.name) → \(name)", kind: "edit")) {
            _ = try await ShellBridge.run(["rename", "\(account.id)", name])
        }
    }

    func deleteClone(_ account: ZaloAccount) async {
        await perform(activity: ActivityEntry(title: "Xóa \(account.name)", detail: "Clone #\(account.id) chuyển vào Trash", kind: "delete")) {
            _ = try await ShellBridge.run(["delete", "\(account.id)"])
            self.defaults.removeObject(forKey: self.noteKey(account.id))
            self.defaults.removeObject(forKey: self.favoriteKey(account.id))
            var order = self.manualOrderIDs()
            order.removeAll { $0 == account.id }
            self.setManualOrder(order)

            self.groups = self.groups.map { group in
                var copy = group
                copy.cloneIDs.removeAll { $0 == account.id }
                return copy
            }
            self.saveGroups()
        }
    }

    func openData(_ account: ZaloAccount) async {
        do {
            _ = try await ShellBridge.run(["open-data", "\(account.id)"])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func revealApp(_ account: ZaloAccount) async {
        do {
            _ = try await ShellBridge.run(["show-app", "\(account.id)"])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applyIcon(_ account: ZaloAccount, variant: String) async {
        await perform(activity: ActivityEntry(title: "Đổi icon \(account.name)", detail: DaloIconVariant.byID(variant).title, kind: "appearance")) {
            _ = try await ShellBridge.run(["apply-icon", "\(account.id)", variant])
        }
    }

    func setStartup(_ account: ZaloAccount, enabled: Bool) async {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index].startupEnabled = enabled
        }

        await perform {
            _ = try await ShellBridge.run(["startup-set", "clone:\(account.id)", enabled ? "1" : "0"])
        }
    }

    func setOriginalStartup(_ enabled: Bool) async {
        original.startupEnabled = enabled
        await perform {
            _ = try await ShellBridge.run(["startup-set", "original", enabled ? "1" : "0"])
        }
    }

    func setDock(_ account: ZaloAccount, enabled: Bool) async {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index].isDocked = enabled
        }

        await perform {
            _ = try await ShellBridge.run([enabled ? "dock-add" : "dock-remove", "\(account.id)"])
        }
    }

    func updateClone(_ account: ZaloAccount) async {
        await perform(activity: ActivityEntry(title: "Cập nhật \(account.name)", detail: "Safe rebuild từ Zalo gốc", kind: "update")) {
            _ = try await ShellBridge.run(["repair-clone", "\(account.id)"])
        }
    }

    func updateAllStopped() async {
        await perform(activity: ActivityEntry(title: "Cập nhật các clone đã tắt", detail: "Update Center", kind: "update")) {
            _ = try await ShellBridge.run(["update-stopped"])
        }
    }

    func autoRepairStoppedIfNeeded() async {
        guard defaults.bool(forKey: "autoRepairStopped") else { return }
        guard !autoRepairInProgress, !isBusy else { return }
        guard accounts.contains(where: { $0.needsUpdate && !$0.isRunning }) else { return }

        autoRepairInProgress = true
        await updateAllStopped()
        autoRepairInProgress = false
    }

    func repairRegistration() async {
        await perform(activity: ActivityEntry(title: "Sửa LaunchServices", detail: "Đăng ký lại ứng dụng clone", kind: "repair")) {
            _ = try await ShellBridge.run(["repair-registration"])
        }
    }

    func repairClone(_ id: Int) async {
        await perform(activity: ActivityEntry(title: "Repair clone #\(id)", detail: "Health Check", kind: "repair")) {
            _ = try await ShellBridge.run(["repair-clone", "\(id)"])
        }
        await refreshHealth()
    }

    func refreshHealth() async {
        do {
            let text = try await ShellBridge.run(["health-dashboard"])
            health = text
                .split(separator: "\n")
                .compactMap { line in
                    let p = line.split(separator: "\t", omittingEmptySubsequences: false)
                    guard p.count >= 4, let id = Int(p[0]) else { return nil }
                    return HealthItem(id: id, name: String(p[1]), state: String(p[2]), message: String(p[3]))
                }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshDiagnostics() async {
        do {
            diagnostics = try await ShellBridge.run(["diagnose"])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportDiagnostics() async {
        do {
            lastExportPath = try await ShellBridge.run(["export-diagnostics"])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openLogs() async {
        do {
            _ = try await ShellBridge.run(["open-logs"])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setNote(_ account: ZaloAccount, note: String) {
        defaults.set(note, forKey: noteKey(account.id))
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index].note = note
        }
    }

    func toggleFavorite(_ account: ZaloAccount) {
        let newValue = !account.isFavorite
        defaults.set(newValue, forKey: favoriteKey(account.id))
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index].isFavorite = newValue
        }
    }

    func manualOrderIDs() -> [Int] {
        let csv = defaults.string(forKey: "manualOrder") ?? ""
        return csv.split(separator: ",").compactMap { Int($0) }
    }

    func setManualOrder(_ ids: [Int]) {
        defaults.set(ids.map(String.init).joined(separator: ","), forKey: "manualOrder")
        objectWillChange.send()
    }

    func sortedAccounts(search: String, mode: AccountSortMode) -> [ZaloAccount] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var filtered = accounts

        if !query.isEmpty {
            filtered = filtered.filter {
                $0.name.lowercased().contains(query) ||
                $0.note.lowercased().contains(query) ||
                String($0.id).contains(query)
            }
        }

        switch mode {
        case .manual:
            let order = manualOrderIDs()
            let positions = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($0.element, $0.offset) })
            return filtered.sorted {
                let a = positions[$0.id] ?? Int.max
                let b = positions[$1.id] ?? Int.max
                if a != b { return a < b }
                return $0.id < $1.id
            }
        case .favorites:
            return filtered.sorted {
                if $0.isFavorite != $1.isFavorite { return $0.isFavorite && !$1.isFavorite }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .name:
            return filtered.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .id:
            return filtered.sorted { $0.id < $1.id }
        }
    }

    private func activityKey() -> String { "activity.v12" }

    private func loadActivity() {
        guard let data = defaults.data(forKey: activityKey()) else {
            activity = []
            return
        }
        activity = (try? JSONDecoder().decode([ActivityEntry].self, from: data)) ?? []
    }

    private func saveActivity() {
        let trimmed = Array(activity.prefix(150))
        if let data = try? JSONEncoder().encode(trimmed) {
            defaults.set(data, forKey: activityKey())
        }
    }

    func recordActivity(_ entry: ActivityEntry) {
        activity.insert(entry, at: 0)
        if activity.count > 150 { activity = Array(activity.prefix(150)) }
        saveActivity()
    }

    func clearActivity() {
        activity = []
        saveActivity()
    }

    var totalRSSKB: Int {
        accounts.filter(\.isRunning).reduce(original.isRunning ? original.rssKB : 0) { $0 + $1.rssKB }
    }

    var runningCount: Int {
        accounts.filter(\.isRunning).count + (original.isRunning ? 1 : 0)
    }

    var outdatedCount: Int { accounts.filter(\.needsUpdate).count }

    private func loadGroups() {
        guard let data = defaults.data(forKey: "launchGroups") else {
            groups = []
            return
        }

        do {
            groups = try JSONDecoder().decode([LaunchGroup].self, from: data)
        } catch {
            groups = []
        }
    }

    private func saveGroups() {
        do {
            let data = try JSONEncoder().encode(groups)
            defaults.set(data, forKey: "launchGroups")
        } catch {
            errorMessage = "Không lưu được nhóm: \(error.localizedDescription)"
        }
    }

    func saveGroup(_ group: LaunchGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
        } else {
            groups.append(group)
        }
        saveGroups()
    }

    func deleteGroup(_ group: LaunchGroup) {
        groups.removeAll { $0.id == group.id }
        saveGroups()
    }

    func openGroup(_ group: LaunchGroup) async {
        await perform(activity: ActivityEntry(title: "Mở workspace \(group.name)", detail: "\(group.cloneIDs.count + (group.includeOriginal ? 1 : 0)) tài khoản", kind: "workspace")) {
            if group.includeOriginal && !self.original.isRunning {
                _ = try await ShellBridge.run(["original"])
            }

            for id in group.cloneIDs {
                guard let account = self.accounts.first(where: { $0.id == id }) else { continue }
                if account.isRunning {
                    continue
                }
                _ = try await ShellBridge.run(["launch", "\(id)"])
            }
        }
    }

    func quitGroup(_ group: LaunchGroup) async {
        await perform(activity: ActivityEntry(title: "Tắt workspace \(group.name)", detail: "Workspace", kind: "workspace")) {
            for id in group.cloneIDs {
                guard self.accounts.contains(where: { $0.id == id }) else { continue }
                _ = try await ShellBridge.run(["quit-clone", "\(id)"])
            }

            if group.includeOriginal && self.original.isRunning {
                _ = try await ShellBridge.run(["quit-original"])
            }
        }
    }

    func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.canBecomeKey && $0.title != "Settings" }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}


@MainActor
extension AppModel {
    func arrangeWindows(_ mode: WindowLayoutMode) async {
        await perform(activity: ActivityEntry(title: "Sắp xếp cửa sổ", detail: mode.label, kind: "workspace")) {
            _ = try await ShellBridge.run(["window-layout", mode.rawValue])
        }
    }

    func saveWindowWorkspace() async {
        await perform(activity: ActivityEntry(title: "Lưu bố cục cửa sổ", detail: "Workspace hiện tại", kind: "workspace")) {
            _ = try await ShellBridge.run(["window-save"])
        }
    }

    func restoreWindowWorkspace() async {
        await perform(activity: ActivityEntry(title: "Khôi phục bố cục cửa sổ", detail: "Workspace đã lưu", kind: "workspace")) {
            _ = try await ShellBridge.run(["window-restore"])
        }
    }

    func openNextAvailable() async {
        if let account = accounts.sorted(by: { $0.id < $1.id }).first(where: { !$0.isRunning }) {
            await openClone(account)
        } else if !original.isRunning {
            await openOriginal()
        } else {
            noticeMessage = "Tất cả tài khoản đã được mở"
        }
    }

    func setGroupLayout(_ group: LaunchGroup, mode: WindowLayoutMode?) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[index].preferredLayout = mode?.rawValue
        saveGroups()
        noticeMessage = mode == nil ? "Đã bỏ layout mặc định" : "Workspace dùng layout \(mode!.label)"
    }

    func openWorkspace(_ group: LaunchGroup) async {
        await openGroup(group)
        guard let raw = group.preferredLayout, let mode = WindowLayoutMode(rawValue: raw) else { return }
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        await arrangeWindows(mode)
    }

    func exportConfiguration() {
        let panel = NSSavePanel()
        panel.title = "Xuất cấu hình Dalỏ"
        let stamp = ISO8601DateFormatter().string(from: Date()).prefix(10)
        panel.nameFieldStringValue = "Dalo-Configuration-\(stamp).json"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let settingsKeys = [
            "autoRefresh", "showStatusBadges", "showMenuBar", "confirmDelete",
            "autoRepairStopped", "accountSortMode", "dashboardDisplayModeV12", "refreshSecondsV12"
        ]
        var settings: [String: String] = [:]
        for key in settingsKeys {
            if let value = defaults.object(forKey: key) {
                settings[key] = String(describing: value)
            }
        }

        let clonePrefs = accounts.map {
            ClonePreferenceBackup(
                id: $0.id,
                name: $0.name,
                note: $0.note,
                isFavorite: $0.isFavorite,
                iconVariant: $0.iconVariant,
                startupEnabled: $0.startupEnabled,
                isDocked: $0.isDocked
            )
        }

        let backup = DaloConfigurationBackup(
            clones: clonePrefs,
            groups: groups,
            manualOrder: manualOrderIDs(),
            settings: settings
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(backup).write(to: url, options: .atomic)
            recordActivity(ActivityEntry(title: "Xuất cấu hình", detail: url.lastPathComponent, kind: "backup"))
            noticeMessage = "Đã xuất cấu hình"
        } catch {
            errorMessage = "Không xuất được cấu hình: \(error.localizedDescription)"
        }
    }

    func importConfiguration() async {
        let panel = NSOpenPanel()
        panel.title = "Nhập cấu hình Dalỏ"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(DaloConfigurationBackup.self, from: Data(contentsOf: url))

            for pref in backup.clones {
                guard let account = accounts.first(where: { $0.id == pref.id }) ?? accounts.first(where: { $0.name == pref.name }) else { continue }
                defaults.set(pref.note, forKey: noteKey(account.id))
                defaults.set(pref.isFavorite, forKey: favoriteKey(account.id))
            }

            groups = backup.groups
            saveGroups()
            setManualOrder(backup.manualOrder)

            for (key, value) in backup.settings {
                if value == "true" || value == "false" {
                    defaults.set(value == "true", forKey: key)
                } else if let number = Double(value) {
                    defaults.set(number, forKey: key)
                } else {
                    defaults.set(value, forKey: key)
                }
            }

            await refresh()
            recordActivity(ActivityEntry(title: "Nhập cấu hình", detail: url.lastPathComponent, kind: "backup"))
            noticeMessage = "Đã nhập cấu hình Dalỏ"
        } catch {
            errorMessage = "File cấu hình không hợp lệ: \(error.localizedDescription)"
        }
    }
}

final class DaloIconCache {
    static let shared = DaloIconCache()
    private let cache = NSCache<NSString, NSImage>()

    func image(named name: String) -> NSImage? {
        let key = name as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Icons/png"),
              let image = NSImage(contentsOf: url) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }
}

func daloFriendlySuggestion(for message: String) -> String {
    let lower = message.lowercased()
    if lower.contains("accessibility") || lower.contains("system events") {
        return "Cho Dalỏ quyền Accessibility trong System Settings → Privacy & Security → Accessibility rồi thử lại."
    }
    if lower.contains("clone đang chạy") || lower.contains("hãy tắt clone") {
        return "Tắt clone đó trước rồi thực hiện lại thao tác."
    }
    if lower.contains("zalo.app") || lower.contains("zalo gốc") {
        return "Kiểm tra Zalo chính thức đang nằm trong /Applications/Zalo.app."
    }
    if lower.contains("signature") || lower.contains("codesign") {
        return "Mở Sức khỏe → Repair clone, hoặc build/cài lại Dalỏ nếu lỗi vẫn còn."
    }
    return "Bạn có thể mở Chẩn đoán để xuất report kỹ thuật nếu lỗi tiếp tục xảy ra."
}

// MARK: - Dalỏ visual system

enum DaloDesign {
    // #0A6FE8 keeps white text above WCAG AA contrast while staying Dalỏ blue.
    static let brand = Color(red: 0.04, green: 0.435, blue: 0.91)
    static let success = Color(nsColor: .systemGreen)
    static let warning = Color(nsColor: .systemOrange)
    static let danger = Color(nsColor: .systemRed)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let canvas = Color(nsColor: .windowBackgroundColor)
    static let separator = Color.primary.opacity(0.10)
    static let subtleSeparator = Color.primary.opacity(0.065)

    static let radiusSmall: CGFloat = 10
    static let radiusMedium: CGFloat = 14
    static let radiusLarge: CGFloat = 18
    static let pagePadding: CGFloat = 28
    static let sectionSpacing: CGFloat = 22
    static let motionPress = 0.08
    static let motionFast = 0.14
    static let motionStandard = 0.20
}

struct DaloSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let radius: CGFloat
    let borderColor: Color
    let emphasized: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(DaloDesign.surface.opacity(colorScheme == .dark ? 0.78 : 0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(borderColor, lineWidth: emphasized ? 1.5 : 1)
            )
    }
}

extension View {
    func daloSurface(
        radius: CGFloat = DaloDesign.radiusMedium,
        borderColor: Color = DaloDesign.subtleSeparator,
        emphasized: Bool = false
    ) -> some View {
        modifier(DaloSurfaceModifier(radius: radius, borderColor: borderColor, emphasized: emphasized))
    }
}

struct DaloSectionTitle: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(DaloDesign.brand)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct DaloPressableRowStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed ? DaloDesign.brand.opacity(0.12) : Color.clear,
                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: DaloDesign.motionPress), value: configuration.isPressed)
    }
}

struct DaloResourceIcon: View {
    let variant: String
    var size: CGFloat = 54

    private var image: NSImage? {
        DaloIconCache.shared.image(named: DaloIconVariant.byID(variant).id)
    }

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: "questionmark.app.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.blue)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct ZaloAppIcon: View {
    private var icon: NSImage {
        NSWorkspace.shared.icon(forFile: "/Applications/Zalo.app")
    }

    var body: some View {
        Image(nsImage: icon)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: 54, height: 54)
            .accessibilityHidden(true)
    }
}

struct StatusBadge: View {
    @AppStorage("showStatusBadges") private var showStatusBadges = true
    let isRunning: Bool

    private var statusColor: Color {
        isRunning ? DaloDesign.success : Color.secondary
    }

    var body: some View {
        Group {
            if showStatusBadges {
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(isRunning ? "Đang mở" : "Đã tắt")
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .foregroundStyle(statusColor)
                .background(statusColor.opacity(0.11), in: Capsule())
                .overlay(Capsule().stroke(statusColor.opacity(0.22)))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Trạng thái")
                .accessibilityValue(isRunning ? "Đang mở" : "Đã tắt")
            }
        }
    }
}

struct SummaryPill: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.headline)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline.monospacedDigit())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct MetricChip: View {
    let text: String
    let icon: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.09), in: Capsule())
            .accessibilityElement(children: .combine)
    }
}

struct ProcessMetrics: View {
    let pid: Int
    let rssKB: Int
    let elapsed: String

    private var ram: String {
        guard rssKB > 0 else { return "— MB" }
        return String(format: "%.0f MB", Double(rssKB) / 1024.0)
    }

    var body: some View {
        HStack(spacing: 6) {
            MetricChip(text: ram, icon: "memorychip")
            if pid > 0 {
                MetricChip(text: "PID \(pid)", icon: "number")
            }
            if elapsed != "-" && !elapsed.isEmpty {
                MetricChip(text: elapsed, icon: "clock")
            }
        }
    }
}

struct OriginalCard: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                ZaloAppIcon()

                VStack(alignment: .leading, spacing: 5) {
                    Text("Zalo gốc")
                        .font(.title3.weight(.semibold))
                    Text("Tài khoản chính · v\(model.original.version)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                StatusBadge(isRunning: model.original.isRunning)
            }

            if model.original.isRunning {
                ProcessMetrics(pid: model.original.pid, rssKB: model.original.rssKB, elapsed: model.original.elapsed)
            }

            Spacer(minLength: 4)

            HStack {
                Button {
                    Task { await model.openOriginal() }
                } label: {
                    Label(model.original.isRunning ? "Đưa ra trước" : "Mở", systemImage: model.original.isRunning ? "macwindow.on.rectangle" : "play.fill")
                }
                .buttonStyle(.borderedProminent)

                if model.original.isRunning {
                    Button(role: .destructive) {
                        Task { await model.quitOriginal() }
                    } label: {
                        Label("Tắt", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if model.original.startupEnabled {
                    Image(systemName: "power.circle.fill")
                        .foregroundStyle(.green)
                        .help("Mở cùng macOS")
                        .accessibilityLabel("Mở cùng macOS")
                }
            }
        }
        .padding(18)
        .frame(minHeight: 205)
        .daloSurface(
            radius: DaloDesign.radiusLarge,
            borderColor: hovered ? DaloDesign.brand.opacity(0.34) : DaloDesign.subtleSeparator
        )
        .shadow(color: Color.black.opacity(hovered ? 0.055 : 0.025), radius: hovered ? 7 : 3, y: 2)
        .onHover { hovered = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: DaloDesign.motionFast), value: hovered)
    }
}

struct CloneCard: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let account: ZaloAccount

    @AppStorage("confirmDelete") private var confirmDelete = true

    @State private var showRename = false
    @State private var renameText = ""
    @State private var showDelete = false
    @State private var showIconPicker = false
    @State private var showNote = false
    @State private var noteText = ""
    @State private var showUpdateConfirm = false
    @State private var hovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top) {
                DaloResourceIcon(variant: account.iconVariant)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Text(account.name)
                            .font(.title3.weight(.semibold))
                            .lineLimit(1)
                            .help(account.name)

                        if account.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }

                    Text("Clone #\(account.id) · v\(account.version)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    Button {
                        model.toggleFavorite(account)
                    } label: {
                        Label(account.isFavorite ? "Bỏ yêu thích" : "Yêu thích", systemImage: account.isFavorite ? "star.slash" : "star")
                    }

                    Button {
                        noteText = account.note
                        showNote = true
                    } label: {
                        Label("Ghi chú", systemImage: "note.text")
                    }

                    Button {
                        renameText = account.name
                        showRename = true
                    } label: {
                        Label("Đổi tên", systemImage: "pencil")
                    }

                    Button {
                        Task { await model.duplicateConfiguration(account) }
                    } label: {
                        Label("Nhân bản cấu hình", systemImage: "plus.square.on.square")
                    }

                    Divider()

                    Button {
                        showIconPicker = true
                    } label: {
                        Label("Đổi icon clone…", systemImage: "app.badge")
                    }

                    Button {
                        Task { await model.setStartup(account, enabled: !account.startupEnabled) }
                    } label: {
                        Label(account.startupEnabled ? "Không mở cùng macOS" : "Mở cùng macOS", systemImage: "power")
                    }

                    Button {
                        Task { await model.setDock(account, enabled: !account.isDocked) }
                    } label: {
                        Label(account.isDocked ? "Bỏ khỏi Dock" : "Ghim vào Dock (thử nghiệm)", systemImage: "dock.rectangle")
                    }

                    Divider()

                    Button {
                        Task { await model.openData(account) }
                    } label: {
                        Label("Mở thư mục dữ liệu", systemImage: "folder")
                    }

                    Button {
                        Task { await model.revealApp(account) }
                    } label: {
                        Label("Hiện app trong Finder", systemImage: "doc.viewfinder")
                    }

                    Divider()

                    Button(role: .destructive) {
                        if confirmDelete {
                            showDelete = true
                        } else {
                            Task { await model.deleteClone(account) }
                        }
                    } label: {
                        Label("Xóa clone…", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .accessibilityLabel("Tùy chọn cho \(account.name)")
            }

            HStack(spacing: 8) {
                StatusBadge(isRunning: account.isRunning)

                if account.needsUpdate {
                    Label("Có cập nhật", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.10), in: Capsule())
                }

                Spacer()

                if account.startupEnabled {
                    Image(systemName: "power.circle.fill")
                        .foregroundStyle(.green)
                        .help("Mở cùng macOS")
                        .accessibilityLabel("Mở cùng macOS")
                }

                if account.isDocked {
                    Image(systemName: "dock.rectangle")
                        .foregroundStyle(.secondary)
                        .help("Đang ghim trong Dock")
                        .accessibilityLabel("Đang ghim trong Dock")
                }
            }

            if !account.note.isEmpty {
                Text(account.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if account.isRunning {
                ProcessMetrics(pid: account.pid, rssKB: account.rssKB, elapsed: account.elapsed)
            }

            Spacer(minLength: 0)

            HStack {
                Button {
                    Task { await model.openClone(account) }
                } label: {
                    Label(account.isRunning ? "Đưa ra trước" : "Mở", systemImage: account.isRunning ? "macwindow.on.rectangle" : "play.fill")
                }
                .buttonStyle(.borderedProminent)

                if account.isRunning {
                    Button(role: .destructive) {
                        Task { await model.quitClone(account) }
                    } label: {
                        Image(systemName: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                    .help("Tắt clone")
                    .accessibilityLabel("Tắt \(account.name)")
                }

                if account.needsUpdate {
                    Button {
                        if account.isRunning {
                            showUpdateConfirm = true
                        } else {
                            Task { await model.updateClone(account) }
                        }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.bordered)
                    .help("Cập nhật clone từ Zalo gốc")
                    .accessibilityLabel("Cập nhật \(account.name)")
                }

                Spacer()

                Button {
                    model.toggleFavorite(account)
                } label: {
                    Image(systemName: account.isFavorite ? "star.fill" : "star")
                }
                .buttonStyle(.plain)
                .foregroundStyle(account.isFavorite ? Color.yellow : Color.secondary)
                .help(account.isFavorite ? "Bỏ yêu thích" : "Yêu thích")
                .accessibilityLabel(account.isFavorite ? "Bỏ \(account.name) khỏi yêu thích" : "Thêm \(account.name) vào yêu thích")
                .accessibilityValue(account.isFavorite ? "Đã chọn" : "Chưa chọn")
            }
        }
        .padding(18)
        .frame(minHeight: 225)
        .daloSurface(
            radius: DaloDesign.radiusLarge,
            borderColor: account.needsUpdate ? DaloDesign.warning.opacity(0.46) :
                (account.isRunning ? DaloDesign.success.opacity(0.44) :
                    (hovered ? DaloDesign.brand.opacity(0.34) : DaloDesign.subtleSeparator)),
            emphasized: account.needsUpdate || account.isRunning
        )
        .shadow(color: Color.black.opacity(hovered ? 0.06 : 0.025), radius: hovered ? 7 : 3, y: 2)
        .onHover { hovered = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: DaloDesign.motionFast), value: hovered)
        .sheet(isPresented: $showIconPicker) {
            IconPickerSheet(account: account)
                .environmentObject(model)
        }
        .alert("Đổi tên clone", isPresented: $showRename) {
            TextField("Tên mới", text: $renameText)
            Button("Hủy", role: .cancel) {}
            Button("Lưu") {
                let value = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    Task { await model.renameClone(account, to: value) }
                }
            }
        } message: {
            Text("Tên này chỉ dùng để quản lý và hiển thị trong Finder.")
        }
        .alert("Ghi chú", isPresented: $showNote) {
            TextField("Ví dụ: khách hàng, sales, CSKH…", text: $noteText)
            Button("Hủy", role: .cancel) {}
            Button("Lưu") {
                model.setNote(account, note: noteText.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        } message: {
            Text("Ghi chú chỉ lưu trong Dalỏ Multi.")
        }
        .confirmationDialog(
            "Xóa \(account.name)?",
            isPresented: $showDelete,
            titleVisibility: .visible
        ) {
            Button("Chuyển app và dữ liệu vào Trash", role: .destructive) {
                Task { await model.deleteClone(account) }
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Zalo gốc không bị ảnh hưởng. Dữ liệu clone được chuyển vào Trash thay vì xóa ngay.")
        }
        .confirmationDialog(
            "Cập nhật \(account.name)?",
            isPresented: $showUpdateConfirm,
            titleVisibility: .visible
        ) {
            Button("Tắt clone và cập nhật") {
                Task { await model.updateClone(account) }
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Dalỏ sẽ rebuild phần ứng dụng từ Zalo gốc mới nhất nhưng giữ data folder, session, tên và icon riêng của clone.")
        }
    }
}

struct IconPickerSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let account: ZaloAccount

    @State private var category = "Tất cả"
    @State private var search = ""

    private let columns = [GridItem(.adaptive(minimum: 108), spacing: 12)]

    private var categories: [String] {
        ["Tất cả"] + Array(Set(DaloIconVariant.all.map(\.group))).sorted()
    }

    private var filtered: [DaloIconVariant] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return DaloIconVariant.all.filter { item in
            let groupOK = category == "Tất cả" || item.group == category
            let queryOK = q.isEmpty || item.title.lowercased().contains(q) || item.id.lowercased().contains(q)
            return groupOK && queryOK
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                DaloResourceIcon(variant: account.iconVariant, size: 54)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Icon cho \(account.name)")
                        .font(.title2.bold())
                    Text("Bộ Dalo Board Family · icon thật trong Finder và Dock")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Đóng") { dismiss() }.keyboardShortcut(.cancelAction)
            }

            if account.isRunning {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text("Clone đang chạy. Tắt clone trước khi đổi icon để code signature và Dock cache được cập nhật an toàn.")
                        .font(.caption)
                    Spacer()
                    Button("Tắt \(account.name)") { Task { await model.quitClone(account) } }
                }
                .padding(10)
                .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 11))
            }

            HStack(spacing: 10) {
                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Tìm icon…", text: $search).textFieldStyle(.plain)
                    if !search.isEmpty {
                        Button { search = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Xóa nội dung tìm kiếm icon")
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
                .frame(width: 230)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(categories, id: \.self) { item in
                            Button(item) { category = item }
                                .buttonStyle(.bordered)
                                .tint(category == item ? Color.accentColor : nil)
                        }
                    }
                }
            }

            Divider()

            ScrollView {
                if filtered.isEmpty {
                    ContentUnavailableView("Không tìm thấy icon", systemImage: "magnifyingglass", description: Text("Thử từ khóa hoặc category khác."))
                        .frame(minHeight: 330)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filtered) { item in
                            Button {
                                Task {
                                    let currentError = model.errorMessage
                                    await model.applyIcon(account, variant: item.id)
                                    if model.errorMessage == nil || model.errorMessage == currentError { dismiss() }
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    DaloResourceIcon(variant: item.id, size: 76)
                                    Text(item.title).font(.caption.weight(.semibold)).lineLimit(1)
                                    Text(item.group).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    DaloIconVariant.byID(account.iconVariant).id == item.id ? Color.accentColor.opacity(0.12) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .stroke(DaloIconVariant.byID(account.iconVariant).id == item.id ? Color.accentColor : Color.primary.opacity(0.07))
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(account.isRunning)
                            .accessibilityLabel(item.title)
                            .accessibilityValue(DaloIconVariant.byID(account.iconVariant).id == item.id ? "Đang dùng" : "Chưa chọn")
                            .accessibilityHint(account.isRunning ? "Tắt clone trước khi đổi icon" : "Áp dụng icon này cho \(account.name)")
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .padding(22)
        .frame(width: 780, height: 610)
    }
}

struct CloneWizardSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var note = ""
    @State private var iconVariant = "blue"
    @State private var iconCategory = "Màu sắc cơ bản"
    @State private var favorite = false
    @State private var startup = false
    @State private var dock = false
    @FocusState private var nameFocused: Bool

    private var categories: [String] { Array(Set(DaloIconVariant.all.map(\.group))).sorted() }
    private var visibleIcons: [DaloIconVariant] { DaloIconVariant.all.filter { $0.group == iconCategory } }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tạo tài khoản mới")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Text("Clone Zalo độc lập, sau đó đăng nhập tài khoản riêng trong chính Zalo.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Đóng") { dismiss() }.keyboardShortcut(.cancelAction)
            }

            HStack(alignment: .top, spacing: 22) {
                VStack(spacing: 10) {
                    DaloResourceIcon(variant: iconVariant, size: 110)
                    Text(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Clone mới" : name)
                        .font(.headline)
                        .lineLimit(1)
                    Text(DaloIconVariant.byID(iconVariant).title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 150)
                .padding(18)
                .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tên tài khoản")
                            .font(.subheadline.weight(.semibold))
                        TextField("Ví dụ: Business", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .focused($nameFocused)
                        Text("Bắt buộc · dùng để phân biệt trong Dalỏ và Finder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ghi chú")
                            .font(.subheadline.weight(.semibold))
                        TextField("Ví dụ: khách hàng / sales / CSKH", text: $note)
                            .textFieldStyle(.roundedBorder)
                        Text("Không bắt buộc · chỉ lưu trong Dalỏ")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Chủ đề icon").font(.headline)
                        Spacer()
                        Picker("Chủ đề", selection: $iconCategory) {
                            ForEach(categories, id: \.self) { Text($0).tag($0) }
                        }
                        .labelsHidden()
                        .frame(width: 190)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 9) {
                            ForEach(visibleIcons) { item in
                                Button {
                                    iconVariant = item.id
                                } label: {
                                    VStack(spacing: 5) {
                                        DaloResourceIcon(variant: item.id, size: 54)
                                        Text(item.title).font(.caption2).lineLimit(1)
                                    }
                                    .padding(7)
                                    .frame(width: 82)
                                    .background(iconVariant == item.id ? Color.accentColor.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 11))
                                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(iconVariant == item.id ? Color.accentColor : Color.primary.opacity(0.06)))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(item.title)
                                .accessibilityValue(iconVariant == item.id ? "Đã chọn" : "Chưa chọn")
                            }
                        }
                    }
                    .frame(height: 86)

                    Divider()
                    Toggle("Đánh dấu yêu thích", isOn: $favorite)
                    Toggle("Mở cùng macOS", isOn: $startup)
                    Toggle("Ghim clone vào Dock", isOn: $dock)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill").foregroundStyle(.green)
                Text("Dalỏ không sao chép password, token, tin nhắn hoặc session từ clone khác.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack {
                Spacer()
                Button("Hủy") { dismiss() }
                Button("Tạo clone") {
                    let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
                    dismiss()
                    Task {
                        await model.createClone(
                            name: cleanName,
                            iconVariant: iconVariant,
                            note: cleanNote,
                            favorite: favorite,
                            startup: startup,
                            dock: dock
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(26)
        .frame(width: 720, height: 650)
        .onAppear { nameFocused = true }
    }
}

struct OrderSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var ids: [Int] = []

    private func name(for id: Int) -> String {
        model.accounts.first(where: { $0.id == id })?.name ?? "Clone #\(id)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sắp xếp tài khoản")
                        .font(.title2.bold())
                    Text("Dùng mũi tên để đặt thứ tự card khi chọn “Thứ tự của tôi”.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Đóng") { dismiss() }
            }

            List {
                ForEach(Array(ids.enumerated()), id: \.element) { index, id in
                    HStack {
                        Text("\(index + 1)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        DaloResourceIcon(
                            variant: model.accounts.first(where: { $0.id == id })?.iconVariant ?? "blue",
                            size: 30
                        )
                        Text(name(for: id))
                        Spacer()
                        Button {
                            guard index > 0 else { return }
                            ids.swapAt(index, index - 1)
                        } label: {
                            Image(systemName: "chevron.up")
                        }
                        .disabled(index == 0)
                        .accessibilityLabel("Di chuyển \(name(for: id)) lên")

                        Button {
                            guard index < ids.count - 1 else { return }
                            ids.swapAt(index, index + 1)
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                        .disabled(index == ids.count - 1)
                        .accessibilityLabel("Di chuyển \(name(for: id)) xuống")
                    }
                }
            }

            HStack {
                Spacer()
                Button("Hủy") { dismiss() }
                Button("Lưu thứ tự") {
                    model.setManualOrder(ids)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
        .frame(width: 520, height: 520)
        .onAppear {
            let existing = model.manualOrderIDs()
            let existingSet = Set(existing)
            let remaining = model.accounts.map(\.id).filter { !existingSet.contains($0) }.sorted()
            ids = existing.filter { id in model.accounts.contains(where: { $0.id == id }) } + remaining
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject var model: AppModel
    @AppStorage("autoRefresh") private var autoRefresh = true
    @AppStorage("accountSortMode") private var sortModeRaw = AccountSortMode.manual.rawValue

    @State private var showAdd = false
    @State private var showOrder = false
    @State private var search = ""
    @FocusState private var searchFocused: Bool

    private let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    private var sortMode: AccountSortMode {
        AccountSortMode(rawValue: sortModeRaw) ?? .manual
    }

    private var shownAccounts: [ZaloAccount] {
        model.sortedAccounts(search: search, mode: sortMode)
    }

    private var runningCount: Int {
        model.accounts.filter(\.isRunning).count + (model.original.isRunning ? 1 : 0)
    }

    private var outdated: [ZaloAccount] {
        model.accounts.filter(\.needsUpdate)
    }

    private var stoppedOutdatedCount: Int {
        outdated.filter { !$0.isRunning }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center, spacing: 14) {
                    DaloResourceIcon(variant: "blue", size: 58)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Dalỏ Multi")
                            .font(.largeTitle.bold())
                        Text("Quản lý nhiều Zalo độc lập trên Mac")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        Task { await model.openAll() }
                    } label: {
                        Label("Mở tất cả", systemImage: "play.rectangle.on.rectangle")
                    }

                    Button {
                        Task { await model.quitAllClones() }
                    } label: {
                        Label("Tắt clone", systemImage: "stop.circle")
                    }

                    Button {
                        Task { await model.refresh(showError: true) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Làm mới")

                    Button {
                        showAdd = true
                    } label: {
                        Label("Thêm tài khoản", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }

                HStack(spacing: 12) {
                    SummaryPill(title: "Tổng tài khoản", value: "\(model.accounts.count + 1)", icon: "person.2.fill")
                    SummaryPill(title: "Đang mở", value: "\(runningCount)", icon: "bolt.fill")
                    SummaryPill(title: "Clone", value: "\(model.accounts.count)", icon: "square.on.square")
                    SummaryPill(title: "Cần cập nhật", value: "\(outdated.count)", icon: "arrow.triangle.2.circlepath")
                    Spacer()
                }

                if !outdated.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Zalo gốc đã khác phiên bản với \(outdated.count) clone")
                                .font(.headline)
                            Text("Dalỏ có thể rebuild phần ứng dụng từ Zalo gốc và giữ nguyên data/session riêng. Clone đang chạy sẽ không được bulk-update.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if stoppedOutdatedCount > 0 {
                            Button("Cập nhật \(stoppedOutdatedCount) clone đã tắt") {
                                Task { await model.updateAllStopped() }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(14)
                    .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.orange.opacity(0.25))
                    )
                }

                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Tìm theo tên, ghi chú hoặc clone ID", text: $search)
                            .textFieldStyle(.plain)
                            .focused($searchFocused)
                        if !search.isEmpty {
                            Button {
                                search = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                    .frame(maxWidth: 420)

                    Picker("Sắp xếp", selection: $sortModeRaw) {
                        ForEach(AccountSortMode.allCases) { mode in
                            Text(mode.label).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)

                    Button {
                        showOrder = true
                    } label: {
                        Label("Thứ tự", systemImage: "arrow.up.arrow.down")
                    }

                    Spacer()
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                    OriginalCard()

                    ForEach(shownAccounts) { account in
                        CloneCard(account: account)
                    }

                    Button {
                        showAdd = true
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 34))
                            Text("Thêm tài khoản")
                                .font(.headline)
                            Text("Tạo một Zalo clone độc lập")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 220)
                    }
                    .buttonStyle(.plain)
                    .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                            .foregroundStyle(.secondary.opacity(0.3))
                    )
                }

                HStack {
                    Text("Cập nhật lúc \(model.lastRefresh.formatted(date: .omitted, time: .standard))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            }
            .padding(26)
        }
        .onAppear {
            Task {
                await model.refresh()
                await model.autoRepairStoppedIfNeeded()
            }
        }
        .onReceive(timer) { _ in
            guard autoRefresh else { return }
            Task {
                await model.refresh()
                await model.autoRepairStoppedIfNeeded()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .daloFocusSearch)) { _ in
            searchFocused = true
        }
        .sheet(isPresented: $showAdd) {
            CloneWizardSheet()
                .environmentObject(model)
        }
        .sheet(isPresented: $showOrder) {
            OrderSheet()
                .environmentObject(model)
        }
    }
}

struct GroupCard: View {
    @EnvironmentObject var model: AppModel
    let group: LaunchGroup
    let edit: () -> Void

    private var members: [String] {
        var result: [String] = []
        if group.includeOriginal {
            result.append("Zalo gốc")
        }

        for id in group.cloneIDs {
            if let account = model.accounts.first(where: { $0.id == id }) {
                result.append(account.name)
            }
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "rectangle.3.group.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text(group.name)
                        .font(.headline)
                    Text("\(members.count) tài khoản")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                Menu {
                    Button("Sửa nhóm", action: edit)
                    Button(role: .destructive) {
                        model.deleteGroup(group)
                    } label: {
                        Label("Xóa nhóm", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
            }

            Text(members.isEmpty ? "Chưa có thành viên" : members.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack {
                Button {
                    Task { await model.openGroup(group) }
                } label: {
                    Label("Mở nhóm", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    Task { await model.quitGroup(group) }
                } label: {
                    Label("Tắt nhóm", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct GroupEditorSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    let existing: LaunchGroup?

    @State private var name: String
    @State private var includeOriginal: Bool
    @State private var selectedIDs: Set<Int>

    init(existing: LaunchGroup?) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _includeOriginal = State(initialValue: existing?.includeOriginal ?? false)
        _selectedIDs = State(initialValue: Set(existing?.cloneIDs ?? []))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(existing == nil ? "Tạo nhóm" : "Sửa nhóm")
                .font(.title2.bold())

            TextField("Tên nhóm, ví dụ WORK", text: $name)
                .textFieldStyle(.roundedBorder)

            Toggle("Bao gồm Zalo gốc", isOn: $includeOriginal)

            Text("Clone")
                .font(.headline)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(model.accounts.sorted(by: { $0.id < $1.id })) { account in
                        Toggle(isOn: Binding(
                            get: { selectedIDs.contains(account.id) },
                            set: { enabled in
                                if enabled {
                                    selectedIDs.insert(account.id)
                                } else {
                                    selectedIDs.remove(account.id)
                                }
                            }
                        )) {
                            HStack {
                                DaloResourceIcon(variant: account.iconVariant, size: 30)
                                Text(account.name)
                                Spacer()
                                Text("#\(account.id)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Button("Hủy") { dismiss() }
                Button("Lưu") {
                    let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let group = LaunchGroup(
                        id: existing?.id ?? UUID(),
                        name: clean,
                        includeOriginal: includeOriginal,
                        cloneIDs: selectedIDs.sorted(),
                        preferredLayout: existing?.preferredLayout
                    )
                    model.saveGroup(group)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 520, height: 560)
    }
}

struct GroupsView: View {
    @EnvironmentObject var model: AppModel
    @State private var showEditor = false
    @State private var editingGroup: LaunchGroup?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nhóm mở nhanh")
                            .font(.largeTitle.bold())
                        Text("Mở hoặc tắt nhiều tài khoản chỉ bằng một nút.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        editingGroup = nil
                        showEditor = true
                    } label: {
                        Label("Tạo nhóm", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }

                if model.groups.isEmpty {
                    ContentUnavailableView(
                        "Chưa có nhóm",
                        systemImage: "rectangle.3.group",
                        description: Text("Tạo WORK, SALES, CSKH… rồi chọn các tài khoản cần mở cùng nhau.")
                    )
                    .frame(minHeight: 380)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 16)], spacing: 16) {
                        ForEach(model.groups) { group in
                            GroupCard(group: group) {
                                editingGroup = group
                                showEditor = true
                            }
                        }
                    }
                }
            }
            .padding(26)
        }
        .sheet(isPresented: $showEditor) {
            GroupEditorSheet(existing: editingGroup)
                .environmentObject(model)
        }
    }
}

struct StartupView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                DaloPageHeader(
                    title: "Khởi động cùng macOS",
                    subtitle: "Chỉ những tài khoản bạn bật ở đây mới được mở lúc đăng nhập Mac.",
                    icon: "power"
                )

                GroupBox("Tài khoản chính") {
                    Toggle(isOn: Binding(
                        get: { model.original.startupEnabled },
                        set: { enabled in
                            Task { await model.setOriginalStartup(enabled) }
                        }
                    )) {
                        HStack {
                            ZaloAppIcon()
                            VStack(alignment: .leading) {
                                Text("Zalo gốc")
                                    .font(.headline)
                                Text("Mở sau khi đăng nhập macOS")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                GroupBox("Clone") {
                    Group {
                        if model.accounts.isEmpty {
                            ContentUnavailableView(
                                "Chưa có clone",
                                systemImage: "square.on.square",
                                description: Text("Tạo clone đầu tiên từ Tổng quan rồi quay lại để bật khởi động cùng macOS.")
                            )
                            .frame(minHeight: 150)
                        } else {
                            VStack(spacing: 2) {
                                ForEach(model.accounts.sorted(by: { $0.id < $1.id })) { account in
                                    Toggle(isOn: Binding(
                                        get: { account.startupEnabled },
                                        set: { enabled in
                                            Task { await model.setStartup(account, enabled: enabled) }
                                        }
                                    )) {
                                        HStack {
                                            DaloResourceIcon(variant: account.iconVariant, size: 34)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(account.name)
                                                Text("Clone #\(account.id)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 7)

                                    if account.id != model.accounts.sorted(by: { $0.id < $1.id }).last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                }

                Label("Dalỏ dùng LaunchAgent riêng. Tắt hết toggle sẽ tự gỡ LaunchAgent.", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(DaloDesign.pagePadding)
            .frame(maxWidth: 840, alignment: .leading)
        }
        .task {
            await model.refresh()
        }
    }
}

struct HealthStateBadge: View {
    let state: String

    private var color: Color {
        switch state {
        case "OK": return .green
        case "WARN": return .orange
        default: return .red
        }
    }

    var body: some View {
        Text(state)
            .font(.caption.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(color.opacity(0.10), in: Capsule())
    }
}

struct HealthView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                DaloPageHeader(
                    title: "Sức khỏe hệ thống",
                    subtitle: "Kiểm tra version, Bundle ID, helper, data folder và code signature.",
                    icon: "heart.text.square.fill"
                )

                Spacer()

                Button {
                    Task { await model.updateAllStopped() }
                } label: {
                    Label("Update clone đã tắt", systemImage: "arrow.triangle.2.circlepath")
                }

                Button {
                    Task { await model.repairRegistration() }
                } label: {
                    Label("Repair LaunchServices", systemImage: "wrench.and.screwdriver")
                }

                Button {
                    Task { await model.refreshHealth() }
                } label: {
                    Label("Kiểm tra lại", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(DaloDesign.pagePadding)

            Divider()

            List(model.health) { item in
                HStack(spacing: 14) {
                    if item.id == 0 {
                        ZaloAppIcon()
                    } else {
                        DaloResourceIcon(
                            variant: model.accounts.first(where: { $0.id == item.id })?.iconVariant ?? "blue",
                            size: 42
                        )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.id == 0 ? "Zalo gốc" : item.name)
                            .font(.headline)
                        Text(item.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                    HealthStateBadge(state: item.state)

                    if item.id > 0 && item.state != "OK" {
                        Button("Sửa / rebuild") {
                            Task { await model.repairClone(item.id) }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .task {
            await model.refreshHealth()
        }
    }
}

struct DiagnosticsView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                DaloPageHeader(
                    title: "Chẩn đoán",
                    subtitle: "Thông tin kỹ thuật để debug mà không đọc tin nhắn, token hoặc Keychain.",
                    icon: "stethoscope"
                )

                Spacer()

                Button {
                    Task { await model.exportDiagnostics() }
                } label: {
                    Label("Export Report", systemImage: "square.and.arrow.up")
                }

                Button {
                    Task { await model.openLogs() }
                } label: {
                    Label("Mở Log", systemImage: "folder")
                }

                Button {
                    Task { await model.refreshDiagnostics() }
                } label: {
                    Label("Chạy lại", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(DaloDesign.pagePadding)

            if !model.lastExportPath.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Đã export: \(model.lastExportPath)")
                        .font(.caption)
                        .textSelection(.enabled)
                    Spacer()
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 12)
            }

            Divider()

            ScrollView([.vertical, .horizontal]) {
                Text(model.diagnostics.isEmpty ? "Bấm “Chạy lại” để lấy thông tin chẩn đoán." : model.diagnostics)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(24)
            }
            .background(Color(nsColor: .textBackgroundColor).opacity(0.45))
        }
        .task {
            if model.diagnostics.isEmpty {
                await model.refreshDiagnostics()
            }
        }
    }
}

struct SettingsView: View {
    @AppStorage("confirmDelete") private var confirmDelete = true
    @AppStorage("autoRefresh") private var autoRefresh = true
    @AppStorage("showStatusBadges") private var showStatusBadges = true
    @AppStorage("showMenuBar") private var showMenuBar = true
    @AppStorage("autoRepairStopped") private var autoRepairStopped = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Cài đặt")
                        .font(.largeTitle.bold())
                    Text("Các tùy chọn này không sửa Zalo gốc.")
                        .foregroundStyle(.secondary)
                }

                GroupBox("Dashboard") {
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle("Tự làm mới trạng thái mỗi 2 giây", isOn: $autoRefresh)
                        Toggle("Hiển thị badge trạng thái", isOn: $showStatusBadges)
                        Toggle("Hiển thị Dalỏ trên menu bar", isOn: $showMenuBar)
                        Toggle("Xác nhận trước khi xóa clone", isOn: $confirmDelete)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                }

                GroupBox("Cập nhật clone") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Tự update clone đã tắt khi Zalo gốc đổi phiên bản", isOn: $autoRepairStopped)
                        Text("Dalỏ không tự kill clone đang chạy. Clone đang mở sẽ chờ bạn tắt hoặc bấm Cập nhật thủ công.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                }

                GroupBox("Quyền riêng tư") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Không đọc tin nhắn", systemImage: "checkmark.shield.fill")
                        Label("Không copy password / token / Keychain", systemImage: "checkmark.shield.fill")
                        Label("Diagnostic export chỉ chứa thông tin kỹ thuật đã giảm nhận diện", systemImage: "checkmark.shield.fill")
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                }

                GroupBox("Engine") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Multi-instance engine tương thích dữ liệu v1", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                        Text("Feature update không đổi đường dẫn profile của các clone hiện tại. Auto-update chỉ rebuild application bundle.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                }
            }
            .padding(26)
            .frame(maxWidth: 760, alignment: .leading)
        }
    }
}

struct MenuBarView: View {
    @EnvironmentObject var model: AppModel
    private let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                DaloResourceIcon(variant: "blue", size: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Dalỏ Multi")
                        .font(.headline)
                    Text("\(model.accounts.filter(\.isRunning).count + (model.original.isRunning ? 1 : 0)) đang mở")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()

            HStack {
                Circle()
                    .fill(model.original.isRunning ? Color.green : Color.secondary.opacity(0.4))
                    .frame(width: 7, height: 7)
                Text("Zalo gốc")
                Spacer()
                Button(model.original.isRunning ? "Mở" : "Chạy") {
                    Task { await model.openOriginal() }
                }
                if model.original.isRunning {
                    Button {
                        Task { await model.quitOriginal() }
                    } label: {
                        Image(systemName: "stop.fill")
                    }
                }
            }

            ForEach(model.accounts.sorted(by: { $0.id < $1.id })) { account in
                HStack {
                    DaloResourceIcon(variant: account.iconVariant, size: 22)
                    Circle()
                        .fill(account.isRunning ? Color.green : Color.secondary.opacity(0.4))
                        .frame(width: 7, height: 7)
                    Text(account.name)
                        .lineLimit(1)
                    Spacer()

                    Button(account.isRunning ? "Mở" : "Chạy") {
                        Task { await model.openClone(account) }
                    }

                    if account.isRunning {
                        Button {
                            Task { await model.quitClone(account) }
                        } label: {
                            Image(systemName: "stop.fill")
                        }
                    }
                }
            }

            Divider()

            HStack {
                Button("Mở tất cả") {
                    Task { await model.openAll() }
                }
                Button("Tắt clone") {
                    Task { await model.quitAllClones() }
                }
                Spacer()
                Button("Dashboard") {
                    model.openMainWindow()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .frame(width: 380)
        .onAppear {
            Task { await model.refresh() }
        }
        .onReceive(timer) { _ in
            Task { await model.refresh() }
        }
    }
}

struct DaloPageHeader: View {
    let title: String
    let subtitle: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(DaloDesign.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: DaloDesign.radiusSmall, style: .continuous))
                    .foregroundStyle(DaloDesign.brand)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct DaloMetricCardV12: View {
    let title: String
    let value: String
    let icon: String
    var detail: String = ""
    var tint: Color = DaloDesign.brand

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .frame(width: 38, height: 38)
                .foregroundStyle(tint)
                .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: DaloDesign.radiusSmall, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.weight(.semibold).monospacedDigit())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .daloSurface()
        .accessibilityElement(children: .combine)
    }
}

struct DaloSearchFieldV12: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Tìm tài khoản, ghi chú hoặc clone ID", text: $text)
                .textFieldStyle(.plain)
                .focused(focused)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Xóa nội dung tìm kiếm")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(DaloDesign.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(focused.wrappedValue ? DaloDesign.brand : DaloDesign.separator, lineWidth: focused.wrappedValue ? 2 : 1)
        )
    }
}

struct CompactOriginalRowV12: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        HStack(spacing: 12) {
            ZaloAppIcon()
                .scaleEffect(0.72)
                .frame(width: 42, height: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text("Zalo gốc").font(.headline)
                Text("v\(model.original.version) · tài khoản chính")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if model.original.isRunning {
                ProcessMetrics(pid: model.original.pid, rssKB: model.original.rssKB, elapsed: model.original.elapsed)
            }
            StatusBadge(isRunning: model.original.isRunning)
            Button(model.original.isRunning ? "Đưa ra trước" : "Mở") {
                Task { await model.openOriginal() }
            }
            .buttonStyle(.borderedProminent)
            if model.original.isRunning {
                Button {
                    Task { await model.quitOriginal() }
                } label: {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(.bordered)
                .help("Tắt Zalo gốc")
                .accessibilityLabel("Tắt Zalo gốc")
            }
        }
        .padding(12)
        .daloSurface()
    }
}

struct CompactCloneRowV12: View {
    @EnvironmentObject var model: AppModel
    let account: ZaloAccount

    var ramText: String {
        account.rssKB > 0 ? String(format: "%.0f MB", Double(account.rssKB) / 1024.0) : "—"
    }

    var body: some View {
        HStack(spacing: 12) {
            DaloResourceIcon(variant: account.iconVariant, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(account.name).font(.headline).lineLimit(1)
                        .help(account.name)
                    if account.isFavorite {
                        Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow)
                    }
                }
                Text(account.note.isEmpty ? "Clone #\(account.id) · v\(account.version)" : account.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if account.needsUpdate {
                Label("Update", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }
            if account.isRunning {
                Text(ramText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 62, alignment: .trailing)
            }
            StatusBadge(isRunning: account.isRunning)
            Button(account.isRunning ? "Đưa ra trước" : "Mở") {
                Task { await model.openClone(account) }
            }
            .buttonStyle(.borderedProminent)
            if account.isRunning {
                Button {
                    Task { await model.quitClone(account) }
                } label: {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(.bordered)
                .help("Tắt \(account.name)")
                .accessibilityLabel("Tắt \(account.name)")
            }
        }
        .padding(11)
        .daloSurface(radius: 13)
        .contextMenu {
            Button(account.isFavorite ? "Bỏ yêu thích" : "Yêu thích") { model.toggleFavorite(account) }
            Button("Mở data folder") { Task { await model.openData(account) } }
            Button("Hiện trong Finder") { Task { await model.revealApp(account) } }
            if account.needsUpdate && !account.isRunning {
                Button("Cập nhật clone") { Task { await model.updateClone(account) } }
            }
        }
    }
}

struct OverviewV12: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onNavigate: (SidebarPage) -> Void

    @AppStorage("autoRefresh") private var autoRefresh = true
    @AppStorage("accountSortMode") private var sortModeRaw = AccountSortMode.manual.rawValue
    @AppStorage("dashboardDisplayModeV12") private var displayModeRaw = DashboardDisplayMode.cards.rawValue
    @AppStorage("refreshSecondsV12") private var refreshSeconds = 5.0

    @State private var showAdd = false
    @State private var showOrder = false
    @State private var search = ""
    @FocusState private var searchFocused: Bool

    private var sortMode: AccountSortMode { AccountSortMode(rawValue: sortModeRaw) ?? .manual }
    private var displayMode: DashboardDisplayMode { DashboardDisplayMode(rawValue: displayModeRaw) ?? .cards }
    private var shownAccounts: [ZaloAccount] { model.sortedAccounts(search: search, mode: sortMode) }
    private var favorites: [ZaloAccount] { shownAccounts.filter(\.isFavorite) }
    private var regulars: [ZaloAccount] {
        if search.isEmpty && !favorites.isEmpty { return shownAccounts.filter { !$0.isFavorite } }
        return shownAccounts
    }
    private var totalRAM: String { String(format: "%.1f GB", Double(model.totalRSSKB) / 1024.0 / 1024.0) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .center, spacing: 16) {
                    DaloResourceIcon(variant: "blue", size: 58)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TRUNG TÂM ĐIỀU KHIỂN")
                            .font(.caption2.weight(.bold))
                            .tracking(0.8)
                            .foregroundStyle(DaloDesign.brand)
                        Text("Dalỏ Multi")
                            .font(.system(size: 30, weight: .bold))
                        HStack(spacing: 7) {
                            Label("\(model.runningCount) đang mở", systemImage: "bolt.fill")
                            Text("•")
                            Text(model.outdatedCount == 0 ? "Mọi clone đã đồng bộ" : "\(model.outdatedCount) clone cần cập nhật")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        NotificationCenter.default.post(name: .daloOpenCommandPalette, object: nil)
                    } label: {
                        Label("Lệnh nhanh", systemImage: "command")
                    }
                    .keyboardShortcut("k", modifiers: .command)

                    Menu {
                        ForEach(WindowLayoutMode.allCases) { mode in
                            Button { Task { await model.arrangeWindows(mode) } } label: {
                                Label(mode.label, systemImage: mode.icon)
                            }
                        }
                        Divider()
                        Button("Lưu bố cục hiện tại") { Task { await model.saveWindowWorkspace() } }
                        Button("Khôi phục bố cục") { Task { await model.restoreWindowWorkspace() } }
                    } label: {
                        Label("Cửa sổ", systemImage: "rectangle.3.group")
                    }

                    Button {
                        showAdd = true
                    } label: {
                        Label("Thêm tài khoản", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(18)
                .daloSurface(radius: DaloDesign.radiusLarge, borderColor: DaloDesign.brand.opacity(0.20))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 12)], spacing: 12) {
                    DaloMetricCardV12(title: "Tài khoản", value: "\(model.accounts.count + 1)", icon: "person.2.fill", detail: "1 gốc + \(model.accounts.count) clone", tint: DaloDesign.brand)
                    DaloMetricCardV12(title: "Đang mở", value: "\(model.runningCount)", icon: "bolt.fill", detail: "RAM \(totalRAM)", tint: DaloDesign.success)
                    DaloMetricCardV12(title: "Cần cập nhật", value: "\(model.outdatedCount)", icon: "arrow.triangle.2.circlepath", detail: model.outdatedCount == 0 ? "Đã đồng bộ" : "Mở Update Center", tint: model.outdatedCount == 0 ? DaloDesign.success : DaloDesign.warning)
                    DaloMetricCardV12(title: "Workspace", value: "\(model.groups.count)", icon: "rectangle.3.group.fill", detail: "Mở theo nhóm", tint: Color(nsColor: .systemPurple))
                }

                if model.outdatedCount > 0 {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(model.outdatedCount) clone đang khác phiên bản Zalo gốc")
                                .font(.headline)
                            Text("Safe rebuild giữ data/session, tên và icon; clone đang chạy không bị tự tắt.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Xem cập nhật") { onNavigate(.updates) }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(14)
                    .background(DaloDesign.warning.opacity(0.10), in: RoundedRectangle(cornerRadius: DaloDesign.radiusMedium, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: DaloDesign.radiusMedium, style: .continuous).stroke(DaloDesign.warning.opacity(0.30)))
                }

                HStack(spacing: 10) {
                    DaloSearchFieldV12(text: $search, focused: $searchFocused)
                        .frame(maxWidth: 440)

                    Picker("Sắp xếp", selection: $sortModeRaw) {
                        ForEach(AccountSortMode.allCases) { mode in Text(mode.label).tag(mode.rawValue) }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 170)

                    Picker("Hiển thị", selection: $displayModeRaw) {
                        ForEach(DashboardDisplayMode.allCases) { mode in
                            Label(mode.label, systemImage: mode.icon).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)

                    Button { showOrder = true } label: { Image(systemName: "arrow.up.arrow.down") }
                        .buttonStyle(.bordered)
                        .help("Sắp thứ tự")
                        .accessibilityLabel("Sắp thứ tự tài khoản")
                    Button { Task { await model.refresh(showError: true) } } label: { Image(systemName: "arrow.clockwise") }
                        .buttonStyle(.bordered)
                        .help("Làm mới")
                        .accessibilityLabel("Làm mới trạng thái tài khoản")
                    Spacer()
                }
                .padding(10)
                .daloSurface(radius: 13)

                if displayMode == .compact {
                    VStack(spacing: 8) {
                        CompactOriginalRowV12()
                        ForEach(shownAccounts) { account in CompactCloneRowV12(account: account) }
                    }
                } else {
                    OriginalCard()

                    if !favorites.isEmpty && search.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            DaloSectionTitle(title: "Yêu thích", subtitle: "Tài khoản bạn dùng thường xuyên", icon: "star.fill")
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 310), spacing: 14)], spacing: 14) {
                                ForEach(favorites) { account in CloneCard(account: account) }
                            }
                        }
                    }

                    if !regulars.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            if !favorites.isEmpty && search.isEmpty {
                                DaloSectionTitle(title: "Tất cả clone", subtitle: "Các phiên Zalo độc lập còn lại", icon: "square.on.square")
                            }
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 310), spacing: 14)], spacing: 14) {
                                ForEach(regulars) { account in CloneCard(account: account) }
                            }
                        }
                    }
                }

                if !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && shownAccounts.isEmpty && !model.accounts.isEmpty {
                    ContentUnavailableView {
                        Label("Không tìm thấy tài khoản", systemImage: "magnifyingglass")
                    } description: {
                        Text("Không có tên, ghi chú hoặc clone ID nào khớp “\(search)”.")
                    } actions: {
                        Button("Xóa tìm kiếm") { search = "" }
                    }
                    .frame(minHeight: 180)
                }

                if model.accounts.isEmpty {
                    ContentUnavailableView {
                        Label("Chưa có clone", systemImage: "square.on.square")
                    } description: {
                        Text("Zalo gốc vẫn dùng bình thường. Tạo clone đầu tiên khi bạn cần thêm một tài khoản độc lập.")
                    } actions: {
                        Button("Tạo clone đầu tiên") { showAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(minHeight: 260)
                }

                HStack {
                    Button { Task { await model.openAll() } } label: { Label("Mở tất cả", systemImage: "play.rectangle.on.rectangle") }
                    Button { Task { await model.quitAllClones() } } label: { Label("Tắt tất cả clone", systemImage: "stop.circle") }
                    Button { Task { await model.openNextAvailable() } } label: { Label("Mở account tiếp theo", systemImage: "forward.end") }
                    Spacer()
                    Label(
                        "Làm mới \(model.lastRefresh.formatted(date: .omitted, time: .standard))" + (autoRefresh ? " · tự động" : " · thủ công"),
                        systemImage: autoRefresh ? "arrow.clockwise.circle.fill" : "pause.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(12)
                .daloSurface(radius: 12)
            }
            .padding(DaloDesign.pagePadding)
            .animation(reduceMotion ? nil : .easeInOut(duration: DaloDesign.motionStandard), value: model.accounts)
        }
        .onAppear {
            Task { await model.refresh(); await model.autoRepairStoppedIfNeeded() }
        }
        .task(id: refreshSeconds) {
            while !Task.isCancelled {
                if autoRefresh {
                    await model.refresh()
                    await model.autoRepairStoppedIfNeeded()
                }
                let seconds = max(2.0, refreshSeconds)
                do {
                    try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                } catch {
                    break
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .daloFocusSearch)) { _ in searchFocused = true }
        .onReceive(NotificationCenter.default.publisher(for: .daloOpenCloneWizard)) { _ in showAdd = true }
        .sheet(isPresented: $showAdd) { CloneWizardSheet().environmentObject(model) }
        .sheet(isPresented: $showOrder) { OrderSheet().environmentObject(model) }
    }
}

struct UpdateCenterV12: View {
    @EnvironmentObject var model: AppModel

    private var outdated: [ZaloAccount] { model.accounts.filter(\.needsUpdate) }
    private var stopped: [ZaloAccount] { outdated.filter { !$0.isRunning } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    DaloPageHeader(title: "Cập nhật clone", subtitle: "Đồng bộ application bundle với Zalo gốc mà không đụng profile.", icon: "arrow.triangle.2.circlepath")
                    Spacer()
                    if !stopped.isEmpty {
                        Button("Cập nhật \(stopped.count) clone đã tắt") { Task { await model.updateAllStopped() } }
                            .buttonStyle(.borderedProminent)
                    }
                }

                GroupBox {
                    HStack(spacing: 14) {
                        ZaloAppIcon()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nguồn: Zalo gốc").font(.headline)
                            Text("Phiên bản \(model.original.version)").foregroundStyle(.secondary)
                        }
                        Spacer()
                        Label("Nguồn clone", systemImage: "checkmark.seal.fill").foregroundStyle(.green)
                    }
                    .padding(6)
                }

                if outdated.isEmpty {
                    ContentUnavailableView("Mọi clone đã đồng bộ", systemImage: "checkmark.circle.fill", description: Text("Không có clone nào cần rebuild theo Zalo gốc hiện tại."))
                        .frame(minHeight: 360)
                } else {
                    VStack(spacing: 10) {
                        ForEach(outdated) { account in
                            HStack(spacing: 12) {
                                DaloResourceIcon(variant: account.iconVariant, size: 44)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(account.name).font(.headline)
                                    Text("Clone \(account.version) → Zalo gốc \(account.sourceVersion)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if account.isRunning {
                                    Label("Đang chạy", systemImage: "bolt.fill")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.orange)
                                } else {
                                    Label("Sẵn sàng", systemImage: "checkmark.circle")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.green)
                                }
                                Button("Cập nhật") { Task { await model.updateClone(account) } }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(account.isRunning)
                            }
                            .padding(14)
                            .daloSurface()
                        }
                    }
                }

                GroupBox("Safe rebuild") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Build clone mới trong thư mục tạm trước", systemImage: "checkmark.circle.fill")
                        Label("Code-sign và kiểm tra trước khi thay bundle cũ", systemImage: "checkmark.circle.fill")
                        Label("Bundle cũ được giữ làm rollback cho tới khi swap thành công", systemImage: "arrow.uturn.backward.circle.fill")
                        Label("Không copy password, token hoặc Keychain", systemImage: "lock.shield.fill")
                    }
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 5)
                }
            }
            .padding(DaloDesign.pagePadding)
        }
        .onAppear { Task { await model.refresh(showError: true) } }
    }
}

struct ActivityCenterV12: View {
    @EnvironmentObject var model: AppModel

    private var ramText: String { String(format: "%.1f GB", Double(model.totalRSSKB) / 1024.0 / 1024.0) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    DaloPageHeader(title: "Hoạt động", subtitle: "Tài nguyên đang dùng và lịch sử thao tác của Dalỏ.", icon: "waveform.path.ecg")
                    Spacer()
                    if !model.activity.isEmpty {
                        Button("Xóa lịch sử") { model.clearActivity() }
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 12)], spacing: 12) {
                    DaloMetricCardV12(title: "Đang mở", value: "\(model.runningCount)", icon: "bolt.fill", tint: DaloDesign.success)
                    DaloMetricCardV12(title: "Tổng RAM", value: ramText, icon: "memorychip", tint: DaloDesign.brand)
                    DaloMetricCardV12(title: "Sự kiện", value: "\(model.activity.count)", icon: "clock.arrow.circlepath", tint: Color(nsColor: .systemPurple))
                }

                if model.runningCount > 0 {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tài nguyên").font(.headline)
                        if model.original.isRunning {
                            HStack {
                                ZaloAppIcon().scaleEffect(0.65).frame(width: 36, height: 36)
                                Text("Zalo gốc")
                                Spacer()
                                ProcessMetrics(pid: model.original.pid, rssKB: model.original.rssKB, elapsed: model.original.elapsed)
                            }
                            .padding(10)
                            .daloSurface(radius: 11)
                        }
                        ForEach(model.accounts.filter(\.isRunning)) { account in
                            HStack {
                                DaloResourceIcon(variant: account.iconVariant, size: 36)
                                Text(account.name)
                                Spacer()
                                ProcessMetrics(pid: account.pid, rssKB: account.rssKB, elapsed: account.elapsed)
                            }
                            .padding(10)
                            .daloSurface(radius: 11)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Gần đây").font(.headline)
                    if model.activity.isEmpty {
                        ContentUnavailableView("Chưa có hoạt động", systemImage: "clock", description: Text("Các thao tác mở, tắt, update, repair và thay đổi cấu hình sẽ xuất hiện ở đây."))
                            .frame(minHeight: 260)
                    } else {
                        ForEach(model.activity) { entry in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: entry.kind == "error" ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                    .foregroundStyle(entry.kind == "error" ? Color.red : Color.accentColor)
                                    .frame(width: 22)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(entry.title).font(.headline)
                                    Text(entry.detail).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(entry.date.formatted(date: .omitted, time: .shortened))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(12)
                            .daloSurface(radius: 12)
                        }
                    }
                }
            }
            .padding(DaloDesign.pagePadding)
        }
        .onAppear { Task { await model.refresh() } }
    }
}

struct WorkspaceCardV12: View {
    @EnvironmentObject var model: AppModel
    let group: LaunchGroup
    let edit: () -> Void

    private var memberNames: [String] {
        var values: [String] = group.includeOriginal ? ["Zalo gốc"] : []
        values += group.cloneIDs.compactMap { id in model.accounts.first(where: { $0.id == id })?.name }
        return values
    }

    private var layoutMode: WindowLayoutMode? {
        guard let raw = group.preferredLayout else { return nil }
        return WindowLayoutMode(rawValue: raw)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "rectangle.3.group.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text(group.name).font(.title3.weight(.semibold))
                    Text("\(memberNames.count) tài khoản" + (layoutMode.map { " · \($0.label)" } ?? ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    Button("Sửa workspace", action: edit)
                    Menu("Layout mặc định") {
                        Button("Không tự sắp") { model.setGroupLayout(group, mode: nil) }
                        ForEach(WindowLayoutMode.allCases) { mode in
                            Button(mode.label) { model.setGroupLayout(group, mode: mode) }
                        }
                    }
                    Divider()
                    Button(role: .destructive) { model.deleteGroup(group) } label: { Label("Xóa", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
                    .menuStyle(.borderlessButton)
                    .accessibilityLabel("Tùy chọn cho workspace \(group.name)")
            }

            Text(memberNames.isEmpty ? "Chưa chọn tài khoản" : memberNames.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Spacer(minLength: 4)
            HStack {
                Button { Task { await model.openWorkspace(group) } } label: { Label("Mở workspace", systemImage: "play.fill") }
                    .buttonStyle(.borderedProminent)
                Button { Task { await model.quitGroup(group) } } label: { Image(systemName: "stop.fill") }
                    .buttonStyle(.bordered)
                    .help("Tắt các tài khoản trong \(group.name)")
                    .accessibilityLabel("Tắt workspace \(group.name)")
                Spacer()
            }
        }
        .padding(17)
        .frame(minHeight: 170)
        .daloSurface(radius: 16)
    }
}

struct WorkspaceViewV12: View {
    @EnvironmentObject var model: AppModel
    @State private var showEditor = false
    @State private var editing: LaunchGroup?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    DaloPageHeader(title: "Không gian làm việc", subtitle: "Mở một nhóm tài khoản và sắp cửa sổ theo một thao tác.", icon: "rectangle.3.group.fill")
                    Spacer()
                    Button { editing = nil; showEditor = true } label: { Label("Tạo workspace", systemImage: "plus") }
                        .buttonStyle(.borderedProminent)
                }

                HStack(spacing: 10) {
                    ForEach(WindowLayoutMode.allCases) { mode in
                        Button { Task { await model.arrangeWindows(mode) } } label: { Label(mode.label, systemImage: mode.icon) }
                    }
                    Divider().frame(height: 22)
                    Button("Lưu vị trí") { Task { await model.saveWindowWorkspace() } }
                    Button("Khôi phục") { Task { await model.restoreWindowWorkspace() } }
                    Spacer()
                }
                .padding(10)
                .daloSurface(radius: 12)

                if model.groups.isEmpty {
                    ContentUnavailableView {
                        Label("Chưa có workspace", systemImage: "rectangle.3.group")
                    } description: {
                        Text("Ví dụ WORK, SALES hoặc CSKH. Mỗi workspace có thể mở một nhóm Zalo và tự sắp cửa sổ.")
                    } actions: {
                        Button("Tạo workspace") { editing = nil; showEditor = true }.buttonStyle(.borderedProminent)
                    }
                    .frame(minHeight: 420)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 310), spacing: 14)], spacing: 14) {
                        ForEach(model.groups) { group in
                            WorkspaceCardV12(group: group) { editing = group; showEditor = true }
                        }
                    }
                }

                Text("Sắp xếp cửa sổ cần quyền Accessibility của macOS. Dalỏ chỉ thay đổi vị trí/kích thước cửa sổ, không đọc nội dung Zalo.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(DaloDesign.pagePadding)
        }
        .sheet(isPresented: $showEditor) { GroupEditorSheet(existing: editing).environmentObject(model) }
    }
}

struct SettingsV12: View {
    @EnvironmentObject var model: AppModel
    @AppStorage("autoRefresh") private var autoRefresh = true
    @AppStorage("showStatusBadges") private var showStatusBadges = true
    @AppStorage("showMenuBar") private var showMenuBar = true
    @AppStorage("confirmDelete") private var confirmDelete = true
    @AppStorage("autoRepairStopped") private var autoRepairStopped = false
    @AppStorage("dashboardDisplayModeV12") private var displayModeRaw = DashboardDisplayMode.cards.rawValue
    @AppStorage("refreshSecondsV12") private var refreshSeconds = 5.0
    @AppStorage("hasCompletedOnboardingV12") private var completedOnboarding = false
    @State private var tab = "General"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                DaloPageHeader(title: "Cài đặt", subtitle: "Tùy chỉnh Dalỏ mà không sửa Zalo gốc.", icon: "gearshape.fill")

                Picker("Mục", selection: $tab) {
                    Text("Chung").tag("General")
                    Text("Tài khoản").tag("Accounts")
                    Text("Giao diện").tag("Appearance")
                    Text("Nâng cao").tag("Advanced")
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 520)

                if tab == "General" {
                    GroupBox("Hoạt động nền") {
                        VStack(alignment: .leading, spacing: 13) {
                            Toggle("Tự làm mới trạng thái", isOn: $autoRefresh)
                            HStack {
                                Text("Chu kỳ làm mới")
                                Spacer()
                                Picker("Chu kỳ", selection: $refreshSeconds) {
                                    Text("2 giây").tag(2.0)
                                    Text("5 giây").tag(5.0)
                                    Text("10 giây").tag(10.0)
                                }.labelsHidden().frame(width: 120)
                            }
                            Toggle("Giữ Dalỏ trên menu bar", isOn: $showMenuBar)
                        }.padding(.vertical, 5)
                    }
                } else if tab == "Accounts" {
                    GroupBox("Clone") {
                        VStack(alignment: .leading, spacing: 13) {
                            Toggle("Tự update clone đã tắt khi Zalo gốc đổi phiên bản", isOn: $autoRepairStopped)
                            Toggle("Xác nhận trước khi xóa clone", isOn: $confirmDelete)
                            Text("Auto-update không tự kill clone đang chạy. Safe rebuild giữ bundle cũ cho tới khi bản mới swap thành công.")
                                .font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical, 5)
                    }
                    GroupBox("Backup cấu hình") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Backup chỉ gồm tên/ghi chú/favorite/group/thứ tự và setting Dalỏ; không chứa tin nhắn, password, token hoặc session.")
                                .font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Button("Xuất cấu hình…") { model.exportConfiguration() }
                                Button("Nhập cấu hình…") { Task { await model.importConfiguration() } }
                            }
                        }.padding(.vertical, 5)
                    }
                } else if tab == "Appearance" {
                    GroupBox("Dashboard") {
                        VStack(alignment: .leading, spacing: 13) {
                            Picker("Kiểu hiển thị", selection: $displayModeRaw) {
                                ForEach(DashboardDisplayMode.allCases) { mode in Text(mode.label).tag(mode.rawValue) }
                            }
                            .pickerStyle(.segmented)
                            Toggle("Hiển thị badge trạng thái", isOn: $showStatusBadges)
                            Text("Logo và Dalo icon family được khóa theo bộ asset hiện tại; Dalỏ không tự resize/recolor artwork.")
                                .font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical, 5)
                    }
                } else {
                    GroupBox("Bảo trì") {
                        VStack(alignment: .leading, spacing: 11) {
                            Button("Repair LaunchServices") { Task { await model.repairRegistration() } }
                            Button("Export diagnostic report") { Task { await model.exportDiagnostics() } }
                            Button("Mở logs") { Task { await model.openLogs() } }
                            Button("Hiện onboarding lần sau") { completedOnboarding = false }
                        }.padding(.vertical, 5)
                    }
                    GroupBox("Quyền riêng tư") {
                        VStack(alignment: .leading, spacing: 7) {
                            Label("Không đọc nội dung tin nhắn", systemImage: "checkmark.shield.fill")
                            Label("Không copy credential / token / Keychain", systemImage: "checkmark.shield.fill")
                            Label("Window layout chỉ dùng Accessibility để di chuyển cửa sổ", systemImage: "checkmark.shield.fill")
                        }.foregroundStyle(.secondary).padding(.vertical, 5)
                    }
                }
            }
            .padding(DaloDesign.pagePadding)
            .frame(maxWidth: 840, alignment: .leading)
        }
    }
}

struct OnboardingV12: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboardingV12") private var completed = false
    @State private var step = 0

    private let pages: [(String, String, String)] = [
        ("Chào mừng đến Dalỏ", "Quản lý nhiều Zalo độc lập bằng dashboard native, nhưng vẫn giữ Zalo gốc nguyên vẹn.", "sparkles"),
        ("Nhanh hơn mỗi ngày", "Dùng ⌘K cho lệnh nhanh, Workspace để mở nhóm tài khoản, và bố cục Grid/Split để sắp cửa sổ.", "command"),
        ("An toàn khi Zalo update", "Update Center dùng safe rebuild. Dalỏ không đọc tin nhắn và không sao chép mật khẩu, token hay Keychain.", "checkmark.shield.fill")
    ]

    var body: some View {
        VStack(spacing: 24) {
            DaloResourceIcon(variant: "blue", size: 92)
            Image(systemName: pages[step].2)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            Text(pages[step].0)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text(pages[step].1)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 480)
                .lineSpacing(4)

            HStack(spacing: 7) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == step ? Color.accentColor : Color.secondary.opacity(0.22))
                        .frame(width: index == step ? 24 : 8, height: 8)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Bước \(step + 1) trên \(pages.count)")

            HStack {
                if step > 0 { Button("Quay lại") { step -= 1 } }
                Spacer()
                if step < pages.count - 1 {
                    Button("Tiếp tục") { step += 1 }.buttonStyle(.borderedProminent)
                } else {
                    Button("Bắt đầu") {
                        completed = true
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(34)
        .frame(width: 620, height: 500)
        .interactiveDismissDisabled()
    }
}

struct CommandPaletteV12: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let navigate: (SidebarPage) -> Void
    @State private var query = ""
    @FocusState private var focused: Bool

    private func matches(_ text: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return q.isEmpty || text.lowercased().contains(q)
    }

    private var wantsQuit: Bool {
        let q = query.lowercased()
        return q.contains("tắt") || q.contains("quit") || q.contains("stop")
    }

    private var matchingAccounts: [ZaloAccount] {
        model.accounts.filter { matches($0.name + " " + $0.note + " \($0.id)") }
    }

    private var hasMatchingCommand: Bool {
        [
            "thêm tài khoản new clone", "mở tất cả open all", "tắt clone quit all",
            "grid lưới cửa sổ", "update cập nhật", "health sức khỏe repair",
            "activity hoạt động ram"
        ].contains(where: matches)
    }

    private var hasAnyResult: Bool {
        hasMatchingCommand || matches("zalo gốc original") || !matchingAccounts.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "command").foregroundStyle(.secondary)
                TextField("Gõ lệnh hoặc tên tài khoản…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($focused)
                Text("⌘K").font(.caption.monospaced()).foregroundStyle(.tertiary)
            }
            .padding(16)
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if matches("thêm tài khoản new clone") {
                        paletteButton("Thêm tài khoản", icon: "plus.circle.fill", detail: "Tạo clone mới") {
                            dismiss(); NotificationCenter.default.post(name: .daloOpenCloneWizard, object: nil)
                        }
                    }
                    if matches("mở tất cả open all") {
                        paletteButton("Mở tất cả", icon: "play.rectangle.on.rectangle", detail: "Zalo gốc + clone") { dismiss(); Task { await model.openAll() } }
                    }
                    if matches("tắt clone quit all") {
                        paletteButton("Tắt tất cả clone", icon: "stop.circle", detail: "Giữ Zalo gốc") { dismiss(); Task { await model.quitAllClones() } }
                    }
                    if matches("grid lưới cửa sổ") {
                        paletteButton("Sắp cửa sổ dạng lưới", icon: "square.grid.2x2", detail: "Cần Accessibility") { dismiss(); Task { await model.arrangeWindows(.grid) } }
                    }
                    if matches("update cập nhật") {
                        paletteButton("Mở Update Center", icon: "arrow.triangle.2.circlepath", detail: "Kiểm tra clone lệch phiên bản") { dismiss(); navigate(.updates) }
                    }
                    if matches("health sức khỏe repair") {
                        paletteButton("Mở Health Check", icon: "heart.text.square", detail: "Kiểm tra clone") { dismiss(); navigate(.health) }
                    }
                    if matches("activity hoạt động ram") {
                        paletteButton("Mở Hoạt động", icon: "waveform.path.ecg", detail: "RAM, uptime và lịch sử") { dismiss(); navigate(.activity) }
                    }

                    Text("Tài khoản")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.top, 8)
                    if matches("zalo gốc original") {
                        paletteButton("Zalo gốc", icon: "message.fill", detail: model.original.isRunning ? "Đang mở" : "Đã tắt") { dismiss(); Task { await model.openOriginal() } }
                    }
                    ForEach(matchingAccounts) { account in
                            Button {
                                dismiss()
                                Task {
                                    if wantsQuit && account.isRunning { await model.quitClone(account) }
                                    else { await model.openClone(account) }
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    DaloResourceIcon(variant: account.iconVariant, size: 32)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(account.name).font(.headline)
                                        Text((wantsQuit && account.isRunning ? "Tắt · " : "") + (account.note.isEmpty ? "Clone #\(account.id)" : account.note)).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Circle().fill(account.isRunning ? Color.green : Color.secondary.opacity(0.35)).frame(width: 7, height: 7)
                                }
                                .padding(9)
                            }
                            .buttonStyle(DaloPressableRowStyle())
                            .accessibilityHint(wantsQuit && account.isRunning ? "Tắt tài khoản này" : "Mở hoặc đưa tài khoản này ra trước")
                    }

                    if !hasAnyResult {
                        ContentUnavailableView(
                            "Không có kết quả",
                            systemImage: "magnifyingglass",
                            description: Text("Thử tên tài khoản hoặc lệnh khác.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 180)
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 620, height: 520)
        .onAppear { focused = true }
    }

    @ViewBuilder
    private func paletteButton(_ title: String, icon: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: icon).frame(width: 28).foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "return").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(9)
            .contentShape(Rectangle())
        }
        .buttonStyle(DaloPressableRowStyle())
    }
}

struct MenuBarViewV12: View {
    @EnvironmentObject var model: AppModel
    @AppStorage("refreshSecondsV12") private var refreshSeconds = 5.0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                DaloResourceIcon(variant: "blue", size: 36)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Dalỏ Multi").font(.headline)
                    Text("\(model.runningCount) đang mở · " + String(format: "%.1f GB RAM", Double(model.totalRSSKB) / 1024.0 / 1024.0))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            Divider()

            Button { Task { await model.openOriginal() } } label: {
                HStack {
                    Circle().fill(model.original.isRunning ? Color.green : Color.secondary.opacity(0.4)).frame(width: 7, height: 7)
                    Text("Zalo gốc")
                    Spacer()
                    Text(model.original.isRunning ? "Mở" : "Chạy").foregroundStyle(.secondary)
                }
            }.buttonStyle(.plain)

            ForEach(model.accounts.sorted(by: { $0.id < $1.id })) { account in
                Button { Task { await model.openClone(account) } } label: {
                    HStack {
                        DaloResourceIcon(variant: account.iconVariant, size: 22)
                        Circle().fill(account.isRunning ? Color.green : Color.secondary.opacity(0.4)).frame(width: 7, height: 7)
                        Text(account.name).lineLimit(1).help(account.name)
                        Spacer()
                        if account.needsUpdate { Image(systemName: "arrow.triangle.2.circlepath").foregroundStyle(.orange) }
                    }
                }.buttonStyle(.plain)
            }

            if !model.groups.isEmpty {
                Divider()
                Text("Workspace").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                ForEach(model.groups.prefix(5)) { group in
                    Button { Task { await model.openWorkspace(group) } } label: { Label(group.name, systemImage: "rectangle.3.group") }
                }
            }

            Divider()
            HStack {
                Menu("Sắp cửa sổ") {
                    ForEach(WindowLayoutMode.allCases) { mode in
                        Button(mode.label) { Task { await model.arrangeWindows(mode) } }
                    }
                }
                Spacer()
                Button("Dashboard") { model.openMainWindow() }.buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .frame(width: 390)
        .onAppear { Task { await model.refresh() } }
        .task(id: refreshSeconds) {
            while !Task.isCancelled {
                do { try await Task.sleep(nanoseconds: UInt64(max(3.0, refreshSeconds) * 1_000_000_000)) } catch { break }
                await model.refresh()
            }
        }
    }
}


struct RootView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection: SidebarPage? = .dashboard
    @State private var showCommandPalette = false
    @State private var showOnboarding = false
    @AppStorage("hasCompletedOnboardingV12") private var completedOnboarding = false

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    DaloResourceIcon(variant: "blue", size: 38)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Dalỏ Multi")
                            .font(.headline)
                        Text("v1.3 · macOS")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                List(selection: $selection) {
                    Section("Làm việc") {
                        ForEach([SidebarPage.dashboard, .groups, .activity, .updates]) { page in
                            Label(page.rawValue, systemImage: page.icon).tag(page)
                        }
                    }
                    Section("Hệ thống") {
                        ForEach([SidebarPage.startup, .health, .diagnostics, .settings]) { page in
                            Label(page.rawValue, systemImage: page.icon).tag(page)
                        }
                    }
                }
                .listStyle(.sidebar)

                VStack(spacing: 8) {
                    Button {
                        showCommandPalette = true
                    } label: {
                        HStack(spacing: 8) {
                            Label("Lệnh nhanh", systemImage: "command")
                            Spacer()
                            Text("⌘K")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(DaloDesign.brand.opacity(0.09), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .accessibilityHint("Mở danh sách lệnh và tài khoản")

                    HStack(spacing: 6) {
                        Circle()
                            .fill(model.runningCount > 0 ? DaloDesign.success : Color.secondary)
                            .frame(width: 7, height: 7)
                        Text("\(model.runningCount) đang mở")
                        Spacer()
                        if model.outdatedCount > 0 {
                            Label("\(model.outdatedCount)", systemImage: "arrow.triangle.2.circlepath")
                                .foregroundStyle(DaloDesign.warning)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(model.runningCount) tài khoản đang mở, \(model.outdatedCount) clone cần cập nhật")
                }
                .padding(10)
                .overlay(alignment: .top) { Divider() }
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } detail: {
            switch selection ?? .dashboard {
            case .dashboard:
                OverviewV12 { selection = $0 }
            case .groups:
                WorkspaceViewV12()
            case .activity:
                ActivityCenterV12()
            case .updates:
                UpdateCenterV12()
            case .startup:
                StartupView()
            case .health:
                HealthView()
            case .diagnostics:
                DiagnosticsView()
            case .settings:
                SettingsV12()
            }
        }
        .overlay {
            if model.isBusy {
                ZStack {
                    Color.black.opacity(0.06).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView().controlSize(.large)
                        Text("Dalỏ đang xử lý…").font(.headline)
                        Text("Bạn có thể tiếp tục khi thao tác hoàn tất.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 22)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(radius: 18)
                }
                .transition(reduceMotion ? .identity : .opacity)
            }
        }
        .overlay(alignment: .topTrailing) {
            if let notice = model.noticeMessage {
                Label(notice, systemImage: "checkmark.circle.fill")
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(radius: 8)
                    .padding(16)
                    .transition(reduceMotion ? .identity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: DaloDesign.motionStandard), value: model.isBusy)
        .animation(reduceMotion ? nil : .easeInOut(duration: DaloDesign.motionStandard), value: model.noticeMessage)
        .task(id: model.noticeMessage) {
            guard model.noticeMessage != nil else { return }
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            model.noticeMessage = nil
        }
        .alert("Dalỏ gặp lỗi", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("Sao chép lỗi") {
                if let message = model.errorMessage {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(message, forType: .string)
                }
            }
            Button("Mở Chẩn đoán") {
                model.errorMessage = nil
                selection = .diagnostics
            }
            Button("Đóng", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text((model.errorMessage ?? "") + "\n\n" + daloFriendlySuggestion(for: model.errorMessage ?? ""))
        }
        .sheet(isPresented: $showCommandPalette) {
            CommandPaletteV12 { page in
                selection = page
            }
            .environmentObject(model)
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingV12()
                .environmentObject(model)
        }
        .onAppear {
            if !completedOnboarding { showOnboarding = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .daloOpenCommandPalette)) { _ in
            showCommandPalette = true
        }
        .tint(DaloDesign.brand)
        .frame(minWidth: 980, minHeight: 680)
    }
}

struct DaloCommands: Commands {
    @ObservedObject var model: AppModel

    private func key(for number: Int) -> KeyEquivalent {
        KeyEquivalent(Character(String(number)))
    }

    var body: some Commands {
        CommandMenu("Dalỏ") {
            Button("Lệnh nhanh…") {
                NotificationCenter.default.post(name: .daloOpenCommandPalette, object: nil)
            }
            .keyboardShortcut("k", modifiers: .command)

            Button("Tìm tài khoản") {
                NotificationCenter.default.post(name: .daloFocusSearch, object: nil)
            }
            .keyboardShortcut("f", modifiers: .command)

            Button("Tạo clone mới") {
                NotificationCenter.default.post(name: .daloOpenCloneWizard, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Divider()

            Button("Mở tất cả") { Task { await model.openAll() } }
                .keyboardShortcut("a", modifiers: [.command, .shift])
            Button("Tắt tất cả clone") { Task { await model.quitAllClones() } }
                .keyboardShortcut("q", modifiers: [.command, .shift])
            Button("Mở account tiếp theo") { Task { await model.openNextAvailable() } }
                .keyboardShortcut("n", modifiers: [.command, .option])

            Menu("Sắp cửa sổ") {
                ForEach(WindowLayoutMode.allCases) { mode in
                    Button(mode.label) { Task { await model.arrangeWindows(mode) } }
                }
                Divider()
                Button("Lưu bố cục") { Task { await model.saveWindowWorkspace() } }
                Button("Khôi phục bố cục") { Task { await model.restoreWindowWorkspace() } }
            }

            Divider()
            Button("Zalo gốc") { Task { await model.openOriginal() } }
                .keyboardShortcut("1", modifiers: .command)
            ForEach(Array(model.accounts.prefix(8).enumerated()), id: \.element.id) { offset, account in
                Button(account.name) { Task { await model.openClone(account) } }
                    .keyboardShortcut(key(for: offset + 2), modifiers: .command)
            }
        }
    }
}

@main
struct DaloMultiApp: App {
    @StateObject private var model = AppModel()
    @AppStorage("showMenuBar") private var showMenuBar = true

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1220, height: 800)
        .commands { DaloCommands(model: model) }

        MenuBarExtra("Dalỏ Multi", systemImage: "message.fill", isInserted: $showMenuBar) {
            MenuBarViewV12()
                .environmentObject(model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsV12()
                .environmentObject(model)
        }
    }
}
