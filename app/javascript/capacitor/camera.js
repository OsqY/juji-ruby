import { Camera, CameraResultType, CameraSource } from "@capacitor/camera"

export async function takePhoto() {
  const image = await Camera.getPhoto({
    quality: 90,
    allowEditing: false,
    resultType: CameraResultType.DataUrl,
    source: CameraSource.Camera
  })
  return image.dataUrl
}

export async function pickPhoto() {
  const image = await Camera.getPhoto({
    quality: 90,
    allowEditing: false,
    resultType: CameraResultType.DataUrl,
    source: CameraSource.Photos
  })
  return image.dataUrl
}
