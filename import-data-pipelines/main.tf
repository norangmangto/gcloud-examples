locals {
  function_name = "bjang-tf-test-func"
}

provider "google" {
  project     = "trv-hs-src-intf-pg-playground"
  region      = "europe-west1"
  zone        = "europe-west1-c"
  credentials = "/Users/bjang/.gcp/bjang-sa.json"
}

resource "google_cloudfunctions_function" "bjang-tf-test-func" {
  name                = local.function_name
  entry_point         = "sub_method"
  available_memory_mb = 128
  timeout             = 61
  project             = "trv-hs-src-intf-pg-playground"
  region              = "europe-west1"
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.bjang-tf-test-pubsub.name
  }
  source_archive_bucket = google_storage_bucket.bjang-tf-test-bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  runtime               = "python37"
  labels = {
    deployment_name = "test"
  }
}

resource "google_pubsub_topic" "bjang-tf-test-pubsub" {
  name    = "bjang-tf-test-pubsub"
  project = "trv-hs-src-intf-pg-playground"
}


resource "google_storage_bucket" "bjang-tf-test-bucket" {
  name = "bjang-tf-test-bucket"
}

data "archive_file" "test_function" {
  type        = "zip"
  output_path = "${path.module}/.files/main.zip"
  source {
    content  = "${file("${path.module}/main.py")}"
    filename = "main.py"
  }
}

resource "google_storage_bucket_object" "archive" {
  name       = "${local.function_name}.${data.archive_file.test_function.output_md5}.zip"
  bucket     = google_storage_bucket.bjang-tf-test-bucket.name
  source     = "${path.module}/.files/main.zip"
  depends_on = ["data.archive_file.test_function"]
}

