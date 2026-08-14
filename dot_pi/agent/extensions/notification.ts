/**
 * Pi Notify Extension
 *
 * Sends a native desktop notification when the agent finishes and is waiting for input.
 * macOS: terminal-notifier when available.
 * Linux: notify-send when available.
 * Falls back to OSC 777 escape sequence on both (supported by Ghostty, iTerm2,
 * WezTerm, rxvt-unicode) when the native tool isn't installed.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { exec } from "child_process";

const ENABLED = true;

function notifyTerminalNotifier(title: string, message: string): void {
  exec(`terminal-notifier -message ${JSON.stringify(message)} -title ${JSON.stringify(title)} -sound default`, () => {});
}

function notifyNotifySend(title: string, message: string): void {
  exec(`notify-send ${JSON.stringify(title)} ${JSON.stringify(message)} 2>/dev/null`, () => {});
}

function notifyOSC777(title: string, body: string): void {
  process.stdout.write(`\x1b]777;notify;${title};${body}\x07`);
}

function notify(title: string, message: string): void {
  const nativeTool = process.platform === "darwin" ? "terminal-notifier" : "notify-send";
  exec(`which ${nativeTool}`, (err) => {
    if (!err) {
      process.platform === "darwin" ? notifyTerminalNotifier(title, message) : notifyNotifySend(title, message);
    } else {
      notifyOSC777(title, message);
    }
  });
}

export default function (pi: ExtensionAPI) {
  if (!ENABLED) return;

  pi.on("agent_end", async (_event, ctx) => {
    const model = ctx.model?.id ?? "pi";
    notify("pi", "Ready for input");
  });
}
