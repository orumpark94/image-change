output "iam_user_name" {
  value = aws_iam_user.image_project_user.name
}

output "iam_user_access_key_id" {
  value = aws_iam_access_key.image_project_access_key.id
  sensitive = true
}

output "iam_user_secret" {
  value     = aws_iam_access_key.image_project_access_key.secret
  sensitive = true
}
