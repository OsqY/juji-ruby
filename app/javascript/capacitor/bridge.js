import { Capacitor } from "@capacitor/core"
import { Preferences } from "@capacitor/preferences"
import { App } from "@capacitor/app"
import { SplashScreen } from "@capacitor/splash-screen"
import { StatusBar, Style } from "@capacitor/status-bar"

const SESSION_KEY = "juji_session_id"
const LAST_PATH_KEY = "juji_last_path"

export async function initBridge() {
  // Hide splash screen after a short delay
  setTimeout(() => SplashScreen.hide(), 1500)

  // Set status bar style based on theme
  const theme = document.documentElement.dataset.theme || "light"
  await StatusBar.setStyle({ style: theme === "dark" ? Style.Dark : Style.Light })
  await StatusBar.setBackgroundColor({ color: getComputedStyle(document.documentElement).getPropertyValue("--paper").trim() || "#FFFFFF" })

  // Handle Android back button
  App.addListener("backButton", ({ canGoBack }) => {
    if (canGoBack) {
      window.history.back()
    } else {
      App.exitApp()
    }
  })

  // Save last visited path before app pauses
  App.addListener("pause", async () => {
    await Preferences.set({ key: LAST_PATH_KEY, value: window.location.pathname })
  })

  // On app resume, could refresh data or check connectivity
  App.addListener("resume", async () => {
    const lastPath = await Preferences.get({ key: LAST_PATH_KEY })
    if (lastPath.value && lastPath.value !== window.location.pathname) {
      // Optional: navigate back to last known path
    }
  })
}

export async function saveSession(sessionId) {
  await Preferences.set({ key: SESSION_KEY, value: sessionId })
}

export async function getSession() {
  const result = await Preferences.get({ key: SESSION_KEY })
  return result.value
}

export async function clearSession() {
  await Preferences.remove({ key: SESSION_KEY })
  await Preferences.remove({ key: LAST_PATH_KEY })
}

export async function injectSessionCookie() {
  const sessionId = await getSession()
  if (sessionId) {
    document.cookie = `session_id=${sessionId}; path=/; SameSite=Lax`
  }
}

// Check if running inside Capacitor native shell
export function isNative() {
  return typeof Capacitor !== "undefined" && Capacitor.isNativePlatform()
}
