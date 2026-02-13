#!/bin/bash
# ==========================================
# user_data.sh.tpl - EC2 초기 설정 스크립트 (템플릿)
# ==========================================
#
# 이 파일의 역할:
#   EC2 인스턴스가 처음 시작될 때 자동으로 실행됩니다.
#   웹 서버 설치, 상태 페이지 생성 등 초기 설정을 수행합니다.
#
# 템플릿 변수:
#   ${environment}   - 배포 환경 (dev/staging/prod)
#   ${instance_name} - 인스턴스 이름
#
# 주의: 이 스크립트는 root 권한으로 실행됩니다.

# 에러 발생 시 즉시 중단
set -e

# ==========================================
# Step 1: 시스템 업데이트
# ==========================================
echo ">>> Updating system packages..."
yum update -y

# ==========================================
# Step 2: 웹 서버 설치 (httpd = Apache)
# ==========================================
echo ">>> Installing and starting httpd..."
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# ==========================================
# Step 3: 상태 확인 페이지 생성
# ==========================================
# 간단한 HTML 페이지를 생성합니다.
# 이 페이지로 서버가 정상 동작하는지 확인할 수 있습니다.
cat > /var/www/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
    <title>Terraform AWS Study</title>
    <style>
        body { font-family: Arial; max-width: 600px; margin: 50px auto; padding: 20px; }
        .status { padding: 20px; border-radius: 8px; margin: 10px 0; }
        .healthy { background: #d4edda; border: 1px solid #c3e6cb; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        td { padding: 8px; border-bottom: 1px solid #eee; }
        td:first-child { font-weight: bold; width: 40%; }
    </style>
</head>
<body>
    <h1>Terraform AWS Study</h1>
    <div class="status healthy">
        Status: Healthy
    </div>
    <table>
        <tr><td>Environment</td><td>${environment}</td></tr>
        <tr><td>Instance</td><td>${instance_name}</td></tr>
        <tr><td>Managed By</td><td>Terraform</td></tr>
    </table>
</body>
</html>
HTMLEOF

echo ">>> Setup complete!"
