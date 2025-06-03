# Monitoring Stack for Multi-tenant Application

This directory contains the configuration for a comprehensive monitoring stack using:
- **Prometheus** for metrics collection
- **Grafana** for visualization
- **Node Exporter** for host metrics
- **cAdvisor** for container metrics
- **Blackbox Exporter** for HTTP/HTTPS endpoint monitoring

## Prerequisites

- Docker and Docker Compose
- Ports 3000, 9090, 8080, 9100, 9115 available

## Quick Start

1. Navigate to the monitoring directory:
   ```bash
   cd deploy/monitoring
   ```

2. Start the monitoring stack:
   ```bash
   ./start-monitoring.sh
   ```
   This will:
   - Create a `.env` file if it doesn't exist
   - Start all monitoring services
   - Print access information

3. Access the dashboards:
   - Grafana: http://localhost:3000
     - Username: admin
     - Password: (from .env file)
   - Prometheus: http://localhost:9090
   - cAdvisor: http://localhost:8080

## Configuration

### Environment Variables

Edit `.env` to customize:
- `GRAFANA_ADMIN_PASSWORD`: Admin password for Grafana
- Port mappings
- Other service-specific settings

### Adding New Services

1. **To monitor a new HTTP/HTTPS endpoint**:
   - Add the URL to `prometheus/prometheus.yml` under the `blackbox-http` job

2. **To add custom metrics**:
   - Configure your application to expose Prometheus metrics
   - Add a new job in `prometheus/prometheus.yml`

## Dashboards

### Included Dashboards

1. **Host Metrics**: CPU, memory, disk, and network usage
2. **Container Metrics**: Resource usage per container
3. **HTTP Endpoints**: Uptime and response times
4. **Custom Application Metrics**: (Add your own)

### Importing Dashboards

1. Go to Grafana > Create > Import
2. Use the dashboard ID or upload a JSON file
3. Select the Prometheus data source

## Alerting

### Pre-configured Alerts

- Instance down
- High memory usage
- High CPU usage
- High disk usage
- Endpoint down
- High response time

### Setting Up Notifications

1. In Grafana, go to Alerting > Notification channels
2. Add a new channel (Email, Slack, etc.)
3. Configure alert rules in `prometheus/alert.rules`

## Maintenance

### Updating the Stack

```bash
docker-compose pull
docker-compose up -d
```

### Stopping the Stack

```bash
docker-compose down
```

### Backing Up Data

```bash
# Backup Prometheus data
cp -r prometheus_data prometheus_data_backup_$(date +%Y%m%d)

# Backup Grafana data
cp -r grafana_data grafana_data_backup_$(date +%Y%m%d)
```

## Security Considerations

1. Change default passwords
2. Enable authentication for all services
3. Use HTTPS for all web interfaces
4. Restrict access to monitoring ports
5. Regularly update the stack components

## Troubleshooting

### View Logs

```bash
docker-compose logs -f
```

### Check Service Status

```bash
docker-compose ps
```

### Reset Admin Password

```bash
docker-compose exec grafana grafana-cli admin reset-admin-password newpassword
```
