# ==========================================
# modules/monitoring/cloudwatch/dashboards.tf
# ==========================================
#
# CloudWatch Dashboard(대시보드)란?
#   CloudWatch 메트릭을 시각적으로 표시하는
#   커스터마이즈 가능한 홈 페이지입니다.
#
# 대시보드의 구성 요소 (위젯):
#   - metric: 시계열 그래프 (라인, 스택, 바 차트)
#   - text: 마크다운 텍스트 (설명, 링크)
#   - alarm: 알람 상태 표시
#   - log: 로그 쿼리 결과
#
# 대시보드 크기:
#   - 가로: 24 열 (grid units)
#   - 세로: 무제한
#   - 각 위젯: width × height (grid units)
#
# 비용:
#   - 3개까지 무료
#   - 이후 대시보드당 $3.00/월

resource "aws_cloudwatch_dashboard" "main" {
  count = var.enable_dashboard ? 1 : 0

  dashboard_name = "${var.project_name}-${var.environment}-overview"

  # 대시보드 본문은 JSON 형식으로 정의합니다.
  # widgets 배열에 각 위젯을 정의합니다.
  dashboard_body = jsonencode({
    widgets = [
      # ==========================================
      # 위젯 1: 타이틀 텍스트
      # ==========================================
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# ${var.project_name} - ${var.environment} Environment Dashboard"
        }
      },

      # ==========================================
      # 위젯 2: CPU 사용률 그래프
      # ==========================================
      # 시간에 따른 CPU 사용률 변화를 라인 그래프로 표시
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 12 # 화면 절반
        height = 6
        properties = {
          title  = "CPU Utilization (%)"
          region = var.aws_region
          metrics = [
            # [네임스페이스, 메트릭이름, 차원키, 차원값]
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.instance_id]
          ]
          period  = 300 # 5분 간격
          stat    = "Average"
          view    = "timeSeries" # 시계열 그래프
          stacked = false        # 스택하지 않음
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
          # 알람 임계값 라인 표시
          annotations = {
            horizontal = [
              {
                label = "CPU Alarm Threshold"
                value = var.cpu_threshold
                color = "#ff0000" # 빨간색 점선
              }
            ]
          }
        }
      },

      # ==========================================
      # 위젯 3: 네트워크 트래픽 그래프
      # ==========================================
      {
        type   = "metric"
        x      = 12
        y      = 1
        width  = 12
        height = 6
        properties = {
          title  = "Network Traffic (Bytes)"
          region = var.aws_region
          metrics = [
            # NetworkIn과 NetworkOut을 같은 그래프에 표시
            ["AWS/EC2", "NetworkIn", "InstanceId", var.instance_id, { color = "#2ca02c", label = "In" }],
            ["AWS/EC2", "NetworkOut", "InstanceId", var.instance_id, { color = "#d62728", label = "Out" }]
          ]
          period = 300
          stat   = "Sum"
          view   = "timeSeries"
        }
      },

      # ==========================================
      # 위젯 4: 디스크 I/O 그래프
      # ==========================================
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6
        properties = {
          title  = "Disk I/O (Operations)"
          region = var.aws_region
          metrics = [
            ["AWS/EC2", "DiskReadOps", "InstanceId", var.instance_id, { label = "Read Ops" }],
            ["AWS/EC2", "DiskWriteOps", "InstanceId", var.instance_id, { label = "Write Ops" }]
          ]
          period = 300
          stat   = "Sum"
          view   = "timeSeries"
        }
      },

      # ==========================================
      # 위젯 5: 상태 확인 그래프
      # ==========================================
      {
        type   = "metric"
        x      = 12
        y      = 7
        width  = 12
        height = 6
        properties = {
          title  = "Status Check Failed"
          region = var.aws_region
          metrics = [
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", var.instance_id, { color = "#d62728" }],
            ["AWS/EC2", "StatusCheckFailed_Instance", "InstanceId", var.instance_id, { color = "#ff7f0e" }],
            ["AWS/EC2", "StatusCheckFailed_System", "InstanceId", var.instance_id, { color = "#9467bd" }]
          ]
          period = 60
          stat   = "Maximum"
          view   = "timeSeries"
          yAxis = {
            left = {
              min = 0
              max = 1
            }
          }
        }
      },

      # ==========================================
      # 위젯 6: 알람 상태 요약
      # ==========================================
      {
        type   = "text"
        x      = 0
        y      = 13
        width  = 24
        height = 2
        properties = {
          markdown = <<-MARKDOWN
## Alarm Status
| Alarm | Description | Threshold |
|-------|-------------|-----------|
| CPU High | CPU 사용률 경고 | ${var.cpu_threshold}% |
| Status Check | 인스턴스 상태 확인 실패 | 1회 |
| Network Out | 네트워크 아웃바운드 급증 | 100MB/5min |
| App Errors | 애플리케이션 에러 급증 | 10건/5min |
          MARKDOWN
        }
      }
    ]
  })
}
