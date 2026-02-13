# ==========================================
# modules/ec2/variables.tf - EC2 모듈 입력 변수
# ==========================================

variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev, staging, prod)"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 타입 (예: t2.micro)"
  type        = string
}

variable "instance_count" {
  description = "생성할 인스턴스 수"
  type        = number
  default     = 1
}

variable "ami_id" {
  description = "사용할 AMI ID"
  type        = string
}

variable "subnet_ids" {
  description = "인스턴스를 배치할 서브넷 ID 목록"
  type        = list(string)
}

variable "security_group_id" {
  description = "적용할 Security Group ID"
  type        = string
}

variable "instance_profile_name" {
  description = "EC2에 연결할 IAM Instance Profile 이름"
  type        = string
}

variable "enable_detailed_monitoring" {
  description = "CloudWatch 상세 모니터링 활성화 여부"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
  default     = {}
}
