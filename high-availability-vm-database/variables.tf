variable "pg_password" {
  type = string
  description = "PostgreSQL database password."
  default = "passpass"
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "project" {
  type = string
}
