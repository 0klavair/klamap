import Foundation
import Network
import Combine
import UIKit

/// Minimal HTTP/1.1 server using Apple's Network framework. This is intentionally
/// a stub for the Phase 1 of the "Server mode" feature: it answers GET requests
/// with a status HTML page so the user can confirm connectivity from a browser
/// on the same Wi-Fi.
///
/// Phase 2 (next iteration) will add: JSON API endpoints, render-job submission,
/// queue UI, Bonjour-based multi-device discovery, and the full web client.
@MainActor
final class LocalHTTPServer: ObservableObject {

    static let shared = LocalHTTPServer()

    @Published private(set) var isRunning: Bool = false
    @Published private(set) var url: String? = nil
    @Published private(set) var lastError: String? = nil

    private let port: NWEndpoint.Port = 8080
    private var listener: NWListener?
    private var bonjour: NetService?

    func start() {
        guard !isRunning else { return }
        do {
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            let listener = try NWListener(using: params, on: port)
            listener.newConnectionHandler = { [weak self] conn in
                Task { @MainActor in
                    self?.handle(conn)
                }
            }
            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    guard let self = self else { return }
                    switch state {
                    case .ready:
                        self.isRunning = true
                        self.url = self.buildURL()
                        self.lastError = nil
                        self.publishBonjour()
                    case .failed(let err):
                        self.lastError = err.localizedDescription
                        self.isRunning = false
                    case .cancelled:
                        self.isRunning = false
                        self.url = nil
                    default: break
                    }
                }
            }
            listener.start(queue: .main)
            self.listener = listener
        } catch {
            lastError = error.localizedDescription
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        bonjour?.stop()
        bonjour = nil
        isRunning = false
        url = nil
    }

    // MARK: - Bonjour publish (lets other iPhones on the same Wi-Fi discover us)

    private func publishBonjour() {
        let svc = NetService(
            domain: "local.",
            type: "_klamap._tcp.",
            name: UIDevice.current.name,
            port: Int32(port.rawValue)
        )
        svc.publish()
        bonjour = svc
    }

    // MARK: - Connection handling

    private func handle(_ conn: NWConnection) {
        conn.start(queue: .main)
        // Up to 4 MB payload — generous for JSON job submissions including
        // long trajectory arrays.
        conn.receive(minimumIncompleteLength: 1, maximumLength: 4 * 1024 * 1024) { [weak self] data, _, _, _ in
            guard let self = self, let data = data else {
                conn.cancel()
                return
            }
            let request = self.parseRequest(data)
            let response = self.respond(to: request)
            conn.send(content: response, completion: .contentProcessed { _ in
                conn.cancel()
            })
        }
    }

    /// Parsed HTTP request: method + path + body (everything after \r\n\r\n).
    private struct ParsedRequest {
        let method: String
        let path: String
        let body: Data
    }

    private func parseRequest(_ data: Data) -> ParsedRequest {
        // Find the \r\n\r\n separator between headers and body.
        let separator = Data([0x0D, 0x0A, 0x0D, 0x0A])
        let headerEnd = data.range(of: separator)?.lowerBound ?? data.endIndex
        let headerData = data[..<headerEnd]
        let bodyStart = data.index(headerEnd, offsetBy: 4, limitedBy: data.endIndex) ?? data.endIndex
        let body = bodyStart < data.endIndex ? data[bodyStart...] : Data()

        let headerString = String(data: headerData, encoding: .utf8) ?? ""
        let firstLine = headerString.split(separator: "\r\n", maxSplits: 1, omittingEmptySubsequences: true).first ?? ""
        let parts = firstLine.split(separator: " ")
        let method = parts.count >= 1 ? String(parts[0]) : "GET"
        let path = parts.count >= 2 ? String(parts[1]) : "/"
        return ParsedRequest(method: method, path: path, body: Data(body))
    }

    private func respond(to req: ParsedRequest) -> Data {
        // Routing: GET endpoints first, then POST.
        if req.method == "GET" {
            switch req.path {
            case "/", "/index.html":
                return ok(body: htmlIndex(), contentType: "text/html; charset=utf-8")
            case "/status.json":
                return ok(body: #"{"app":"klamap","version":"1.0","status":"running"}"#,
                          contentType: "application/json; charset=utf-8")
            case "/api/info":
                let info = #"{"name":"\#(UIDevice.current.name)","capabilities":["render","tendies"],"protocolVersion":1}"#
                return ok(body: info, contentType: "application/json; charset=utf-8")
            default:
                return notFound()
            }
        }
        if req.method == "POST" {
            switch req.path {
            case "/api/render":
                // Phase 5 stub. The body will be JSON describing a render job:
                // { states: [...], captureSize: {...}, config: {...}, ... }
                // Phase 6 will actually queue this and run ContinuousRenderEngine.
                let payloadSize = req.body.count
                let stub = #"""
                {"status":"accepted","message":"Render endpoint scaffold ready. Phase 6 will execute the job.","payloadBytes":\#(payloadSize)}
                """#
                return ok(status: 202, statusText: "Accepted",
                          body: stub, contentType: "application/json; charset=utf-8")
            default:
                return notFound()
            }
        }
        return methodNotAllowed()
    }

    // MARK: - Response helpers

    private func ok(status: Int = 200, statusText: String = "OK",
                    body: String, contentType: String) -> Data {
        let bodyData = Data(body.utf8)
        let header = """
        HTTP/1.1 \(status) \(statusText)\r\nContent-Type: \(contentType)\r\nContent-Length: \(bodyData.count)\r\nConnection: close\r\n\r\n
        """
        return Data(header.utf8) + bodyData
    }

    private func methodNotAllowed() -> Data {
        let body = "405 Method Not Allowed"
        let bodyData = Data(body.utf8)
        let header = """
        HTTP/1.1 405 Method Not Allowed\r\nContent-Type: text/plain\r\nContent-Length: \(bodyData.count)\r\nConnection: close\r\n\r\n
        """
        return Data(header.utf8) + bodyData
    }

    private func notFound() -> Data {
        let body = "404 Not Found"
        let bodyData = Data(body.utf8)
        let header = """
        HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nContent-Length: \(bodyData.count)\r\nConnection: close\r\n\r\n
        """
        return Data(header.utf8) + bodyData
    }

    private func htmlIndex() -> String {
        let device = UIDevice.current.name
        return """
        <!DOCTYPE html>
        <html lang="fr"><head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>klamap — \(device)</title>
        <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
          background: linear-gradient(135deg, #1a1a2e, #0f0f1e);
          color: #e0e0ff;
          margin: 0;
          padding: 40px 24px;
          min-height: 100vh;
          display: flex;
          flex-direction: column;
          align-items: center;
        }
        h1 { font-size: 2.4rem; margin: 0 0 8px; }
        .device { color: #8888aa; font-size: 1rem; margin-bottom: 32px; }
        .card {
          background: rgba(255,255,255,0.05);
          backdrop-filter: blur(12px);
          border: 1px solid rgba(255,255,255,0.1);
          border-radius: 16px;
          padding: 24px;
          max-width: 540px;
          width: 100%;
          margin-bottom: 16px;
        }
        .pulse {
          display: inline-block;
          width: 10px; height: 10px;
          border-radius: 50%;
          background: #4ade80;
          margin-right: 8px;
          animation: pulse 1.5s ease-in-out infinite;
        }
        @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.4} }
        code { background: rgba(0,0,0,0.4); padding: 2px 6px; border-radius: 4px; }
        ul { padding-left: 20px; }
        li { margin: 6px 0; color: #aaaadd; }
        </style>
        </head><body>
        <h1>klamap</h1>
        <div class="device">running on <code>\(device)</code></div>

        <div class="card">
          <div><span class="pulse"></span><strong>Server is live</strong></div>
          <p>Le serveur HTTP local est actif. C'est la fondation pour les fonctionnalités multi-device et l'édition depuis un navigateur.</p>
        </div>

        <div class="card">
          <h2 style="margin-top:0">Bientôt disponible</h2>
          <ul>
            <li>Édition de wallpaper depuis cette page (Apple Maps + Google Maps)</li>
            <li>File d'attente pour soumettre des rendus à un autre iPhone du réseau</li>
            <li>Streaming live du rendu Apple Maps 3D vers le navigateur</li>
            <li>Découverte automatique des autres iPhones via Bonjour</li>
          </ul>
        </div>

        <div class="card">
          <h2 style="margin-top:0">API stub</h2>
          <p><a href="/status.json" style="color:#8b9eff">GET /status.json</a> retourne l'état JSON du serveur.</p>
        </div>
        </body></html>
        """
    }

    // MARK: - URL helper

    private func buildURL() -> String {
        let ip = wifiIP() ?? "?"
        return "http://\(ip):\(port.rawValue)"
    }

    /// Returns the device's IPv4 address on the Wi-Fi interface (en0).
    private func wifiIP() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let family = interface.ifa_addr.pointee.sa_family
            if family == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &host,
                        socklen_t(host.count),
                        nil,
                        0,
                        NI_NUMERICHOST
                    )
                    address = String(cString: host)
                    break
                }
            }
        }
        return address
    }
}
