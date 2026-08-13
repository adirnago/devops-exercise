variable "web_server_count" {
  description = "Number of web servers to create"
  type        = number
  default     = 2
}

variable "web_server_version" {
  description = "Version of the web server"
  type        = string
  default     = "1.0.0"
}

variable "load_balancer_version" {
  description = "Version of the load balancer"
  type        = string
  default     = "1.0.0"
}
