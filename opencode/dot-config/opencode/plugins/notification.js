export const NotificationPlugin = async ({ $, client }) => {
  const ENABLED = true

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

        await $`notify-send --urgency=${urgency} --app-name=opencode --icon=utilities-terminal ${title} ${message}`.nothrow()
      }
    },
  }
}
