import Foundation
import AppKit

class OllamaProcessManager: NSObject {
    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var outputData: Data = Data()
    private var errorData: Data = Data()
    private var isRunning = false
    private var isStarting = false

    static let shared = OllamaProcessManager()

    private override init() {
        super.init()
    }

    var ollamaBinaryPath: String {
        let bundlePath = Bundle.main.bundlePath
        let bundledBinary = bundlePath + "/Contents/MacOS/ollama"
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appSupportDir = supportDir.appendingPathComponent("OllamaSidecar")
        let runtimeBinary = appSupportDir.appendingPathComponent("ollama").path

        if FileManager.default.fileExists(atPath: bundledBinary) {
            return bundledBinary
        }

        if FileManager.default.fileExists(atPath: runtimeBinary) {
            return runtimeBinary
        }

        return bundledBinary
    }

    var modelsDirectory: String {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appSupportDir = supportDir.appendingPathComponent("OllamaSidecar/models")
        return appSupportDir.path
    }

    func ensureRuntimeBinaryExists() throws {
        let bundlePath = Bundle.main.bundlePath
        let bundledBinary = bundlePath + "/Contents/MacOS/ollama"
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appSupportDir = supportDir.appendingPathComponent("OllamaSidecar")
        let runtimeBinary = appSupportDir.appendingPathComponent("ollama").path

        if FileManager.default.fileExists(atPath: runtimeBinary) {
            return
        }

        if !FileManager.default.fileExists(atPath: bundledBinary) {
            throw NSError(domain: "OllamaProcessManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Ollama binary not found in app bundle at \(bundledBinary)"])
        }

        try FileManager.default.createDirectory(atPath: appSupportDir.path, withIntermediateDirectories: true, attributes: nil)

        try FileManager.default.copyItem(atPath: bundledBinary, toPath: runtimeBinary)

        var isExecutable: ObjCBool = false
        if FileManager.default.isExecutableFile(atPath: runtimeBinary) {
            isExecutable = true
        }
        if !isExecutable.boolValue {
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: runtimeBinary)
        }
    }

    func ensureModelsDirectoryExists() throws {
        let modelsDir = modelsDirectory
        if !FileManager.default.fileExists(atPath: modelsDir) {
            try FileManager.default.createDirectory(atPath: modelsDir, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func startOllama() throws -> Bool {
        if isRunning || isStarting {
            return true
        }

        isStarting = true

        try ensureRuntimeBinaryExists()
        try ensureModelsDirectoryExists()

        let executableURL = URL(fileURLWithPath: ollamaBinaryPath)

        let process = Process()
        process.executableURL = executableURL
        process.arguments = ["serve"]

        let environment = ProcessInfo.processInfo.environment
        var newEnvironment = environment
        newEnvironment["OLLAMA_HOST"] = "127.0.0.1:11434"
        newEnvironment["OLLAMA_MODELS"] = modelsDirectory
        newEnvironment["OLLAMA_ORIGINS"] = "*"
        process.environment = newEnvironment

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        let outputHandle = outputPipe.fileHandleForReading
        let errorHandle = errorPipe.fileHandleForReading

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handleOutputData(_:)),
            name: FileHandle.readCompletionNotification,
            object: outputHandle
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handleErrorData(_:)),
            name: FileHandle.readCompletionNotification,
            object: errorHandle
        )

        outputHandle.readInBackgroundAndNotify()
        errorHandle.readInBackgroundAndNotify()

        process.terminationHandler = { [weak self] process in
            guard let self = self else { return }
            if self.process === process {
                self.isRunning = false
                self.isStarting = false
                self.process = nil
                self.outputPipe = nil
                self.errorPipe = nil
            }
        }

        self.process = process
        self.outputPipe = outputPipe
        self.errorPipe = errorPipe

        try process.run()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.isRunning = process.isRunning
            self.isStarting = false
        }

        return true
    }

    func stopOllama() throws -> Bool {
        if let process = process, isRunning {
            process.terminate()

            if process.isRunning {
                process.interrupt()
            }

            isRunning = false
            self.process = nil
            outputPipe = nil
            errorPipe = nil
            return true
        }

        return false
    }

    func isOllamaRunning() -> Bool {
        if let process = process {
            return process.isRunning
        }
        return isRunning
    }

    func getOllamaLogs() -> String {
        return String(data: outputData, encoding: .utf8) ?? ""
    }

    func getOllamaVersion() -> String {
        return "0.31.1"
    }

    @objc private func handleOutputData(_ notification: Notification) {
        guard let handle = notification.object as? FileHandle else { return }
        let data = handle.availableData
        guard !data.isEmpty else { return }
        outputData.append(data)
        handle.readInBackgroundAndNotify()
    }

    @objc private func handleErrorData(_ notification: Notification) {
        guard let handle = notification.object as? FileHandle else { return }
        let data = handle.availableData
        guard !data.isEmpty else { return }
        errorData.append(data)
        handle.readInBackgroundAndNotify()
    }
}