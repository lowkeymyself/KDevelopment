#include "http.h"
#include "log.h"

#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>

#include <atomic>
#include <cstring>
#include <string>
#include <string_view>
#include <thread>

namespace koffee::http {

namespace {

constexpr int kRecvBufSize = 4096;
constexpr int kRecvTimeoutMs = 2000;
constexpr int kSendTimeoutMs = 2000;

// Alpha1 health payload. Alpha2 will grow this to include driver + Roblox
// attach state so koffee.lua can toast "helper up but not attached" instead
// of a false-positive "everything green."
constexpr std::string_view kHealthBody =
    R"({"status":"ok","version":"0.3.0-alpha1","stage":"skeleton"})";

// Response builder. Fixed content-type application/json; the client is
// koffee.lua parsing this via HttpService:JSONDecode.
std::string build_response(int status, std::string_view reason,
                           std::string_view body) {
    std::string s;
    s.reserve(128 + body.size());
    s += "HTTP/1.1 ";
    s += std::to_string(status);
    s += ' ';
    s += reason;
    s += "\r\n";
    s += "Content-Type: application/json\r\n";
    s += "Content-Length: ";
    s += std::to_string(body.size());
    s += "\r\n";
    s += "Connection: close\r\n";
    s += "\r\n";
    s += body;
    return s;
}

// Read until end-of-headers OR buffer full. Alpha1 doesn't parse the body
// (no route needs it), so once we have the request line + headers we stop.
// Returns empty string on socket error / timeout / oversize.
std::string read_head(SOCKET client) {
    std::string buf;
    buf.reserve(kRecvBufSize);
    char tmp[512];
    while (buf.size() < kRecvBufSize) {
        const int n = ::recv(client, tmp, sizeof(tmp), 0);
        if (n <= 0) return {};
        buf.append(tmp, tmp + n);
        // End-of-headers marker.
        if (buf.find("\r\n\r\n") != std::string::npos) break;
    }
    return buf;
}

// Parse "METHOD PATH HTTP/1.x\r\n..." — returns METHOD and PATH in-place
// views into `raw`. Empty result on malformed input.
struct RequestLine {
    std::string_view method;
    std::string_view path;
};
RequestLine parse_request_line(std::string_view raw) {
    const auto line_end = raw.find("\r\n");
    if (line_end == std::string_view::npos) return {};
    const auto line = raw.substr(0, line_end);
    const auto sp1 = line.find(' ');
    if (sp1 == std::string_view::npos) return {};
    const auto sp2 = line.find(' ', sp1 + 1);
    if (sp2 == std::string_view::npos) return {};
    return {line.substr(0, sp1), line.substr(sp1 + 1, sp2 - sp1 - 1)};
}

void handle_client(SOCKET client) {
    // Apply timeouts so a stuck peer can't hold a worker thread forever.
    DWORD rt = kRecvTimeoutMs, st = kSendTimeoutMs;
    ::setsockopt(client, SOL_SOCKET, SO_RCVTIMEO,
                 reinterpret_cast<const char*>(&rt), sizeof(rt));
    ::setsockopt(client, SOL_SOCKET, SO_SNDTIMEO,
                 reinterpret_cast<const char*>(&st), sizeof(st));

    const std::string head = read_head(client);
    std::string response;

    if (head.empty()) {
        // Malformed / timed out — respond with 400 as a courtesy, then close.
        response = build_response(400, "Bad Request",
                                  R"({"error":"malformed_request"})");
    } else {
        const auto req = parse_request_line(head);
        if (req.method == "GET" && req.path == "/health") {
            response = build_response(200, "OK", kHealthBody);
        } else {
            response = build_response(404, "Not Found",
                                      R"({"error":"unknown_route"})");
        }
    }

    // Best-effort send; on partial send we just close (browser / lua client
    // will surface the error). Ignore return -- worker exits either way.
    ::send(client, response.data(), static_cast<int>(response.size()), 0);
    ::shutdown(client, SD_BOTH);
    ::closesocket(client);
}

}  // namespace

int serve(std::uint16_t port) {
    WSADATA wsa{};
    if (const int rc = ::WSAStartup(MAKEWORD(2, 2), &wsa); rc != 0) {
        koffee::log_err("WSAStartup failed");
        return rc;
    }

    SOCKET listener = ::socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (listener == INVALID_SOCKET) {
        koffee::log_err("socket() failed");
        ::WSACleanup();
        return 1;
    }

    // 127.0.0.1 ONLY. The helper accepts no external connections; koffee.lua
    // runs in the same-machine Roblox process and talks over localhost.
    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    ::inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr);

    BOOL reuse = TRUE;
    ::setsockopt(listener, SOL_SOCKET, SO_REUSEADDR,
                 reinterpret_cast<const char*>(&reuse), sizeof(reuse));

    if (::bind(listener, reinterpret_cast<sockaddr*>(&addr), sizeof(addr))
        == SOCKET_ERROR) {
        koffee::log_err("bind() failed -- port likely in use");
        ::closesocket(listener);
        ::WSACleanup();
        return 2;
    }
    if (::listen(listener, SOMAXCONN) == SOCKET_ERROR) {
        koffee::log_err("listen() failed");
        ::closesocket(listener);
        ::WSACleanup();
        return 3;
    }

    {
        std::string msg = "http listening on 127.0.0.1:";
        msg += std::to_string(port);
        koffee::log(msg);
    }

    // Accept forever. Each connection gets its own detached thread; the pool
    // is unbounded here because alpha1 traffic is tiny (one koffee.lua
    // instance sending occasional keepalives). Alpha2 caps concurrency.
    for (;;) {
        sockaddr_in peer{};
        int peer_len = sizeof(peer);
        SOCKET client = ::accept(listener,
                                 reinterpret_cast<sockaddr*>(&peer),
                                 &peer_len);
        if (client == INVALID_SOCKET) {
            // WSAEINTR on shutdown, WSAENOBUFS under load — either way, keep
            // the loop alive; abrupt exit here would silently kill /health.
            continue;
        }
        std::thread(handle_client, client).detach();
    }

    // Unreachable in alpha1 — no shutdown path yet. Alpha2 wires a signal
    // handler that closes `listener` from outside the accept loop.
    ::closesocket(listener);
    ::WSACleanup();
    return 0;
}

}  // namespace koffee::http
