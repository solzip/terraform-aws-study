# 초기 설정 가이드

> 01-basic 브랜치 실습을 위한 환경 설정 가이드

## 📋 사전 요구사항

- 컴퓨터: macOS, Windows, Linux
- 인터넷 연결
- AWS 계정
- 텍스트 에디터 (VSCode, IntelliJ 등)

## 1. Terraform 설치

### macOS
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform version
```

### Windows
```powershell
choco install terraform
terraform version
```

### Linux
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

## 2. AWS CLI 설정

```bash
# 설치
brew install awscli  # macOS
# 또는 https://aws.amazon.com/cli/

# 설정
aws configure
# AWS Access Key ID, Secret Key, Region 입력

# 확인
aws sts get-caller-identity
```

## 3. 프로젝트 초기화

```bash
cd 01-basic
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # 값 수정
terraform init
```

✅ 설정 완료!