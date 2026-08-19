/**
 * Session title extension.
 *
 * Mirrors opencode's `agent.title.prompt` config (see dot_config/opencode/opencode.json):
 * after the first completed turn, asks the active model for a short 3-6 word
 * title summarizing the conversation and sets it as the session display name.
 * This keeps pi sessions easy to find in `/resume` without any manual `/name`
 * step, matching opencode's auto-titled session list.
 *
 * Best-effort: any failure (no auth, model error, empty response) is silently
 * ignored and the session simply stays unnamed, same as pi's default behavior.
 */

import { uuidv7 } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type ContentBlock = { type?: string; text?: string };

type SessionEntry = {
  type: string;
  message?: { role?: string; content?: unknown };
};

const TITLE_PROMPT =
  "Generate a session title as a short description, it should be 3-6 words " +
  "summarizing the main topic or task of the conversation. Return only the " +
  "title string, nothing else.";

function extractText(content: unknown): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content
    .filter((part): part is ContentBlock => !!part && typeof part === "object")
    .filter((part) => part.type === "text" && typeof part.text === "string")
    .map((part) => part.text as string)
    .join("\n");
}

function buildConversationText(entries: SessionEntry[]): string {
  return entries
    .filter((entry) => entry.type === "message" && entry.message?.role)
    .map((entry) => `${entry.message?.role}: ${extractText(entry.message?.content)}`)
    .filter((line) => line.trim().length > 0)
    .join("\n\n")
    .slice(0, 4000);
}

export default function (pi: ExtensionAPI) {
  pi.on("agent_settled", async (_event, ctx) => {
    if (pi.getSessionName()) return;

    const branch = ctx.sessionManager.getBranch() as SessionEntry[];
    const assistantTurns = branch.filter(
      (entry) => entry.type === "message" && entry.message?.role === "assistant",
    ).length;

    // Only fire once, right after the first completed turn.
    if (assistantTurns !== 1) return;

    const conversationText = buildConversationText(branch);
    if (!conversationText.trim()) return;

    const model = ctx.model;
    if (!model || !ctx.modelRegistry.hasConfiguredAuth(model)) return;

    try {
      const response = await ctx.modelRegistry.complete(
        model,
        {
          messages: [
            {
              role: "user" as const,
              content: [
                {
                  type: "text" as const,
                  text: `${TITLE_PROMPT}\n\n<conversation>\n${conversationText}\n</conversation>`,
                },
              ],
              timestamp: Date.now(),
            },
          ],
        },
        { reasoningEffort: "low", cacheRetention: "none", sessionId: uuidv7() },
      );

      const title = response.content
        .filter((c): c is { type: "text"; text: string } => c.type === "text")
        .map((c) => c.text)
        .join(" ")
        .trim()
        .replace(/^["']|["']$/g, "");

      if (title) pi.setSessionName(title);
    } catch {
      // best-effort; leave session unnamed on failure
    }
  });
}
