function pushNotifications() {
  return globalThis.Capacitor?.Plugins?.PushNotifications
}

export async function initPushNotifications() {
  const plugin = pushNotifications()
  if (!plugin?.requestPermissions) return false

  const result = await plugin.requestPermissions()
  if (result.receive !== "granted") return false

  await plugin.register()

  plugin.addListener("registration", async (token) => {
    await registerTokenWithBackend(token.value)
  })

  plugin.addListener("registrationError", (error) => {
    console.error("Push registration error:", error)
  })

  plugin.addListener("pushNotificationReceived", (notification) => {
    console.log("Push received:", notification)
  })

  plugin.addListener("pushNotificationActionPerformed", (action) => {
    const data = action.notification.data
    if (data?.url) {
      window.location.href = data.url
    }
  })

  return true
}

async function registerTokenWithBackend(token) {
  try {
    const response = await fetch("/push_notifications/register", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({ fcm_token: token })
    })
    if (!response.ok) throw new Error("Failed to register token")
  } catch (error) {
    console.error("Token registration failed:", error)
  }
}

export async function unregisterPushNotifications() {
  await pushNotifications()?.unregister?.()
}
