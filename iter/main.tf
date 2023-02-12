variable "user_names" {
  type    = list(string)
  default = ["neo", "tri", "mor"]
}

provider "aws" {
  region = "ap-northeast-2"
}


# count 사용 -> 위에 배열이 바뀌거나 추가 삭제에서 약함
# resource "aws_iam_user" "example" {
#   count = length(var.user_names)
#   name  = var.user_names[count.index]
# }

# output "all_user_arns" {
#   value = aws_iam_user.example[*].arn
# }

# output "neo_arn" {
#   value = aws_iam_user.example[0].arn
# }



#  for_each 사용 -> 컬랙션 중간의 항목의 추가 삭제에도 안전 -> 리소스의 복제본을 만들때는 for_each가 바람직
resource "aws_iam_user" "example" {
  for_each = toset(var.user_names)
  name     = each.value
}

output "all_users" {
  value = values(aws_iam_user.example)[*].arn
}



