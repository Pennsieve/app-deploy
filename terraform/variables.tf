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