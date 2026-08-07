function pushNotifications() {
  return globalThis.Capacitor?.Plugins?.PushNotifications
}

export async function initPushNotifications() {
  if (globalThis.document?.body?.dataset.nativePushEnabled !== "true") return false

  const plugin = pushNotifications()
  if (!plugin?.checkPermissions || !plugin?.requestPermissions) return false

  let permission = await plugin.checkPermissions()
  if (permission.receive === "prompt") {
    permission = await plugin.requestPermissions()
  }
  if (permission.receive !== "granted") return false

  await plugin.addListener("registration", async (token) => {
    await registerTokenWithBackend(token.value)
  })

  await plugin.addListener("registrationError", (error) => {
    console.error("Push registration error:", error)
  })

  await plugin.addListener("pushNotificationReceived", (notification) => {
    console.log("Push received:", notification)
  })

  await plugin.addListener("pushNotificationActionPerformed", (action) => {
    const data = action.notification.data
    if (data?.url) {
      window.location.href = data.url
    }
  })

  await plugin.register()

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
