# Monitoring and Alerting System

This directory contains the configuration and scripts for monitoring your multi-tenant application.

## Setup

1. **Required Secrets** (set in GitHub Secrets):
   - `SLACK_WEBHOOK_URL`: For Slack notifications (optional)
   - `ALERT_EMAIL`: For email alerts (requires SMTP setup)

2. **Configuration** (`deploy/config/monitoring.yaml`):
   - Update `alert_email` with your email
   - Configure health check endpoints
   - Set alert thresholds

## Usage

### Manual Monitoring

Check a specific entity:
```bash
./deploy/scripts/monitor.sh entity1
```

Check all entities:
```bash
for config in ./deploy/config/*.yaml; do
  if [ "$(basename "$config")" != "monitoring.yaml" ]; then
    ./deploy/scripts/monitor.sh "$(basename "$config" .yaml)"
  fi
done
```

### GitHub Actions

- **Scheduled Monitoring**: Runs every 5 minutes
- **Manual Trigger**: Go to Actions > Monitor Entities > Run workflow

## Alerting

Alerts are sent for:
- Service downtime
- High response times
- Error rates exceeding thresholds

### Alert Destinations:
1. **Slack**: Configured via webhook
2. **Email**: Requires SMTP setup

## Monitoring Dashboard

Access monitoring logs in GitHub Actions under the "monitoring-logs" artifact.

## Customization

1. **Health Checks**:
   - Update `health_checks` in `monitoring.yaml`
   - Add custom endpoints as needed

2. **Alert Thresholds**:
   - Adjust values in `alert_thresholds`
   - Set appropriate values for your SLA

3. **Notification Templates**:
   - Modify templates in `monitoring.yaml`
   - Customize messages for different alert types
