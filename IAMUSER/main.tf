provider "aws" {
  region     = "ap-northeast-2"
}

resource "aws_iam_user" "image_project_user" {
  name = "image-project"
}

resource "aws_iam_user_policy" "image_project_user_policy" {
  name = "image-project-initial-policy"
  user = aws_iam_user.image_project_user.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "InitialPermissions",
        Effect = "Allow",
        Action = [
          "iam:CreateRole",
          "iam:AttachRolePolicy",
          "iam:PutRolePolicy",
          "s3:CreateBucket"
        ],
        Resource = "*"
      }
    ]
  })
}

# Access Key 발급
resource "aws_iam_access_key" "image_project_access_key" {
  user = aws_iam_user.image_project_user.name
}
