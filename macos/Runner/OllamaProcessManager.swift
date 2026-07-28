import Foundation
import AppKit
import os

class OllamaProcessManager: NSObject {
    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var outputHandle: FileHandle?
    private var errorHandle: FileHandle?
    private var outputData: Data = Data()
    private var errorData: Data = Data()
    private var isRunning = false
    private var isStarting = false
    private let outputQueue = DispatchQueue(label: "ollamaOutputQueue")
    
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
        print("OllamaProcessManager: startOllama called")
        if isRunning || isStarting {
            print("OllamaProcessManager: already running or starting")
            return true
        }
        
        isStarting = true
        
        do {
            try ensureRuntimeBinaryExists()
            try ensureModelsDirectoryExists()
        } catch {
            print("OllamaProcessManager: error ensuring binary/models: \(error)")
            isStarting = false
            throw error
        }
        
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
        
        // Set up readability handlers on a background queue
        outputHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty {
                self?.outputQueue.async {
                    self?.outputData.append(data)
                }
            }
        }
        
        errorHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty {
                self?.outputQueue.async {
                    self?.errorData.append(data)
                }
            }
        }
        
        self.outputHandle = outputHandle
        self.errorHandle = errorHandle
        
        process.terminationHandler = { [weak self] process in
            guard let self = self else { return }
            if self.process === process {
                print("OllamaProcessManager: process terminated")
                self.isRunning = false
                self.isStarting = false
                self.process = nil
                self.outputPipe = nil
                self.errorPipe = nil
                // Clean up readability handlers and handles
                self.outputHandle?.readabilityHandler = nil
                self.errorHandle?.readabilityHandler = nil
                self.outputHandle = nil
                self.errorHandle = nil
            }
        }
        
        self.process = process
        self.outputPipe = outputPipe
        self.errorPipe = errorPipe
        
        do {
            try process.run()
            print("OllamaProcessManager: process launched successfully")
        } catch {
            print("OllamaProcessManager: failed to launch process: \(error)")
            // Clean up on failure
            outputHandle.readabilityHandler = nil
            errorHandle.readabilityHandler = nil
            self.outputHandle = nil
            self.errorHandle = nil
            self.process = nil
            self.outputPipe = nil
            self.errorPipe = nil
            self.isStarting = false
            throw error
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.isRunning = process.isRunning
            self.isStarting = false
            print("OllamaProcessManager: after delay, isRunning=\(self.isRunning)")
        }
        
        return true
    }
    
    func stopOllama() throws -> Bool {
        print("OllamaProcessManager: stopOllama called")
        if let process = process, isRunning {
            process.terminate()
            
            if process.isRunning {
                process.interrupt()
            }
            
            isRunning = false
            self.process = nil
            self.outputPipe = nil
            self.errorPipe = nil
            // Remove readability handlers
            outputHandle?.readabilityHandler = nil
            errorHandle?.readabilityHandler = nil
            self.outputHandle = nil
            self.errorHandle = nil
            print("OllamaProcessManager: stopped Ollama")
            return true
        }
        
        print("OllamaProcessManager: stopOllama called but not running")
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
}