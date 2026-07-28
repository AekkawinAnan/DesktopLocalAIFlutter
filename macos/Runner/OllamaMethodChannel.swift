import Foundation
import FlutterMacOS

class OllamaMethodChannel: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.example.ollama_sidecar",
            binaryMessenger: registrar.messenger
        )
        let instance = OllamaMethodChannel()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startOllama":
            do {
                let started = try OllamaProcessManager.shared.startOllama()
                result(["success": started])
            } catch {
                result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
            }
        case "stopOllama":
            do {
                let stopped = try OllamaProcessManager.shared.stopOllama()
                result(["success": stopped])
            } catch {
                result(FlutterError(code: "STOP_FAILED", message: error.localizedDescription, details: nil))
            }
        case "isOllamaRunning":
            result(["running": OllamaProcessManager.shared.isOllamaRunning()])
        case "getOllamaLogs":
            result(["logs": OllamaProcessManager.shared.getOllamaLogs()])
        case "getOllamaVersion":
            result(["version": OllamaProcessManager.shared.getOllamaVersion()])
        case "getOllamaBinaryPath":
            result(["path": OllamaProcessManager.shared.ollamaBinaryPath])
        case "getModelsDirectory":
            result(["path": OllamaProcessManager.shared.modelsDirectory])
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}