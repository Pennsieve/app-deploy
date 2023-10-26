// Lambda gateway function
// allow lambda to access resources in your AWS account
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

// attach policy to allow gateway lambda to start an ECS task and to write to Cloudwatch
resource "aws_iam_role_policy_attachment" "lambda_policy_ecs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}

resource "aws_iam_policy" "lambda_iam_policy" {
  name   = "lambda-iam-policy-${random_uuid.val.id}"
  path   = "/"
  policy = data.aws_iam_policy_document.iam_policy_document_gateway.json
}

// Post processor lambda
// allow lambda to access resources in your AWS account
data "aws_iam_policy_document" "post_processor_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_post_processor_lambda" {
  name               = "iam_for_post_processor_lambda"
  assume_role_policy = data.aws_iam_policy_document.post_processor_assume_role.json
}

// attach policy to allow post-processor lambda to write to Cloudwatch
resource "aws_iam_role_policy_attachment" "lambda_policy_post_processor" {
  role       = aws_iam_role.iam_for_post_processor_lambda.name
  policy_arn = aws_iam_policy.post_processor_lambda_iam_policy.arn
}

resource "aws_iam_policy" "post_processor_lambda_iam_policy" {
  name   = "post-processor-lambda-iam-policy-${random_uuid.val.id}"
  path   = "/"
  policy = data.aws_iam_policy_document.iam_policy_document_post_processor.json
}
