provider "google" {
  project = var.projectName
  region  = var.location
}


data "google_iam_policy" "admin" {
  binding {
    role = "roles/iam.serviceAccountUser"

    members = [
      "user:jane@example.com",
    ]
  }
}

resource "google_service_account" "sa" {
  account_id   = "my-service-account"
  display_name = "A service account that only Jane can interact with"
}

resource "google_service_account_iam_policy" "admin-account-iam" {
  service_account_id = google_service_account.sa.name
  policy_data        = data.google_iam_policy.admin.policy_data
}


resource "google_service_account" "account" {
  account_id   = "gcf-sa"
  display_name = "Test Service Account"
}

resource "google_pubsub_topic" "topic" {
  name = "functions2-topic"
}

resource "google_storage_bucket" "bucket" {
  name                        = "${local.project}-gcf-source" # Every bucket name must be globally unique
  location                    = "US"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "object" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.bucket.name
  source = "function-source.zip" # Add path to the zipped function source code
}

resource "google_cloudfunctions2_function" "function" {
  name        = "gcf-function"
  location    = "us-central1"
  description = "a new function"

  build_config {
    runtime     = "nodejs16"
    entry_point = "helloPubSub" # Set the entry point 
    environment_variables = {
      LP_BILLING_ACCOUNT = var.billingAccount
    }
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count               = 3
    min_instance_count               = 1
    available_memory                 = "4Gi"
    timeout_seconds                  = 60
    max_instance_request_concurrency = 80
    available_cpu                    = "4"
    environment_variables = {
      SERVICE_CONFIG_TEST = "config_test"
    }
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.account.email
  }

  event_trigger {
    trigger_region = "us-central1"
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.topic.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}

resource "google_logging_organization_sink" "my-sink" {
  name        = "my-sink"
  description = "some explanation on what this is"
  org_id      = "123456789"

  # Can export to pubsub, cloud storage, or bigquery
  destination = "storage.googleapis.com/${google_storage_bucket.log-bucket.name}"

  # Log all WARN or higher severity messages relating to instances
  filter = "resource.type = gce_instance AND severity >= WARNING"
}

resource "google_storage_bucket" "log-bucket" {
  name     = "organization-logging-bucket"
  location = "US"
}

resource "google_project_iam_member" "log-writer" {
  project = "your-project-id"
  role    = "roles/storage.objectCreator"
  member  = google_logging_organization_sink.my-sink.writer_identity
}
