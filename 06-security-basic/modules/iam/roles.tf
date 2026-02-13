# ==========================================
# modules/iam/roles.tf - IAM Role 및 Instance Profile 정의
# ==========================================
#
# IAM Role이란?
# - AWS 리소스(EC2, Lambda 등)에게 "권한"을 부여하는 방법
# - 사람에게 주는 것이 아니라 "서비스"에게 주는 역할
# - Access Key 없이도 AWS API를 호출할 수 있게 해줌
#
# 왜 IAM Role을 사용하는가?
# - EC2 인스턴스에서 S3에 접근해야 할 때
#   나쁜 방법: Access Key를 인스턴스에 하드코딩 (보안 위험!)
#   좋은 방법: IAM Role을 부여 (자동으로 임시 자격증명 발급)
#
# Role의 구성:
#   1. Trust Policy (신뢰 정책) - 누가 이 Role을 사용할 수 있는가?
#   2. Permission Policy (권한 정책) - 이 Role로 무엇을 할 수 있는가?

# ==========================================
# EC2용 IAM Role
# ==========================================
#
# 이 Role은 EC2 인스턴스가 사용합니다.
# EC2가 S3, CloudWatch Logs 등에 접근할 수 있도록 합니다.

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  # Trust Policy (신뢰 정책)
  # "누가 이 Role을 사용(assume)할 수 있는가?"를 정의
  #
  # 아래 정책은 "EC2 서비스가 이 Role을 사용할 수 있다"는 의미
  # 즉, EC2 인스턴스만이 이 Role의 권한을 행사할 수 있습니다
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Effect: "Allow" = 허용
        Effect = "Allow"

        # Principal: 이 Role을 사용할 수 있는 주체
        # "ec2.amazonaws.com" = AWS EC2 서비스
        Principal = {
          Service = "ec2.amazonaws.com"
        }

        # Action: "sts:AssumeRole" = 역할 수임 (Role을 사용하겠다는 동작)
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.common_tags
}

# ==========================================
# IAM Instance Profile
# ==========================================
#
# Instance Profile이란?
# - IAM Role을 EC2 인스턴스에 연결하기 위한 "컨테이너"
# - EC2에 직접 Role을 연결할 수 없고, Instance Profile을 통해 연결
# - 1개의 Instance Profile에 1개의 Role만 연결 가능
#
# 관계:
#   EC2 Instance → Instance Profile → IAM Role → Policies

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"

  # 위에서 생성한 IAM Role을 이 Profile에 연결
  role = aws_iam_role.ec2_role.name

  tags = var.common_tags
}
