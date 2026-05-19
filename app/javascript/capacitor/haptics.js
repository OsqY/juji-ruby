import { Haptics, ImpactStyle, NotificationType } from "@capacitor/haptics"

export async function lightImpact() {
  await Haptics.impact({ style: ImpactStyle.Light })
}

export async function mediumImpact() {
  await Haptics.impact({ style: ImpactStyle.Medium })
}

export async function heavyImpact() {
  await Haptics.impact({ style: ImpactStyle.Heavy })
}

export async function successNotification() {
  await Haptics.notification({ type: NotificationType.Success })
}

export async function errorNotification() {
  await Haptics.notification({ type: NotificationType.Error })
}

export async function warningNotification() {
  await Haptics.notification({ type: NotificationType.Warning })
}

export async function vibrate() {
  await Haptics.vibrate()
}
