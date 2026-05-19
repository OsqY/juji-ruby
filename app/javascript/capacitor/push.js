import { PushNotifications } from "@capacitor/push-notifications"

export async function initPushNotifications() {
  const result = await PushNotifications.requestPermissions()
  if (result.receive !== "granted") return false

  await PushNotifications.register()

  PushNotifications.addListener("registration", async (token) => {
    await registerTokenWithBackend(token.value)
  })

  PushNotifications.addListener("registrationError", (error) => {
    console.error("Push registration error:", error)
  })

  PushNotifications.addListener("pushNotificationReceived", (notification) => {
    console.log("Push received:", notification)
  })

  PushNotifications.addListener("pushNotificationActionPerformed", (action) => {
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
  await PushNotifications.unregister()
}
