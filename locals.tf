locals {
  tags = {
  }

  basename      = "${var.prefix}-${random_string.postfix.result}"
  safe_basename = replace(local.basename, "-", "")
}