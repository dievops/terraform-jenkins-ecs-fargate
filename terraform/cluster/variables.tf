variable "region" {
    type = string
}

variable "additional_tags" {
    type = map(string)
}

variable "project" {
    type = string
}

variable "environment" {
    type = string
}

variable "container_image" {
    type = string
}

variable "container_cpu" {
    type = string
}
variable "container_memory" {
    type = string
}