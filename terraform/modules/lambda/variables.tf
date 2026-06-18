variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

# Path to the directory containing Python source code — zipped automatically via archive_file
variable "source_dir" {
  description = "Path to the directory containing Lambda source code"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

# Format: filename.function_name (e.g. "handler.lambda_handler")
variable "handler" {
  description = "Lambda handler entry point"
  type        = string
  default     = "handler.lambda_handler"
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 10
}

variable "memory_size" {
  description = "Lambda memory allocation in MB"
  type        = number
  default     = 128
}

# Injected as Lambda environment variables — use for config, not secrets
variable "environment_variables" {
  description = "Map of environment variables to pass to the Lambda function"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources in this module"
  type        = map(string)
  default     = {}
}
