variable "api_name" {
  description = "Name of the API"
  type        = string
  default     = "groundwork-api"
}

variable "routes" {
  description = "Routes keyed by \"METHOD /path\", each pointing at a lambda. Add an entry to expose a new endpoint."
  type = map(object({
    lambda_invoke_arn    = string
    lambda_function_name = string
  }))

  validation {
    condition     = alltrue([for key in keys(var.routes) : can(regex("^(GET|POST|PUT|PATCH|DELETE) /[A-Za-z0-9/_-]*$", key))])
    error_message = "Route keys must look like \"POST /ticket\"."
  }
}

variable "cors_allow_origins" {
  description = "Origins allowed to call the API from a browser. Restrict to the website origin once it exists."
  type        = list(string)
  default     = ["*"]
}

variable "throttling_rate_limit" {
  description = "Steady-state requests per second allowed across the API"
  type        = number
  default     = 5
}

variable "throttling_burst_limit" {
  description = "Maximum burst of concurrent requests"
  type        = number
  default     = 10
}
