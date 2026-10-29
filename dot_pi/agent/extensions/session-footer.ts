import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

function tokens(n: number): string {
	if (n < 1000) return String(n);
	if (n < 10000) return `${(n / 1000).toFixed(1)}k`;
	if (n < 1000000) return `${Math.round(n / 1000)}k`;
	return `${(n / 1000000).toFixed(1)}M`;
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		ctx.ui.setFooter((_tui, theme) => ({
			invalidate() {},
			render(width: number): string[] {
				if (width <= 0) return [""];

				const id = ctx.sessionManager.getSessionId().slice(0, 8);
				let input = 0;
				let output = 0;
				let cost = 0;
				for (const entry of ctx.sessionManager.getEntries()) {
					if (entry.type !== "message") continue;
					const usage = entry.message.role === "assistant" || entry.message.role === "toolResult"
						? entry.message.usage : undefined;
					if (!usage) continue;
					input += usage.input;
					output += usage.output;
					cost += usage.cost.total;
				}

				const context = ctx.getContextUsage();
				const contextWindow = context?.contextWindow ?? ctx.model?.contextWindow ?? 0;
				const percent = context?.percent == null ? "?" : `${context.percent.toFixed(1)}%`;
				const stats = [
					...(input ? [`↑${tokens(input)}`] : []),
					...(output ? [`↓${tokens(output)}`] : []),
					`$${cost.toFixed(3)}`,
					`${percent}/${tokens(contextWindow)} (auto)`,
				].join(" ");
				const model = ctx.model;
				const thinking = model?.reasoning ? ` • ${pi.getThinkingLevel()}` : "";
				const modelText = `${model?.provider ? `(${model.provider}) ` : ""}${model?.id ?? "no-model"}${thinking}`;

				const left = theme.fg("dim", id);
				const right = theme.fg("dim", truncateToWidth(modelText, Math.max(0, width - visibleWidth(left) - 2), "…"));
				const leftWidth = visibleWidth(left);
				const rightWidth = visibleWidth(right);
				if (leftWidth + rightWidth + 2 >= width) {
					const available = Math.max(0, width - rightWidth - 1);
					return [truncateToWidth(left, available) + " ".repeat(Math.max(0, width - rightWidth - available)) + right];
				}

				const available = width - leftWidth - rightWidth - 2;
				const middle = theme.fg("dim", truncateToWidth(stats, available, "…"));
				const middleWidth = visibleWidth(middle);
				// Center the stats when possible, without moving the ID or model off their edges.
				const start = Math.max(leftWidth + 1, Math.min(Math.floor((width - middleWidth) / 2), width - rightWidth - middleWidth - 1));
				return [left + " ".repeat(start - leftWidth) + middle + " ".repeat(width - start - middleWidth - rightWidth) + right];
			},
		}));
	});
}
