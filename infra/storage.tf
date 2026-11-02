resource "aws_s3_bucket" "storage" {
  bucket = "kiba-${local.project}"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    app = local.project
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.id
  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "storage" {
  bucket = aws_s3_bucket.storage.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "storage" {
  depends_on = [
    aws_s3_bucket_ownership_controls.storage,
    aws_s3_bucket_public_access_block.storage,
  ]
  bucket = aws_s3_bucket.storage.id
  acl = "public-read"
}

# NOTE(krishan711): cloudfront reads the bucket with origin access control
data "aws_iam_policy_document" "storage" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.storage.arn}/*"]
    principals {
      type = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test = "StringEquals"
      variable = "AWS:SourceArn"
      values = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "storage" {
  bucket = aws_s3_bucket.storage.id
  policy = data.aws_iam_policy_document.storage.json
}
