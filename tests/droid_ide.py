"""Wire-level tests, driven by tests/droid_ide.lua using a live Neovim."""
import http.client
import json
import subprocess
import sys
import unittest

PORT, ADDR, FILE, NVIM = sys.argv[1:]


def request(method, body=None, session=None, extra=None):
    conn = http.client.HTTPConnection("127.0.0.1", int(PORT), timeout=5)
    headers = {"Content-Type": "application/json", **(extra or {})}
    if session:
        headers["Mcp-Session-Id"] = session
    conn.request(method, "/mcp", json.dumps(body) if body is not None else None, headers)
    response = conn.getresponse()
    data = response.read()
    result = response.status, dict(response.getheaders()), json.loads(data) if data else None
    conn.close()
    return result


class ProtocolTest(unittest.TestCase):
    def test_bridge(self):
        status, headers, data = request("POST", {
            "jsonrpc": "2.0", "id": 1, "method": "initialize",
            "params": {"protocolVersion": "2025-11-25", "capabilities": {},
                       "clientInfo": {"name": "protocol-test", "version": "1"}},
        })
        self.assertEqual(status, 200)
        self.assertEqual(data["result"]["serverInfo"]["name"], "Neovim")
        session = headers["Mcp-Session-Id"]
        self.assertEqual(request("POST", {
            "jsonrpc": "2.0", "method": "notifications/initialized",
        }, session)[0], 202)
        conn = http.client.HTTPConnection("127.0.0.1", int(PORT), timeout=5)
        conn.request("GET", "/mcp", headers={"Mcp-Session-Id": session, "Accept": "text/event-stream"})
        stream = conn.getresponse()
        self.assertEqual(stream.status, 200)

        def event(method, predicate=lambda _: True):
            for _ in range(100):
                line = stream.readline().decode()
                if line.startswith("data: "):
                    msg = json.loads(line[6:])
                    if msg["method"] == "notifications/" + method and predicate(msg["params"]):
                        return msg["params"]
            self.fail("Expected event: " + method)

        def control(action):
            res = subprocess.run(
                [NVIM, "--headless", "--server", ADDR, "--remote-expr",
                 f'luaeval("DroidIDETest(\'{action}\')")'],
                capture_output=True, text=True, timeout=5,
            )
            self.assertEqual(res.returncode, 0, res.stderr)

        def call(method, params=None):
            status, _, data = request("POST", {
                "jsonrpc": "2.0", "id": 2, "method": method, "params": params or {},
            }, session)
            self.assertEqual(status, 200)
            return data

        active = event("activeFile")
        self.assertEqual(active["path"], FILE)
        self.assertEqual(active["selection"]["startCharacter"], 3, "UTF-16, not bytes")
        self.assertFalse(active["isDirty"])
        self.assertEqual(event("openFiles")["files"][0]["path"], FILE)
        self.assertEqual(event("diagnostics")["diagnostics"], [])
        self.assertGreater(event("heartbeat")["timestamp"], 0)
        self.assertEqual(call("ping")["result"], {})
        self.assertEqual(call("missing")["error"]["code"], -32601)
        self.assertEqual(call("tools/list")["result"]["tools"][0]["name"], "openFile")
        self.assertTrue(call("tools/call", {"name": "missing"})["result"]["isError"])
        self.assertTrue(call("tools/call", {
            "name": "openFile", "arguments": {"filePath": "relative"},
        })["result"]["isError"])
        self.assertTrue(call("tools/call", {
            "name": "openFile", "arguments": {"filePath": FILE, "waitForSave": True},
        })["result"]["isError"])
        self.assertEqual(request("GET")[0], 404, "SSE requires a session")
        self.assertEqual(request("POST", {
            "jsonrpc": "2.0", "id": 1, "method": "ping",
        }, "invalid")[0], 404)
        self.assertEqual(request("GET", session=session, extra={"Origin": "https://example.com"})[0], 403)
        self.assertEqual(request("GET", session=session, extra={"Host": "example.com"})[0], 403)

        control("change")
        self.assertTrue(event("activeFile", lambda p: p["isDirty"])["isDirty"])
        diag = event("diagnostics", lambda p: bool(p["diagnostics"]))["diagnostics"][0]
        self.assertEqual(diag["range"]["start"]["character"], 3)
        self.assertEqual(diag["severity"], 0)
        control("clear")
        self.assertEqual(event("diagnostics")["diagnostics"], [])
        control("terminal")
        # A new stream must get a full snapshot, even when focus is not in a file.
        conn.close()
        stream.close()
        conn = http.client.HTTPConnection("127.0.0.1", int(PORT), timeout=5)
        conn.request("GET", "/mcp", headers={"Mcp-Session-Id": session})
        stream = conn.getresponse()
        self.assertEqual(event("activeFile")["path"], FILE)
        control("selection")
        selected = event("activeFile", lambda p: bool(p["selection"]["selectedText"]))
        self.assertEqual(selected["selection"]["selectedText"], "a😀b\nchanged")
        self.assertEqual(selected["selection"]["startLine"], 0)
        self.assertEqual(selected["selection"]["endLine"], 1)
        control("empty")
        self.assertEqual(event("activeFile", lambda p: not p["path"])["path"], "")
        unusual_path = FILE + " | let g:droid_ide_injected=1"
        opened = call("tools/call", {
            "name": "openFile", "arguments": {"filePath": unusual_path},
        })["result"]
        self.assertNotIn("isError", opened)
        self.assertEqual(event("activeFile", lambda p: bool(p["path"]))["path"], unusual_path)
        injected = subprocess.run(
            [NVIM, "--headless", "--server", ADDR, "--remote-expr",
             "get(g:, 'droid_ide_injected', 0)"],
            capture_output=True, text=True, timeout=5,
        )
        self.assertEqual(injected.stdout.strip(), "0", "File paths must never execute Ex commands")
        stream.close()
        conn.close()
        self.assertEqual(request("DELETE", session=session)[0], 200)
        self.assertEqual(request("GET", session=session)[0], 404)
        print("Protocol, security, UTF-16, context, diagnostics, reconnect, and tool checks passed")


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]])
