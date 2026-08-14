export const NotificationPlugin = async ({ $, client }) => {
  const ENABLED = true
  const isMac = process.platform === "darwin"

  return {
    event: async ({ event }) => {
      if (!ENABLED) return
      if (event.type === "session.idle" || event.type === "session.error") {
        const isError = event.type === "session.error"

        let title = "opencode"
        try {
          const session = await client.session.get({ path: { id: event.properties.sessionID } })
          if (session.data?.title) title = session.data.title
        } catch {}

        const message = isError ? "Session errored!" : "Session completed!"
        const urgency = isError ? "critical" : "normal"

        if (isMac) {
          await $`terminal-notifier -title ${title} -message ${message} -sound default 2>/dev/null`.nothrow()
        } else {
          await $`notify-send --urgency=${urgency} ${title} ${message} 2>/dev/null`.nothrow()
        }
      }
    },
  }
}
