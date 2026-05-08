variable "project" {
  type        = string
  default     = "enechange-coding-challenge"
  description = "プロジェクト識別子。リソース名のプレフィックスに使用"
}

variable "env" {
  type        = string
  default     = "prod"
  description = "環境識別子 (prod / stg など)"
}

variable "region" {
  type        = string
  default     = "ap-northeast-1"
  description = "AWS リージョン"
}

variable "rails_image" {
  type        = string
  description = "Rails API Docker image URI (ECR)"
}

variable "cors_allowed_origins" {
  type        = string
  description = "CORS を許可するオリジン (例: https://your-app.vercel.app)"
}

variable "origin_verify_secret" {
  type        = string
  sensitive   = true
  description = "CloudFront → ALB 間の X-Origin-Verify ヘッダー値。推測困難な値を設定すること"
}
