# modules/ec2/variables.tf
# EC2 모듈 입력 변수

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 구분 (dev, staging, prod)"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = contains(["t2.micro", "t2.small", "t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "허용된 인스턴스 타입: t2.micro, t2.small, t3.micro, t3.small, t3.medium"
  }
}

variable "ami_id" {
  description = "사용할 AMI ID (null이면 최신 Amazon Linux 2023 자동 선택)"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "인스턴스를 배포할 Subnet ID"
  type        = string
}

variable "security_group_ids" {
  description = "연결할 Security Group ID 목록"
  type        = list(string)
}

variable "root_volume_size" {
  description = "루트 볼륨 크기 (GB)"
  type        = number
  default     = 8

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 30
    error_message = "루트 볼륨 크기는 8~30GB 사이여야 합니다."
  }
}

variable "enable_monitoring" {
  description = "상세 모니터링 활성화 여부"
  type        = bool
  default     = false
}

variable "user_data" {
  description = "인스턴스 시작 시 실행할 User Data 스크립트"
  type        = string
  default     = null
}

variable "additional_tags" {
  description = "추가 태그"
  type        = map(string)
  default     = {}
}
