variable "cluster_name" {
  description = "클러스터 이름"
  type        = string
}

variable "db_remote_state_bucket" {
  description = "The name of the s3 bucket for db_remote_state_bucket"
  type        = string
}

variable "db_remote_state_key" {
  description = "The path for the db's remote state in s3"
  type        = string
}

variable "instance_type" {
  description = "인스턴스 타입 (e.g. t3.nano)"
  type        = string
}

variable "min_size" {
  description = "asg안에 인스턴스 최소갯수"
}

variable "max_size" {
  description = "asg안에 인스턴스 최대갯수"
}

variable "custom_tags" {
  type    = map(string)
  default = {}
}
# variable "number_e" {
#   description = "a ex"
#   type        = number
#   default     = 42
# }

# variable "list_example" {
#   type        = list(any)
#   description = "An example of a list in tf"
#   default     = ["a", "b", "c"]
# }

# variable "list_numeric_example" {
#   type        = list(number)
#   description = "an example of a numeric list tf"
#   default     = [1, 2, 3]
# }

# variable "map_example" {
#   type        = map(string)
#   description = "an example of a map in tf"
#   default = {
#     "key" = "value"
#   }
# }

# variable "object_example" {
#   description = "An example of a structural type in tf"
#   type = object({
#     name    = string
#     age     = number
#     tags    = list(string)
#     enabled = bool
#   })
#   default = {
#     age     = 1
#     enabled = false
#     name    = "value"
#     tags    = ["value"]
#   }
# }



