terraform {
  required_providers {
    zipper = {
      version = "~>0.1"
      source = "ArthurHlt/zipper"
    }
  }
}

provider "google" {
  project = var.projectName
  region  = var.region
}

provider "zipper" {
  skip_ssl_validation = true
}

#################################################################################
## Service Account and IAM ##

resource "google_service_account" "sa" {
  account_id   = var.saName
  display_name = "Service Account with access to add billing information"
}

resource "google_organization_iam_member" "organization" {
  org_id  = var.orgID
  role    = "roles/billing.user"
  member  = google_service_account.sa.email
}

resource "google_project_iam_member" "log-writer" {
  project = var.projectName
  role    = "roles/storage.objectCreator"
  member  = "serviceAccount:${google_logging_organization_sink.projectCreate.writer_identity}"
}

resource "google_project_iam_member" "cloudfunctions" {
  for_each = toset(var.saRoles)
  project = var.projectName
  role    = each.value
  member  = "serviceAccount:${google_service_account.sa.email}"
}



#################################################################################
## PubSub ##

resource "google_pubsub_topic" "topic" {
  name = var.pubsubTopic
  message_retention_duration = "86600s"
}


#################################################################################
## Storage and Data ##

resource "google_storage_bucket" "codeBucket" {
  name                        = "${var.projectName}-lp-gcf"
  location                    = "US"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "object" {
  name   = var.codeZip
  bucket = google_storage_bucket.codeBucket.name
  source = zipper_file.cloudFunctionCode.output_path
}

resource "google_storage_bucket" "log-bucket" {
  name     = var.loggingBucketName
  location = "US"
}

resource "zipper_file" "cloudFunctionCode" {
  source      = "${path.module}/code"
  output_path      = "${path.module}/files/${var.codeZip}"
}

#################################################################################
## Log Sink ##

resource "google_logging_organization_sink" "projectCreate" {
  name        = "projectCreated"
  description = "Sink for only projects being created"
  org_id      = var.orgID

  # Can export to pubsub, cloud storage, or bigquery
  destination = "storage.googleapis.com/${google_storage_bucket.log-bucket.name}"

  # Log all WARN or higher severity messages relating to instances
  filter = "protoPayload.methodName=\"CreateProject\""
}

#################################################################################
## Cloud Function ##
resource "google_cloudfunctions2_function" "create_project_watch_function" {
  name        = var.funcName
  location    = var.region
  description = "Function for applying billing when a new project is created"

  build_config {
    runtime     = "python311"
    entry_point = "main" # Set the entry point 
    source {
      storage_source {
        bucket = google_storage_bucket.codeBucket.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count               = 1
    min_instance_count               = 0
    available_memory                 = "256Mi"
    timeout_seconds                  = 60
    max_instance_request_concurrency = 80
    available_cpu                    = "1"
    environment_variables = {
      LP_BILLING_ACCOUNT = var.billingAccount
    }
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.sa.email
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.topic.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}