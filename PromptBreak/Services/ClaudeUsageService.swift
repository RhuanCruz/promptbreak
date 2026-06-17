import Foundation
import Combine

// Integrates with Claude Code via a status line script. The script writes each
// session's JSON (cost, tokens, rate limits) to ~/.promptbreak/claude/<session>.json.
// We poll those files, aggregate the spend since the last break, and fire a break
// when it crosses the user's goal. The script also chains to any pre-existing
// status line so we don't clobber the user's setup.
@MainActor
final class ClaudeUsageService: ObservableObject {
    @Published var isInstalled: Bool = false
    @Published var tokensSinceLastBreak: Int = 0

    var onGoalReached: (() async -> Void)?

    private let fm = FileManager.default
    private var home: URL { fm.homeDirectoryForCurrentUser }
    private var dataDir: URL { home.appendingPathComponent(".promptbreak/claude") }
    private var scriptURL: URL { home.appendingPathComponent(".promptbreak/claude-statusline.sh") }
    private var settingsURL: URL { home.appendingPathComponent(".claude/settings.json") }
    private var prevCmdBackupURL: URL { home.appendingPathComponent(".promptbreak/prev-statusline.txt") }
    private var statusURL: URL { home.appendingPathComponent(".promptbreak/status.txt") }

    private var timer: Timer?
    private var lastTokensBySession: [String: Int] = [:]
    private var transcriptCache: [String: (mtime: Date, tokens: Int)] = [:]
    private var goal: Int = 100_000

    init() {
        isInstalled = isStatusLinePointingToUs()
    }

    // Regenerate the script on launch so its display always matches the current app version.
    func refreshScriptIfInstalled() {
        guard isInstalled else { return }
        let saved = (try? String(contentsOf: prevCmdBackupURL, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let prev = (saved?.isEmpty == false) ? saved : nil
        try? script(previousCommand: prev).write(to: scriptURL, atomically: true, encoding: .utf8)
        try? fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
    }

    // MARK: - Install / uninstall

    func install() throws {
        try fm.createDirectory(at: dataDir, withIntermediateDirectories: true)

        // Read existing settings + preserve any previous status line to chain into.
        var settings = readSettings()
        var previousCommand: String? = nil
        if let sl = settings["statusLine"] as? [String: Any],
           let cmd = sl["command"] as? String,
           cmd != scriptURL.path, !cmd.isEmpty {
            previousCommand = cmd
            try? cmd.write(to: prevCmdBackupURL, atomically: true, encoding: .utf8)
        } else if let saved = try? String(contentsOf: prevCmdBackupURL, encoding: .utf8),
                  !saved.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            previousCommand = saved.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Write the script.
        try script(previousCommand: previousCommand).write(to: scriptURL, atomically: true, encoding: .utf8)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        // Point the status line at our script.
        settings["statusLine"] = ["type": "command", "command": scriptURL.path, "padding": 0]
        try writeSettings(settings)

        isInstalled = true
    }

    func uninstall() throws {
        var settings = readSettings()
        // Restore the previous command if we have one, else remove our status line.
        if let saved = try? String(contentsOf: prevCmdBackupURL, encoding: .utf8),
           !saved.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            settings["statusLine"] = ["type": "command", "command": saved.trimmingCharacters(in: .whitespacesAndNewlines)]
        } else if let sl = settings["statusLine"] as? [String: Any],
                  (sl["command"] as? String) == scriptURL.path {
            settings.removeValue(forKey: "statusLine")
        }
        try writeSettings(settings)
        try? fm.removeItem(at: scriptURL)
        isInstalled = false
        stopMonitoring()
    }

    // MARK: - Monitoring

    func startMonitoring(goal: Int) {
        self.goal = goal
        timer?.invalidate()
        // Seed baselines so we only count tokens from now on.
        poll(seedOnly: true)
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll(seedOnly: false) }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        try? fm.removeItem(at: statusURL)   // clear the status line progress
    }

    func resetSpend() {
        tokensSinceLastBreak = 0
    }

    private func poll(seedOnly: Bool) {
        guard let files = try? fm.contentsOfDirectory(at: dataDir, includingPropertiesForKeys: nil) else { return }
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
            let sid = (obj["session_id"] as? String) ?? file.lastPathComponent
            guard let transcriptPath = obj["transcript_path"] as? String else { continue }
            let tokens = tokensInTranscript(transcriptPath)

            if let prev = lastTokensBySession[sid] {
                if !seedOnly { tokensSinceLastBreak += max(0, tokens - prev) }
            }
            lastTokensBySession[sid] = tokens
        }

        // Update the status line progress text.
        let text = "🏋️ \(formatTokens(tokensSinceLastBreak)) / \(formatTokens(goal)) tokens"
        try? text.write(to: statusURL, atomically: true, encoding: .utf8)

        if !seedOnly && tokensSinceLastBreak >= goal {
            let cb = onGoalReached
            Task { await cb?() }
        }
    }

    // Sums input/output/cache tokens across the whole session transcript (cumulative).
    // Cached per file modification date so we only re-parse when the transcript grows.
    private func tokensInTranscript(_ path: String) -> Int {
        let mtime = (try? fm.attributesOfItem(atPath: path))?[.modificationDate] as? Date ?? .distantPast
        if let cached = transcriptCache[path], cached.mtime == mtime { return cached.tokens }

        var total = 0
        if let content = try? String(contentsOfFile: path, encoding: .utf8) {
            content.enumerateLines { line, _ in
                guard let data = line.data(using: .utf8),
                      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let message = obj["message"] as? [String: Any],
                      let usage = message["usage"] as? [String: Any] else { return }
                // Exclude cache_read: with prompt caching it re-reads the whole context
                // every turn and would inflate the count to millions in minutes.
                let inp = (usage["input_tokens"] as? Int) ?? 0
                let out = (usage["output_tokens"] as? Int) ?? 0
                let cc = (usage["cache_creation_input_tokens"] as? Int) ?? 0
                total += inp + out + cc
            }
        }
        transcriptCache[path] = (mtime, total)
        return total
    }

    // MARK: - Settings I/O

    private func readSettings() -> [String: Any] {
        guard let data = try? Data(contentsOf: settingsURL),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        return obj
    }

    private func writeSettings(_ dict: [String: Any]) throws {
        try fm.createDirectory(at: settingsURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: settingsURL)
    }

    private func isStatusLinePointingToUs() -> Bool {
        guard let sl = readSettings()["statusLine"] as? [String: Any],
              let cmd = sl["command"] as? String else { return false }
        return cmd == scriptURL.path
    }

    // MARK: - Script

    private func script(previousCommand: String?) -> String {
        // Embed the previous command safely (escape single quotes for bash).
        let prev = (previousCommand ?? "").replacingOccurrences(of: "'", with: "'\\''")
        return """
        #!/bin/bash
        # PromptBreak — Claude Code usage bridge (auto-generated)
        input=$(cat)
        dir="$HOME/.promptbreak/claude"
        mkdir -p "$dir"
        sid=$(printf '%s' "$input" | sed -n 's/.*"session_id":"\\([^"]*\\)".*/\\1/p')
        [ -z "$sid" ] && sid="default"
        printf '%s' "$input" > "$dir/$sid.json"

        PREV='\(prev)'
        STATUS="$HOME/.promptbreak/status.txt"
        if [ -n "$PREV" ]; then
          out=$(printf '%s' "$input" | eval "$PREV")
          if [ -f "$STATUS" ]; then printf '%s · %s' "$out" "$(cat "$STATUS")"; else printf '%s' "$out"; fi
        elif [ -f "$STATUS" ]; then
          cat "$STATUS"
        else
          printf '🏋️  PromptBreak'
        fi
        """
    }
}
