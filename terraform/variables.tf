variable "region" {
    type = string 
}
variable "az" {
    type = list
}
variable "app_repository" {
    type = string
}
variable "post_processor_repository" {
    type = string
}
variable "workflow_manager_repository" {
    type = string
}
variable "api_host" {
    type = string
}
variable "api_host2" {
    type = string
}
variable "pennsieve_agent_home" {
    type = string
}
variable "pennsieve_upload_bucket" {
    type = string
}
variable "api_key_secret" {
    type = map(string)
    sensitive   = true
}
variable "environment" {
    type = string
}
variable "app_name" {
    type = string
}
variable "app_cpu" {
    type = number
}
variable "app_memory" {
    type = number
}
variable "pre_processor_cpu" {
    type = number
}
variable "pre_processor_memory" {
    type = number
}
variable "post_processor_cpu" {
    type = number
}
variable "post_processor_memory" {
    type = number
}
variable "wm_cpu" {
    type = number
}
variable "wm_memory" {
    type = number
}