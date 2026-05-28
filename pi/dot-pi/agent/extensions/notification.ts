/**
 * Pi Notify Extension
 *
 * Sends a native macOS notification when the agent finishes and is waiting for input.
 * Uses terminal-notifier when available, falls back to OSC 777 escape sequence
 * (supported by Ghostty, iTerm2, WezTerm, rxvt-unicode).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { exec } from "child_process";

const ENABLED = true;

function notifyTerminalNotifier(title: string, message: string): void {
  exec(`terminal-notifier -message ${JSON.stringify(message)} -title ${JSON.stringify(title)} -sound default`, () => {});
}

function notifyOSC777(title: string, body: string): void {
  process.stdout.write(`\x1b]777;notify;${title};${body}\x07`);
}

function notify(title: string, message: string): void {
  // Prefer terminal-notifier on macOS if available
  exec("which terminal-notifier", (err) => {
    if (!err) {
      notifyTerminalNotifier(title, message);
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
