# Local Development Environment

This repository contains a comprehensive Docker Compose setup for local development, including databases, message queues, monitoring tools, and other development services, all managed through Traefik reverse proxy.

## Prerequisites

- Docker Engine 20.10.0 or newer
- Docker Compose 2.0.0 or newer
- At least 16GB RAM recommended
- At least 50GB free disk space

## Quick Start

1. Clone this repository
2. Create a `prometheus.yml` file (see configuration section below)
3. Add the following entries to your `/etc/hosts` file:
```
127.0.0.1 mock.localhost rabbitmq.localhost mail.localhost pma.localhost minio.localhost minio-console.localhost jaeger.localhost adminer.localhost grafana.localhost prometheus.localhost auth.localhost vault.localhost jenkins.localhost sonar.localhost graylog.localhost zipkin.localhost consul.localhost
```
4. Run the environment:
```bash
docker-compose up -d
```
5. To stop all services:
```bash
docker-compose down
```

## Available Services

### Traefik Dashboard
| Service      | URL                         | Description                    |
|--------------|----------------------------|--------------------------------|
| Traefik      | http://localhost:8090      | Reverse proxy dashboard       |

### Databases
| Service      | Port  | Credentials            | Web Interface          |
|--------------|-------|------------------------|------------------------|
| MongoDB      | 27017 | None                  | No                    |
| PostgreSQL   | 5432  | postgres/postgres      | Via Adminer           |
| MySQL        | 3306  | root/root             | Via phpMyAdmin        |
| Redis        | 6379  | None                  | No                    |

### Database Management
| Service      | URL                         | Credentials             |
|--------------|----------------------------|-------------------------|
| phpMyAdmin   | http://pma.localhost       | root/root              |
| Adminer      | http://adminer.localhost   | Varies by DB           |

### Message Queues
| Service      | Port(s)     | Web Interface                | Credentials      |
|--------------|-------------|------------------------------|------------------|
| RabbitMQ     | 5672        | http://rabbitmq.localhost    | guest/guest     |
| Kafka        | 9092        | No                          | None            |
| Zookeeper    | 2181        | No                          | None            |

### Storage
| Service      | Port(s)     | Web Interface                     | Credentials         |
|--------------|-------------|-----------------------------------|---------------------|
| MinIO API    | 9000        | http://minio.localhost            | minioadmin/minioadmin|
| MinIO Console| 9001        | http://minio-console.localhost    | minioadmin/minioadmin|
| Memcached    | 11211       | No                               | None               |

### Monitoring & Tracing
| Service      | URL                         | Credentials             |
|--------------|----------------------------|-------------------------|
| Grafana      | http://grafana.localhost    | admin/admin            |
| Prometheus   | http://prometheus.localhost  | None                   |
| Jaeger       | http://jaeger.localhost     | None                   |
| Zipkin       | http://zipkin.localhost     | None                   |

### Search & Logging
| Service        | Port(s)           | Web Interface                | Credentials      |
|----------------|-------------------|------------------------------|------------------|
| Elasticsearch  | 9200, 9300        | N/A                         | None            |
| Graylog        | 12201, 1514       | http://graylog.localhost    | admin/admin     |

### Development Tools
| Service      | URL                         | Credentials             |
|--------------|----------------------------|-------------------------|
| Jenkins      | http://jenkins.localhost    | Set on first login     |
| SonarQube    | http://sonar.localhost     | admin/admin            |
| Vault        | http://vault.localhost      | root                   |
| Keycloak     | http://auth.localhost      | admin/admin            |
| Consul       | http://consul.localhost     | None                   |
| MailHog      | http://mail.localhost      | None                   |
| MockServer   | http://mock.localhost      | None                   |

## Configuration Files

### Prometheus Configuration
Create a `prometheus.yml` file in the same directory as your docker-compose.yml:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

## Memory Requirements

Some services require significant memory. Recommended minimum allocations:

- Elasticsearch: 2GB
- SonarQube: 2GB
- Jenkins: 2GB
- Graylog: 2GB
- Keycloak: 512MB
- Others: 4GB combined

Total recommended available memory: 16GB

## Common Operations

### Accessing Logs
```bash
# View logs for a specific service
docker-compose logs [service_name]

# Follow logs for a specific service
docker-compose logs -f [service_name]

# View Traefik logs
docker-compose logs traefik
```

### Data Persistence
All services use named volumes for data persistence. To clean up:
```bash
# Remove all volumes (WARNING: This deletes all data)
docker-compose down -v
```

### Scaling Services
Some services can be scaled:
```bash
# Scale a service to multiple instances (note: not all services support scaling)
docker-compose up -d --scale [service_name]=[number]
```

### Service Dependencies
- Graylog depends on MongoDB and Elasticsearch
- Grafana is configured to use Prometheus as a data source
- Kafka depends on Zookeeper
- phpMyAdmin depends on MySQL
- All services depend on Traefik for routing

## Troubleshooting

### Common Issues

1. **Service Won't Start**
   - Check logs: `docker-compose logs [service_name]`
   - Check Traefik logs: `docker-compose logs traefik`
   - Verify port availability: `netstat -tulpn | grep [port]`
   - Check memory usage: `docker stats`

2. **Memory Issues**
   - Increase Docker memory limit
   - Reduce Elasticsearch/Java heap sizes
   - Start fewer services

3. **DNS Resolution Issues**
   - Verify entries in `/etc/hosts`
   - Check Traefik dashboard for routing rules
   - Ensure DNS resolver can handle `.localhost` domains

4. **Traefik Routing Issues**
   - Check Traefik dashboard (http://localhost:8090)
   - Verify service labels in docker-compose.yml
   - Check service health and connectivity

### Health Checks

Most services expose health endpoints:
- Elasticsearch: http://localhost:9200/_cluster/health
- Consul: http://consul.localhost/v1/health/state/any
- RabbitMQ: http://rabbitmq.localhost/api/health/checks/virtual-hosts

## Security Note

This configuration is for development only. Services are configured without security for ease of use. Do not use in production without proper security configurations. Key considerations:

- Traefik dashboard is exposed without authentication
- Services use default or simple credentials
- Inter-service communication is not encrypted
- Volumes are not encrypted

## Maintenance

### Backup Volumes
```bash
# Create a backup directory
mkdir -p ./backups

# Backup a volume
docker run --rm -v [volume_name]:/source:ro -v $(pwd)/backups:/backup alpine tar -czf /backup/[volume_name].tar.gz -C /source .
```

### Update Images
```bash
# Pull latest versions of all images
docker-compose pull

# Rebuild and restart containers
docker-compose up -d --build
```

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details.