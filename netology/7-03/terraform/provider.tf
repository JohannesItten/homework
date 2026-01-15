provider "yandex" {
  cloud_id  = var.provider_cloud_id
  folder_id = var.provider_folder_id
  token     = var.provider_token
  zone      = "ru-central1-a"
}