const http = require("http");
const { spawn } = require("child_process");
const { URL } = require("url");

const PORT = 27870; // any free port is fine

function log(...args) {
  console.log(new Date().toISOString(), ...args);
}

const server = http.createServer((req, res) => {
  try {
    const reqUrl = new URL(req.url, `http://127.0.0.1:${PORT}`);

    // Only handle GET /join
    if (req.method !== "GET" || reqUrl.pathname !== "/join") {
      res.statusCode = 404;
      res.setHeader("Content-Type", "text/plain; charset=utf-8");
      res.end("Not found");
      return;
    }

    const url = reqUrl.searchParams.get("url");

    if (
      !url ||
      !(url.startsWith("roblox-player:") || url.startsWith("roblox:"))
    ) {
      res.statusCode = 400;
      res.setHeader("Content-Type", "text/plain; charset=utf-8");
      res.end("Missing or invalid Roblox URL");
      return;
    }

    log("Incoming Roblox URL:", url);

    const cmd = "flatpak";
    const args = [
      "run",
      "--branch=stable", // or master if that's what you have
      "--arch=x86_64",
      "--command=sober",
      "--file-forwarding",
      "org.vinegarhq.Sober",
      "--",
      "@@u",
      url,
      "@@",
    ];

    log("Running:", cmd, args.join(" "));

    const child = spawn(cmd, args, {
      detached: true,
      stdio: "ignore",
    });

    child.unref();

    res.statusCode = 200;
    res.setHeader("Content-Type", "text/plain; charset=utf-8");
    res.end("Distilling...");

    // Give the response a moment to flush, then exit the process
    setTimeout(() => {
      log("Sober launched, Joe is exiting...");
      process.exit(0);
    }, 1500);
  } catch (e) {
    log("Error handling request:", e);
    if (!res.headersSent) {
      res.statusCode = 500;
      res.setHeader("Content-Type", "text/plain; charset=utf-8");
      res.end("Failed to launch Sober!");
    }
  }
});

server.listen(PORT, () => {
  log(`Joe is listening on http://127.0.0.1:${PORT}`);
});
