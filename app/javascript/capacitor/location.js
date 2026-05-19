import { Geolocation } from "@capacitor/geolocation"

export async function getCurrentPosition() {
  const permission = await Geolocation.requestPermissions()
  if (permission.location !== "granted") {
    throw new Error("Location permission denied")
  }

  const position = await Geolocation.getCurrentPosition({
    enableHighAccuracy: true,
    timeout: 10000
  })

  return {
    latitude: position.coords.latitude,
    longitude: position.coords.longitude,
    accuracy: position.coords.accuracy
  }
}

export async function watchPosition(callback) {
  const permission = await Geolocation.requestPermissions()
  if (permission.location !== "granted") {
    throw new Error("Location permission denied")
  }

  return Geolocation.watchPosition({ enableHighAccuracy: true }, (position) => {
    if (position) {
      callback({
        latitude: position.coords.latitude,
        longitude: position.coords.longitude,
        accuracy: position.coords.accuracy
      })
    }
  })
}
