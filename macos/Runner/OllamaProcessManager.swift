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
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appSupportDir = supportDir.appendingPathComponent("OllamaSidecar/ollama-bin/ollama").path
        
        if FileManager.default.fileExists(atPath: appSupportDir) {
            return appSupportDir
        }
        
        return appSupportDir
    }
    
    var modelsDirectory: String {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appSupportDir = supportDir.appendingPathComponent("OllamaSidecar/models")
        return appSupportDir.path
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
            try ensureModelsDirectoryExists()
        } catch {
            print("OllamaProcessManager: error ensuring models dir: \(error)")
            isStarting = false
            throw error
        }
        
        let executableURL = URL(fileURLWithPath: ollamaBinaryPath)
        
        if !FileManager.default.fileExists(atPath: executableURL.path) {
            isStarting = false
            throw NSError(domain: "OllamaProcessManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ollama binary not found at \(executableURL.path). Please install Ollama first."])
        }
        
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
        let binaryPath = ollamaBinaryPath
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = ["--version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        } catch {
            return "unknown"
        }
        return "unknown"
    }
    
    func installOllama() async -> Bool {
        print("OllamaProcessManager: installOllama called")
        
        let fileManager = FileManager.default
        let installDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("OllamaSidecar/ollama-bin")
        
        do {
            try fileManager.createDirectory(at: installDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("OllamaProcessManager: failed to create install dir: \(error)")
            return false
        }
        
        let downloadURL = URL(string: "https://github.com/ollama/ollama/releases/latest/download/Ollama-darwin.zip")!
        let zipPath = installDir.appendingPathComponent("ollama.zip")
        let binaryPath = installDir.appendingPathComponent("ollama")
        
        do {
            let tempURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                let task = URLSession.shared.downloadTask(with: downloadURL) { tempURL, _, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let tempURL = tempURL else {
                        continuation.resume(throwing: NSError(domain: "OllamaProcessManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Download failed"]))
                        return
                    }
                    continuation.resume(returning: tempURL)
                }
                task.resume()
            }
            
            if fileManager.fileExists(atPath: zipPath.path) {
                try? fileManager.removeItem(at: zipPath)
            }
            try fileManager.moveItem(at: tempURL, to: zipPath)
        } catch {
            print("OllamaProcessManager: download failed: \(error)")
            return false
        }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        task.arguments = ["-o", zipPath.path, "-d", installDir.path]
        do {
            try task.run()
            task.waitUntilExit()
            
            guard task.terminationStatus == 0 else {
                print("OllamaProcessManager: unzip failed")
                try? fileManager.removeItem(at: zipPath)
                return false
            }
        } catch {
            print("OllamaProcessManager: unzip error: \(error)")
            try? fileManager.removeItem(at: zipPath)
            return false
        }
        
        try? fileManager.removeItem(at: zipPath)
        
        do {
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binaryPath.path)
        } catch {
            print("OllamaProcessManager: chmod failed: \(error)")
            return false
        }
        
        print("OllamaProcessManager: installOllama succeeded at \(binaryPath.path)")
        return true
    }
}
