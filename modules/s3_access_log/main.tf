# Terraform module which creates S3 Bucket resources for Access Log on AWS.
#
# https://www.terraform.io/docs/providers/aws/r/s3_bucket.html
resource "aws_s3_bucket" "default" {

  # https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html#bucketnamingrules
  bucket = var.name

  # ACLs are disabled by default when Object Ownership is BucketOwnerEnforced.
  # Do not set ACLs; logging will work via bucket policy on the log target bucket.

  # https://docs.aws.amazon.com/AmazonS3/latest/dev/Versioning.html
  versioning {
    enabled = var.versioning_enabled
  }

  # S3 encrypts your data at the object level as it writes it to disks in its data centers
  # and decrypts it for you when you access it.
  # https://docs.aws.amazon.com/AmazonS3/latest/dev/serv-side-encryption.html
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        # The objects are encrypted using server-side encryption with either
        # Amazon S3-managed keys (SSE-S3) or AWS KMS-managed keys (SSE-KMS).
        # https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html
        sse_algorithm = "AES256"
      }
    }
  }

  # To manage your objects so that they are stored cost effectively throughout their lifecycle, configure their lifecycle.
  # https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html
  lifecycle_rule {
    enabled = var.lifecycle_rule_enabled
    prefix  = var.lifecycle_rule_prefix

    # The STANDARD_IA and ONEZONE_IA storage classes are designed for long-lived and infrequently accessed data.
    # https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html#sc-infreq-data-access
    transition {
      days          = var.standard_ia_transition_days
      storage_class = "STANDARD_IA"
    }

    # The GLACIER storage class is suitable for archiving data where data access is infrequent.
    # https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html#sc-glacier
    transition {
      days          = var.glacier_transition_days
      storage_class = "GLACIER"
    }

    # https://docs.aws.amazon.com/AmazonS3/latest/dev/intro-lifecycle-rules.html
    expiration {
      days = var.expiration_days
    }

    # Specifies when noncurrent objects transition to a specified storage class.
    # https://docs.aws.amazon.com/AmazonS3/latest/dev/intro-lifecycle-rules.html#intro-lifecycle-rules-actions
    noncurrent_version_transition {
      days          = var.glacier_noncurrent_version_transition_days
      storage_class = "GLACIER"
    }

    # Specifies when noncurrent object versions expire.
    # https://docs.aws.amazon.com/AmazonS3/latest/dev/intro-lifecycle-rules.html#intro-lifecycle-rules-actions
    noncurrent_version_expiration {
      days = var.noncurrent_version_expiration_days
    }
  }

  # A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error.
  # These objects are not recoverable.
  # https://www.terraform.io/docs/providers/aws/r/s3_bucket.html#force_destroy
  force_destroy = var.force_destroy

  # A mapping of tags to assign to the bucket.
  tags = var.tags
}