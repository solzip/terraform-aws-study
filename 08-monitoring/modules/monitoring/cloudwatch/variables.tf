# ==========================================
# modules/monitoring/cloudwatch/variables.tf
# ==========================================

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경"
  type        = string
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
}

variable "instance_id" {
  description = "모니터링 대상 EC2 인스턴스 ID"
  type        = string
}

variable "cpu_threshold" {
  description = "CPU 알람 임계값 (%)"
  type        = number
  default     = 80
}

variable "monitoring_topic_arn" {
  description = "일반 알림 SNS Topic ARN"
  type        = string
}

variable "critical_topic_arn" {
  description = "긴급 알림 SNS Topic ARN"
  type        = string
}

variable "app_log_group_name" {
  description = "애플리케이션 로그 그룹 이름 (Metric Filter용)"
  type        = string
}

variable "enable_dashboard" {
  description = "CloudWatch Dashboard 활성화 여부"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}
