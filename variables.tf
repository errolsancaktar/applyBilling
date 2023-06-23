## No Defaults ##

variable "billingAccount" {
  type        = string
  description = "Billing account to apply to projects"
}

variable "orgID" {
  type        = string
  description = "Org where sink lives"
}

## Defaults ##

variable saRoles {
  type = list(string)
  description = "Roles needed for Billing SA Account"
  default = [
    "roles/cloudfunctions.invoker",
    "roles/pubsub.publisher",
    "roles/run.invoker",
    "roles/eventarc.eventReceiver",
    "roles/artifactregistry.reader"
  ]
}

variable "projectName" {
  type        = string
  description = "Project where storage bucket and function live"
  default = "sandbox-388418"
}

variable "region" {
  type        = string
  description = "region location"
  default = "us-central1"
}

variable "saName" {
  type        = string
  description = "name of service account to manage linking billing"
  default = "billing-sa"
}

variable "pubsubTopic" {
  type        = string
  description = "name of pubsub topic"
  default = "lplabs_project_created"
}

variable "funcName" {
  type        = string
  description = "Name of Cloud Function"
  default = "lplabs_billing_applicator"
}

variable "loggingBucketName" {
  type        = string
  description = "name of Logging bucket for sink"
  default = "create_projects_lpio_log_bucket"
}

variable "codeZip" {
  type= string
  description = "name of zip file to upload to cloudFunc"
  default = "billing_code.zip"
}