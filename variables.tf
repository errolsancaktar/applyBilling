variable "projectName" {
  type        = string
  description = "Project where storage bucket and function live"
}

variable "sinkLocation" {
  type        = string
  description = "location where sink should live"
}

variable "location" {
  type        = string
  description = "region location"
}

variable "saName" {
  type        = string
  description = "name of service account to manage linking billing"
}

variable "pubsubTopic" {
  type        = string
  description = "name of pubsub topic"
}

variable "codeBucketName" {
  type        = string
  description = "name of bucket"
}

variable "funcName" {
  type        = string
  description = "Name of Cloud Function"
}

variable "billingAccount" {
  type        = string
  description = "Billing account to apply to projects"
}

variable "loggingBucketName" {
  type        = string
  description = "name of Logging bucket for sink"
}

variable "orgID" {
  type        = string
  description = "Org where sink lives"
}
