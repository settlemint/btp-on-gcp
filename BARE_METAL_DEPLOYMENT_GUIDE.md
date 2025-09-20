# SettleMint Blockchain Transformation Platform - Bare Metal Deployment Guide

## Table of Contents

- [Overview](#overview)
- [Architecture Options](#architecture-options)
- [Prerequisites](#prerequisites)
- [Hardware Requirements](#hardware-requirements)
- [Operating System Setup](#operating-system-setup)
- [Installation Methods](#installation-methods)
- [Network Configuration](#network-configuration)
- [Security Hardening](#security-hardening)
- [Monitoring & Logging](#monitoring--logging)
- [Backup & Recovery](#backup--recovery)
- [Troubleshooting](#troubleshooting)
- [Production Considerations](#production-considerations)

## Overview

> **⚠️ IMPORTANT DISCLAIMER**
> 
> This guide is provided for **educational and demonstration purposes only**. For production deployments, official support, and enterprise implementations, please contact the **SettleMint team** directly.
> 
> **Contact SettleMint:**
> - Website: [www.settlemint.com](https://www.settlemint.com)
> - Email: support@settlemint.com
> - Documentation: [docs.settlemint.com](https://docs.settlemint.com)

This guide provides comprehensive instructions for deploying **SettleMint's Blockchain Transformation Platform (BTP)** on bare metal infrastructure without any managed cloud services. This approach offers maximum control, customization, and data sovereignty while requiring complete infrastructure management.

### Key Benefits of Bare Metal Deployment

| Benefit | Description | Use Cases |
|---------|-------------|-----------|
| **Complete Control** | Full control over hardware, OS, and software stack | Regulatory compliance, custom optimizations |
| **Data Sovereignty** | All data remains on-premises | Financial institutions, government agencies |
| **Cost Predictability** | No variable cloud costs, fixed infrastructure expenses | Long-term deployments, budget certainty |
| **Performance Optimization** | Direct hardware access, no virtualization overhead | High-performance blockchain workloads |
| **Network Isolation** | Complete network control and air-gapped deployments | Security-sensitive environments |
| **Customization** | Custom hardware configurations and specialized setups | GPU mining, specialized storage arrays |

### Deployment Complexity Matrix

| Complexity Level | Infrastructure Size | Recommended For | Time to Deploy |
|------------------|-------------------|-----------------|----------------|
| **Minimal** | Single server | Development, testing | 4-8 hours |
| **Standard** | 3-5 servers | Small production | 1-2 days |
| **Enterprise** | 10+ servers | Large production | 3-7 days |
| **High Availability** | 15+ servers across sites | Mission-critical | 1-2 weeks |

## Architecture Options

### Option 1: Single Server Deployment (Minimal)

```mermaid
graph TD
    USERS[👥 Users<br/>Web Browser<br/>Mobile App]
    
    subgraph SERVER["🖥️ Single Server (32GB RAM, 8 CPU)"]
        NGINX[🔀 NGINX Proxy<br/>SSL Termination<br/>Load Balancing<br/>Rate Limiting]
        
        subgraph CONTAINERS["🐳 Docker Containers"]
            BTP[🚀 BTP Platform<br/>Web UI<br/>API Services<br/>Deployment Engine]
            POSTGRES[🗄️ PostgreSQL<br/>Primary Database<br/>ACID Compliance<br/>Backup & Recovery]
            REDIS[⚡ Redis Cache<br/>Session Storage<br/>Real-time Data<br/>Message Queue]
            VAULT[🔒 HashiCorp Vault<br/>Secrets Management<br/>Encryption Keys<br/>Policy Engine]
            MONITORING[📊 Monitoring Stack<br/>Prometheus<br/>Grafana<br/>Alertmanager]
        end
        
        subgraph STORAGE["💾 Storage Layer"]
            DATA[📁 Data Volume<br/>500GB NVMe SSD<br/>Application Data<br/>Database Files]
            BACKUP[💾 Backup Volume<br/>1TB SATA HDD<br/>Automated Backups<br/>Archive Storage]
            LOGS[📋 Log Volume<br/>100GB SSD<br/>Application Logs<br/>Audit Trails]
        end
    end
    
    %% User Flow
    USERS --> NGINX
    NGINX --> BTP
    
    %% Application Flow
    BTP --> POSTGRES
    BTP --> REDIS
    BTP --> VAULT
    
    %% Storage Flow
    POSTGRES --> DATA
    REDIS --> DATA
    VAULT --> DATA
    BTP --> LOGS
    MONITORING --> BACKUP
    
    %% Monitoring Flow
    MONITORING --> POSTGRES
    MONITORING --> REDIS
    MONITORING --> VAULT
    MONITORING --> BTP
    
    %% Styling
    classDef user fill:#e3f2fd,stroke:#1976d2,stroke-width:3px,color:#000,font-weight:bold
    classDef proxy fill:#f3e5f5,stroke:#7b1fa2,stroke-width:3px,color:#fff,font-weight:bold
    classDef application fill:#ff6b35,stroke:#e55100,stroke-width:3px,color:#fff,font-weight:bold
    classDef database fill:#4caf50,stroke:#2e7d32,stroke-width:3px,color:#fff,font-weight:bold
    classDef cache fill:#ff9800,stroke:#f57c00,stroke-width:3px,color:#fff,font-weight:bold
    classDef security fill:#9c27b0,stroke:#7b1fa2,stroke-width:3px,color:#fff,font-weight:bold
    classDef monitoring fill:#00bcd4,stroke:#0097a7,stroke-width:3px,color:#fff,font-weight:bold
    classDef storage fill:#795548,stroke:#5d4037,stroke-width:3px,color:#fff,font-weight:bold
    
    class USERS user
    class NGINX proxy
    class BTP application
    class POSTGRES database
    class REDIS cache
    class VAULT security
    class MONITORING monitoring
    class DATA,BACKUP,LOGS storage
```

**Specifications:**
- **CPU:** 8 cores / 16 threads minimum
- **RAM:** 32GB minimum
- **Storage:** 500GB SSD + 1TB HDD
- **Network:** 1Gbps ethernet
- **Use Case:** Development, small teams

### Option 2: Multi-Server Standard Deployment

```mermaid
graph TB
    subgraph "Load Balancer Server"
        LB[NGINX Load Balancer<br/>+ SSL Termination]
    end
    
    subgraph "Application Servers (2x)"
        APP1[BTP App Server 1<br/>- Web UI<br/>- API Services]
        APP2[BTP App Server 2<br/>- Web UI<br/>- API Services]
    end
    
    subgraph "Database Server"
        DB[PostgreSQL Primary<br/>+ Streaming Replication]
    end
    
    subgraph "Cache Server"
        CACHE[Redis Cluster<br/>High Availability]
    end
    
    subgraph "Storage Server"
        STORAGE[NFS/GlusterFS<br/>Shared Storage]
    end
    
    USERS[Users] --> LB
    LB --> APP1
    LB --> APP2
    APP1 --> DB
    APP2 --> DB
    APP1 --> CACHE
    APP2 --> CACHE
    APP1 --> STORAGE
    APP2 --> STORAGE
```

**Server Specifications:**
- **Load Balancer:** 4 cores, 8GB RAM, 100GB SSD
- **App Servers:** 8 cores, 32GB RAM, 200GB SSD (each)
- **Database Server:** 16 cores, 64GB RAM, 1TB SSD
- **Cache Server:** 8 cores, 16GB RAM, 200GB SSD
- **Storage Server:** 8 cores, 16GB RAM, 4TB RAID array

### Option 3: Enterprise High Availability Deployment

```mermaid
graph TB
    subgraph "DMZ Network"
        subgraph "Load Balancer Cluster"
            LB1[HAProxy Primary<br/>+ Keepalived]
            LB2[HAProxy Secondary<br/>+ Keepalived]
        end
        VIP[Virtual IP<br/>Floating]
    end
    
    subgraph "Application Tier"
        subgraph "Kubernetes Cluster"
            MASTER1[K8s Master 1]
            MASTER2[K8s Master 2]
            MASTER3[K8s Master 3]
            WORKER1[K8s Worker 1]
            WORKER2[K8s Worker 2]
            WORKER3[K8s Worker 3]
        end
    end
    
    subgraph "Database Tier"
        subgraph "PostgreSQL Cluster"
            PGPRIMARY[PostgreSQL Primary]
            PGREPLICA1[PostgreSQL Replica 1]
            PGREPLICA2[PostgreSQL Replica 2]
        end
        
        subgraph "Redis Cluster"
            REDIS1[Redis Node 1]
            REDIS2[Redis Node 2]
            REDIS3[Redis Node 3]
        end
    end
    
    subgraph "Storage Tier"
        subgraph "Distributed Storage"
            CEPH1[Ceph OSD 1]
            CEPH2[Ceph OSD 2]
            CEPH3[Ceph OSD 3]
        end
    end
    
    subgraph "Management Tier"
        MONITORING[Monitoring Stack<br/>Prometheus, Grafana]
        LOGGING[Logging Stack<br/>ELK/EFK]
        BACKUP[Backup Server<br/>Bacula/Bareos]
    end
    
    USERS --> VIP
    VIP --> LB1
    VIP --> LB2
    LB1 --> WORKER1
    LB1 --> WORKER2
    LB1 --> WORKER3
    LB2 --> WORKER1
    LB2 --> WORKER2
    LB2 --> WORKER3
    
    WORKER1 --> PGPRIMARY
    WORKER2 --> PGPRIMARY
    WORKER3 --> PGPRIMARY
    PGPRIMARY --> PGREPLICA1
    PGPRIMARY --> PGREPLICA2
    
    WORKER1 --> REDIS1
    WORKER2 --> REDIS2
    WORKER3 --> REDIS3
    
    WORKER1 --> CEPH1
    WORKER2 --> CEPH2
    WORKER3 --> CEPH3
```

## Prerequisites

### Required Expertise

| Skill Area | Level Required | Responsibilities |
|------------|----------------|------------------|
| **Linux Administration** | Advanced | OS setup, package management, security |
| **Networking** | Intermediate | VLANs, firewalls, DNS configuration |
| **Database Administration** | Intermediate | PostgreSQL setup, backup, tuning |
| **Container Technologies** | Advanced | Docker, Kubernetes (for complex setups) |
| **Security Hardening** | Advanced | SSL/TLS, firewall rules, access control |
| **Monitoring & Logging** | Intermediate | Prometheus, Grafana, log aggregation |

### Tools and Software

| Category | Required Tools | Optional Tools |
|----------|----------------|----------------|
| **Operating System** | Ubuntu 22.04 LTS, RHEL 9, CentOS Stream 9 | Debian 12, Rocky Linux 9 |
| **Containerization** | Docker CE, Docker Compose | Podman, Kubernetes |
| **Database** | PostgreSQL 15+ | PostgreSQL clustering tools |
| **Proxy/Load Balancer** | NGINX, HAProxy | Traefik, Envoy |
| **Monitoring** | Prometheus, Grafana | Zabbix, Nagios |
| **Backup** | rsync, tar, pg_dump | Bacula, Bareos, Restic |

## Hardware Requirements

### Minimum Requirements (Single Server)

| Component | Specification | Notes |
|-----------|---------------|-------|
| **CPU** | 8 cores @ 2.4GHz | Intel Xeon or AMD EPYC recommended |
| **RAM** | 32GB DDR4 | ECC memory preferred |
| **Storage** | 500GB NVMe SSD | For OS, applications, and database |
| **Network** | 1Gbps Ethernet | Redundant NICs recommended |
| **Power** | Redundant PSU | UPS recommended |

### Recommended Production (Multi-Server)

#### Load Balancer Servers (2x)
| Component | Specification | Purpose |
|-----------|---------------|---------|
| **CPU** | 4 cores @ 2.4GHz | HAProxy, SSL termination |
| **RAM** | 8GB DDR4 | Connection state tracking |
| **Storage** | 100GB SSD | OS and logs |
| **Network** | 2x 1Gbps (bonded) | High availability |

#### Application Servers (3x)
| Component | Specification | Purpose |
|-----------|---------------|---------|
| **CPU** | 16 cores @ 2.8GHz | BTP application processing |
| **RAM** | 64GB DDR4 | Application memory, caching |
| **Storage** | 500GB NVMe SSD | OS, applications, temp data |
| **Network** | 2x 10Gbps (bonded) | High throughput |

#### Database Servers (3x)
| Component | Specification | Purpose |
|-----------|---------------|---------|
| **CPU** | 24 cores @ 3.0GHz | Database processing |
| **RAM** | 128GB DDR4 ECC | Database buffer cache |
| **Storage** | 2TB NVMe SSD RAID 10 | Database files |
| **Network** | 2x 10Gbps (bonded) | Database replication |

#### Storage Servers (3x)
| Component | Specification | Purpose |
|-----------|---------------|---------|
| **CPU** | 12 cores @ 2.4GHz | Storage processing |
| **RAM** | 32GB DDR4 | Storage cache |
| **Storage** | 8TB SAS RAID 6 | Bulk storage |
| **Network** | 2x 10Gbps (bonded) | Storage traffic |

### Storage Architecture Options

#### Option 1: Direct Attached Storage (DAS)
```bash
# RAID 10 for performance and redundancy
mdadm --create --verbose /dev/md0 --level=10 --raid-devices=4 /dev/sda /dev/sdb /dev/sdc /dev/sdd

# LVM for flexible volume management
pvcreate /dev/md0
vgcreate btp-vg /dev/md0
lvcreate -L 100G -n postgres-lv btp-vg
lvcreate -L 50G -n redis-lv btp-vg
lvcreate -L 200G -n app-lv btp-vg
```

#### Option 2: Network Attached Storage (NFS)
```bash
# NFS Server setup
apt install nfs-kernel-server
mkdir -p /export/btp/{postgres,redis,app,backups}
echo "/export/btp 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
exportfs -a
systemctl enable --now nfs-kernel-server

# Client mount
mount -t nfs 192.168.1.100:/export/btp/postgres /var/lib/postgresql
```

#### Option 3: Distributed Storage (Ceph)
```bash
# Ceph cluster setup (simplified)
apt install ceph ceph-osd ceph-mon ceph-mgr

# Initialize monitors
ceph-deploy new node1 node2 node3
ceph-deploy install node1 node2 node3
ceph-deploy mon create-initial
ceph-deploy admin node1 node2 node3
ceph-deploy mgr create node1

# Create OSDs
ceph-deploy osd create --data /dev/sdb node1
ceph-deploy osd create --data /dev/sdb node2
ceph-deploy osd create --data /dev/sdb node3
```

## Operating System Setup

### Ubuntu 22.04 LTS Setup

#### Base System Installation
```bash
# Update system
apt update && apt upgrade -y

# Install essential packages
apt install -y curl wget gnupg2 software-properties-common \
    apt-transport-https ca-certificates lsb-release \
    vim htop iotop nethogs iftop \
    build-essential git unzip \
    fail2ban ufw logrotate \
    ntp chrony

# Configure timezone
timedatectl set-timezone UTC

# Configure NTP
systemctl enable --now chrony
```

#### Network Configuration
```bash
# Static IP configuration (/etc/netplan/01-netcfg.yaml)
cat > /etc/netplan/01-netcfg.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
    enp0s8:
      addresses:
        - 10.0.0.100/24
  bonds:
    bond0:
      interfaces:
        - enp0s3
        - enp0s8
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      parameters:
        mode: active-backup
        primary: enp0s3
EOF

netplan apply
```

#### Security Hardening
```bash
# Configure firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

# SSH hardening
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
systemctl restart sshd

# Configure fail2ban
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = 2222
EOF

systemctl enable --now fail2ban
```

### RHEL/CentOS Setup

#### Base System Installation
```bash
# Update system
dnf update -y

# Install EPEL repository
dnf install -y epel-release

# Install essential packages
dnf install -y curl wget gnupg2 \
    vim htop iotop nethogs iftop \
    gcc gcc-c++ make git unzip \
    firewalld fail2ban logrotate \
    chrony

# Configure SELinux
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

# Configure timezone
timedatectl set-timezone UTC
```

## Installation Methods

### Method 1: Docker Compose (Recommended for Single Server)

#### Docker Installation
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Add user to docker group
usermod -aG docker $USER
```

#### Docker Compose Configuration
```yaml
# docker-compose.yml
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    container_name: btp-postgres
    environment:
      POSTGRES_DB: btp
      POSTGRES_USER: btp_user
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_INITDB_ARGS: "--auth-host=scram-sha-256 --auth-local=scram-sha-256"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./postgres/postgresql.conf:/etc/postgresql/postgresql.conf
      - ./postgres/pg_hba.conf:/etc/postgresql/pg_hba.conf
    ports:
      - "5432:5432"
    networks:
      - btp-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U btp_user -d btp"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: btp-redis
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
    volumes:
      - redis_data:/data
      - ./redis/redis.conf:/usr/local/etc/redis/redis.conf
    ports:
      - "6379:6379"
    networks:
      - btp-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # HashiCorp Vault
  vault:
    image: vault:1.15
    container_name: btp-vault
    environment:
      VAULT_ADDR: http://0.0.0.0:8200
      VAULT_API_ADDR: http://0.0.0.0:8200
      VAULT_LOCAL_CONFIG: |
        ui = true
        listener "tcp" {
          address = "0.0.0.0:8200"
          tls_disable = 1
        }
        storage "file" {
          path = "/vault/data"
        }
        default_lease_ttl = "168h"
        max_lease_ttl = "720h"
    volumes:
      - vault_data:/vault/data
      - vault_logs:/vault/logs
      - ./vault/config:/vault/config
    ports:
      - "8200:8200"
    networks:
      - btp-network
    cap_add:
      - IPC_LOCK
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8200/v1/sys/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # MinIO Object Storage
  minio:
    image: minio/minio:latest
    container_name: btp-minio
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}
    command: server /data --console-address ":9001"
    volumes:
      - minio_data:/data
    ports:
      - "9000:9000"
      - "9001:9001"
    networks:
      - btp-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

  # NGINX Reverse Proxy
  nginx:
    image: nginx:alpine
    container_name: btp-nginx
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./ssl:/etc/nginx/ssl
      - nginx_logs:/var/log/nginx
    ports:
      - "80:80"
      - "443:443"
    networks:
      - btp-network
    depends_on:
      - btp-app
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # SettleMint BTP Application
  btp-app:
    image: registry.settlemint.com/settlemint-platform/settlemint:${BTP_VERSION}
    container_name: btp-app
    environment:
      DATABASE_URL: postgresql://btp_user:${POSTGRES_PASSWORD}@postgres:5432/btp
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379
      VAULT_ADDR: http://vault:8200
      VAULT_TOKEN: ${VAULT_TOKEN}
      MINIO_ENDPOINT: minio:9000
      MINIO_ACCESS_KEY: ${MINIO_ROOT_USER}
      MINIO_SECRET_KEY: ${MINIO_ROOT_PASSWORD}
      OAUTH_CLIENT_ID: ${OAUTH_CLIENT_ID}
      OAUTH_CLIENT_SECRET: ${OAUTH_CLIENT_SECRET}
      JWT_SECRET: ${JWT_SECRET}
      ENCRYPTION_KEY: ${ENCRYPTION_KEY}
      NODE_ENV: production
    volumes:
      - app_data:/app/data
      - app_logs:/app/logs
    networks:
      - btp-network
    depends_on:
      - postgres
      - redis
      - vault
      - minio
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"

  # Prometheus Monitoring
  prometheus:
    image: prom/prometheus:latest
    container_name: btp-prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    networks:
      - btp-network
    restart: unless-stopped

  # Grafana Dashboard
  grafana:
    image: grafana/grafana:latest
    container_name: btp-grafana
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD}
      GF_INSTALL_PLUGINS: grafana-clock-panel,grafana-simple-json-datasource
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    ports:
      - "3000:3000"
    networks:
      - btp-network
    restart: unless-stopped

volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/btp/data/postgres
  redis_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/btp/data/redis
  vault_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/btp/data/vault
  vault_logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/btp/logs/vault
  minio_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/btp/data/minio
  app_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/btp/data/app
  app_logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/btp/logs/app
  nginx_logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/btp/logs/nginx
  prometheus_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/btp/data/prometheus
  grafana_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/btp/data/grafana

networks:
  btp-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

#### Environment Configuration
```bash
# .env file
# Database Configuration
POSTGRES_PASSWORD=your_secure_postgres_password_here
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=btp
POSTGRES_USER=btp_user

# Redis Configuration
REDIS_PASSWORD=your_secure_redis_password_here
REDIS_HOST=redis
REDIS_PORT=6379

# Vault Configuration
VAULT_TOKEN=your_vault_root_token_here

# MinIO Configuration
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=your_secure_minio_password_here

# BTP Application Configuration
BTP_VERSION=v7.6.19
OAUTH_CLIENT_ID=your_oauth_client_id
OAUTH_CLIENT_SECRET=your_oauth_client_secret
JWT_SECRET=your_jwt_secret_32_chars_minimum
ENCRYPTION_KEY=your_encryption_key_32_chars

# Monitoring
GRAFANA_PASSWORD=your_secure_grafana_password
```

#### Deployment Script
```bash
#!/bin/bash
# deploy-btp.sh

set -e

echo "🚀 Starting BTP Bare Metal Deployment..."

# Create directory structure
mkdir -p /opt/btp/{data/{postgres,redis,vault,minio,app,prometheus,grafana},logs/{vault,app,nginx},config/{nginx,prometheus,grafana}}

# Set permissions
chown -R 999:999 /opt/btp/data/postgres
chown -R 999:999 /opt/btp/data/redis
chown -R 100:1000 /opt/btp/data/vault
chown -R 1000:1000 /opt/btp/data/minio
chown -R 472:472 /opt/btp/data/grafana

# Generate secrets if not provided
if [ -z "$POSTGRES_PASSWORD" ]; then
    export POSTGRES_PASSWORD=$(openssl rand -base64 32)
    echo "Generated PostgreSQL password: $POSTGRES_PASSWORD"
fi

if [ -z "$REDIS_PASSWORD" ]; then
    export REDIS_PASSWORD=$(openssl rand -base64 32)
    echo "Generated Redis password: $REDIS_PASSWORD"
fi

if [ -z "$JWT_SECRET" ]; then
    export JWT_SECRET=$(openssl rand -base64 32)
    echo "Generated JWT secret: $JWT_SECRET"
fi

# Create SSL certificates
if [ ! -f ./ssl/server.crt ]; then
    echo "📜 Generating SSL certificates..."
    mkdir -p ./ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ./ssl/server.key \
        -out ./ssl/server.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=btp.local"
fi

# Start services
echo "🐳 Starting Docker services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Initialize Vault
echo "🔐 Initializing Vault..."
docker exec btp-vault vault operator init -key-shares=5 -key-threshold=3 > vault-keys.txt

# Extract root token and unseal keys
ROOT_TOKEN=$(grep 'Initial Root Token:' vault-keys.txt | awk '{print $NF}')
UNSEAL_KEY1=$(grep 'Unseal Key 1:' vault-keys.txt | awk '{print $NF}')
UNSEAL_KEY2=$(grep 'Unseal Key 2:' vault-keys.txt | awk '{print $NF}')
UNSEAL_KEY3=$(grep 'Unseal Key 3:' vault-keys.txt | awk '{print $NF}')

# Unseal Vault
docker exec btp-vault vault operator unseal $UNSEAL_KEY1
docker exec btp-vault vault operator unseal $UNSEAL_KEY2
docker exec btp-vault vault operator unseal $UNSEAL_KEY3

# Configure Vault
docker exec -e VAULT_TOKEN=$ROOT_TOKEN btp-vault vault auth enable userpass
docker exec -e VAULT_TOKEN=$ROOT_TOKEN btp-vault vault secrets enable -path=ethereum kv-v2
docker exec -e VAULT_TOKEN=$ROOT_TOKEN btp-vault vault secrets enable -path=fabric kv-v2
docker exec -e VAULT_TOKEN=$ROOT_TOKEN btp-vault vault secrets enable -path=ipfs kv-v2

echo "✅ BTP deployment completed!"
echo "📋 Access Information:"
echo "   - BTP Platform: https://localhost"
echo "   - Grafana: http://localhost:3000 (admin/admin)"
echo "   - Prometheus: http://localhost:9090"
echo "   - MinIO Console: http://localhost:9001"
echo "   - Vault UI: http://localhost:8200"
echo ""
echo "🔑 Important: Save the vault-keys.txt file securely!"
echo "🔑 Root Token: $ROOT_TOKEN"
```

### Method 2: Kubernetes Deployment (Multi-Server)

#### Kubernetes Cluster Setup with kubeadm

##### Master Node Setup
```bash
# Install container runtime (containerd)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update && apt install -y containerd.io

# Configure containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd

# Install kubeadm, kubelet, kubectl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt update && apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Initialize cluster
kubeadm init --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint=k8s-master:6443

# Configure kubectl
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Install CNI (Flannel)
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

##### Worker Node Setup
```bash
# Install container runtime and kubernetes components (same as master)
# Join cluster using token from master
kubeadm join k8s-master:6443 --token <token> --discovery-token-ca-cert-hash <hash>
```

#### BTP Kubernetes Manifests

##### Namespace
```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: btp-platform
  labels:
    name: btp-platform
```

##### PostgreSQL Deployment
```yaml
# postgres.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: btp-platform
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: local-storage
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: btp-platform
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15
        env:
        - name: POSTGRES_DB
          value: "btp"
        - name: POSTGRES_USER
          value: "btp_user"
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: btp-secrets
              key: postgres-password
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "2Gi"
            cpu: "500m"
          limits:
            memory: "4Gi"
            cpu: "1000m"
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: btp-platform
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
```

##### Redis Deployment
```yaml
# redis.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-pvc
  namespace: btp-platform
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: btp-platform
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        command:
        - redis-server
        - --requirepass
        - $(REDIS_PASSWORD)
        - --appendonly
        - "yes"
        env:
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: btp-secrets
              key: redis-password
        ports:
        - containerPort: 6379
        volumeMounts:
        - name: redis-storage
          mountPath: /data
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: redis-storage
        persistentVolumeClaim:
          claimName: redis-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: btp-platform
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
```

### Method 3: Manual Binary Installation

#### PostgreSQL Manual Installation
```bash
# Install PostgreSQL from source
wget https://ftp.postgresql.org/pub/source/v15.4/postgresql-15.4.tar.gz
tar xzf postgresql-15.4.tar.gz
cd postgresql-15.4

# Configure and compile
./configure --prefix=/usr/local/pgsql --with-openssl
make && make install

# Create postgres user
useradd -m postgres

# Initialize database
su - postgres
/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data

# Start PostgreSQL
/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data -l /usr/local/pgsql/data/postgresql.log start

# Create BTP database and user
/usr/local/pgsql/bin/createdb btp
/usr/local/pgsql/bin/psql -c "CREATE USER btp_user WITH PASSWORD 'secure_password';"
/usr/local/pgsql/bin/psql -c "GRANT ALL PRIVILEGES ON DATABASE btp TO btp_user;"
```

#### Redis Manual Installation
```bash
# Install Redis from source
wget https://download.redis.io/redis-stable.tar.gz
tar xzf redis-stable.tar.gz
cd redis-stable
make && make install

# Create redis user
useradd -r -s /bin/false redis

# Create directories
mkdir -p /etc/redis /var/lib/redis /var/log/redis
chown redis:redis /var/lib/redis /var/log/redis

# Configure Redis
cat > /etc/redis/redis.conf << EOF
bind 127.0.0.1
port 6379
dir /var/lib/redis
logfile /var/log/redis/redis-server.log
requirepass your_secure_password
appendonly yes
appendfilename "appendonly.aof"
EOF

# Create systemd service
cat > /etc/systemd/system/redis.service << EOF
[Unit]
Description=Advanced key-value store
After=network.target

[Service]
Type=notify
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
ExecStop=/usr/local/bin/redis-cli shutdown
TimeoutStopSec=0
Restart=always
User=redis
Group=redis

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now redis
```

## Network Configuration

### Load Balancer Setup (HAProxy)

#### HAProxy Configuration
```bash
# Install HAProxy
apt install -y haproxy

# Configure HAProxy
cat > /etc/haproxy/haproxy.cfg << EOF
global
    log stdout local0
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    mode http
    log global
    option httplog
    option dontlognull
    timeout connect 5000
    timeout client 50000
    timeout server 50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

frontend btp_frontend
    bind *:80
    bind *:443 ssl crt /etc/ssl/certs/btp.pem
    redirect scheme https if !{ ssl_fc }
    
    # Security headers
    http-response set-header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    http-response set-header X-Frame-Options DENY
    http-response set-header X-Content-Type-Options nosniff
    http-response set-header Referrer-Policy "strict-origin-when-cross-origin"
    
    default_backend btp_servers

backend btp_servers
    balance roundrobin
    option httpchk GET /health
    
    server app1 192.168.1.101:3000 check
    server app2 192.168.1.102:3000 check
    server app3 192.168.1.103:3000 check

listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
EOF

systemctl enable --now haproxy
```

#### Keepalived for High Availability
```bash
# Install Keepalived
apt install -y keepalived

# Configure Keepalived (Master)
cat > /etc/keepalived/keepalived.conf << EOF
vrrp_script chk_haproxy {
    script "/bin/kill -0 \`cat /var/run/haproxy.pid\`"
    interval 2
    weight 2
    fall 3
    rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 101
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass your_password
    }
    virtual_ipaddress {
        192.168.1.100/24
    }
    track_script {
        chk_haproxy
    }
}
EOF

systemctl enable --now keepalived
```

### SSL/TLS Configuration

#### Let's Encrypt with Certbot
```bash
# Install Certbot
apt install -y certbot python3-certbot-nginx

# Obtain certificate
certbot --nginx -d btp.yourdomain.com

# Auto-renewal
echo "0 12 * * * /usr/bin/certbot renew --quiet" | crontab -
```

#### Self-Signed Certificate Generation
```bash
# Generate private key
openssl genrsa -out btp.key 2048

# Generate certificate signing request
openssl req -new -key btp.key -out btp.csr -subj "/C=US/ST=State/L=City/O=Organization/CN=btp.local"

# Generate self-signed certificate
openssl x509 -req -days 365 -in btp.csr -signkey btp.key -out btp.crt

# Combine for HAProxy
cat btp.crt btp.key > /etc/ssl/certs/btp.pem
```

### DNS Configuration

#### BIND9 DNS Server Setup
```bash
# Install BIND9
apt install -y bind9 bind9utils bind9-doc

# Configure named.conf.local
cat >> /etc/bind/named.conf.local << EOF
zone "btp.local" {
    type master;
    file "/etc/bind/db.btp.local";
};
EOF

# Create zone file
cat > /etc/bind/db.btp.local << EOF
\$TTL    604800
@       IN      SOA     btp.local. admin.btp.local. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.btp.local.
@       IN      A       192.168.1.100
ns      IN      A       192.168.1.100
www     IN      A       192.168.1.100
api     IN      A       192.168.1.100
vault   IN      A       192.168.1.100
EOF

systemctl restart bind9
```

## Security Hardening

### Firewall Configuration

#### iptables Rules
```bash
#!/bin/bash
# firewall-rules.sh

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# Set default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow SSH (change port as needed)
iptables -A INPUT -p tcp --dport 2222 -j ACCEPT

# Allow HTTP/HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Allow database access from application servers
iptables -A INPUT -p tcp -s 192.168.1.101 --dport 5432 -j ACCEPT
iptables -A INPUT -p tcp -s 192.168.1.102 --dport 5432 -j ACCEPT
iptables -A INPUT -p tcp -s 192.168.1.103 --dport 5432 -j ACCEPT

# Allow Redis access from application servers
iptables -A INPUT -p tcp -s 192.168.1.101 --dport 6379 -j ACCEPT
iptables -A INPUT -p tcp -s 192.168.1.102 --dport 6379 -j ACCEPT
iptables -A INPUT -p tcp -s 192.168.1.103 --dport 6379 -j ACCEPT

# Save rules
iptables-save > /etc/iptables/rules.v4
```

### Application Security

#### NGINX Security Configuration
```nginx
# /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
}

http {
    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
    limit_req_zone $binary_remote_addr zone=api:10m rate=100r/m;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    upstream btp_backend {
        least_conn;
        server 127.0.0.1:3000 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }
    
    server {
        listen 80;
        server_name btp.local;
        return 301 https://$server_name$request_uri;
    }
    
    server {
        listen 443 ssl http2;
        server_name btp.local;
        
        ssl_certificate /etc/ssl/certs/btp.crt;
        ssl_certificate_key /etc/ssl/private/btp.key;
        
        # Security
        if ($request_method !~ ^(GET|HEAD|POST|PUT|DELETE|OPTIONS)$ ) {
            return 405;
        }
        
        # Rate limiting
        location /api/auth/login {
            limit_req zone=login burst=5 nodelay;
            proxy_pass http://btp_backend;
            include proxy_params;
        }
        
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://btp_backend;
            include proxy_params;
        }
        
        location / {
            proxy_pass http://btp_backend;
            include proxy_params;
        }
        
        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
```

### Database Security

#### PostgreSQL Security Hardening
```sql
-- Create dedicated database and user
CREATE DATABASE btp;
CREATE USER btp_user WITH ENCRYPTED PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE btp TO btp_user;

-- Revoke public schema access
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO btp_user;

-- Create read-only user for monitoring
CREATE USER monitoring WITH ENCRYPTED PASSWORD 'monitoring_password';
GRANT CONNECT ON DATABASE btp TO monitoring;
GRANT USAGE ON SCHEMA public TO monitoring;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO monitoring;
```

#### PostgreSQL Configuration (postgresql.conf)
```ini
# Connection settings
listen_addresses = '192.168.1.100'
port = 5432
max_connections = 200

# SSL settings
ssl = on
ssl_cert_file = '/etc/postgresql/ssl/server.crt'
ssl_key_file = '/etc/postgresql/ssl/server.key'
ssl_ca_file = '/etc/postgresql/ssl/ca.crt'

# Authentication
password_encryption = scram-sha-256

# Logging
log_connections = on
log_disconnections = on
log_checkpoints = on
log_lock_waits = on
log_statement = 'mod'
log_min_duration_statement = 1000

# Performance
shared_buffers = 8GB
effective_cache_size = 24GB
work_mem = 64MB
maintenance_work_mem = 2GB
checkpoint_completion_target = 0.9
wal_buffers = 64MB
```

#### PostgreSQL Host-Based Authentication (pg_hba.conf)
```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
local   all             all                                     scram-sha-256
host    btp             btp_user        192.168.1.101/32        scram-sha-256
host    btp             btp_user        192.168.1.102/32        scram-sha-256
host    btp             btp_user        192.168.1.103/32        scram-sha-256
host    btp             monitoring      192.168.1.0/24          scram-sha-256
```

## Monitoring & Logging

### Prometheus Configuration

#### Prometheus Configuration File
```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: 
        - '192.168.1.100:9100'
        - '192.168.1.101:9100'
        - '192.168.1.102:9100'
        - '192.168.1.103:9100'

  - job_name: 'postgres-exporter'
    static_configs:
      - targets: ['192.168.1.100:9187']

  - job_name: 'redis-exporter'
    static_configs:
      - targets: ['192.168.1.100:9121']

  - job_name: 'nginx-exporter'
    static_configs:
      - targets: ['192.168.1.100:9113']

  - job_name: 'btp-application'
    static_configs:
      - targets:
        - '192.168.1.101:3000'
        - '192.168.1.102:3000'
        - '192.168.1.103:3000'
    metrics_path: '/metrics'
```

#### Alert Rules
```yaml
# alert_rules.yml
groups:
- name: btp_alerts
  rules:
  - alert: HighCPUUsage
    expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage on {{ $labels.instance }}"
      description: "CPU usage is above 80% for more than 5 minutes"

  - alert: HighMemoryUsage
    expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High memory usage on {{ $labels.instance }}"
      description: "Memory usage is above 85% for more than 5 minutes"

  - alert: PostgreSQLDown
    expr: pg_up == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "PostgreSQL is down"
      description: "PostgreSQL database is not responding"

  - alert: RedisDown
    expr: redis_up == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Redis is down"
      description: "Redis cache is not responding"

  - alert: BTPApplicationDown
    expr: up{job="btp-application"} == 0
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "BTP application is down on {{ $labels.instance }}"
      description: "BTP application is not responding for more than 2 minutes"
```

### Log Aggregation with ELK Stack

#### Elasticsearch Configuration
```yaml
# elasticsearch.yml
cluster.name: btp-logs
node.name: elasticsearch-1
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 192.168.1.104
http.port: 9200
discovery.seed_hosts: ["192.168.1.104"]
cluster.initial_master_nodes: ["elasticsearch-1"]

# Security
xpack.security.enabled: true
xpack.security.authc.api_key.enabled: true
```

#### Logstash Configuration
```ruby
# logstash.conf
input {
  beats {
    port => 5044
  }
  
  syslog {
    port => 514
  }
}

filter {
  if [fields][service] == "btp" {
    json {
      source => "message"
    }
    
    date {
      match => [ "timestamp", "ISO8601" ]
    }
  }
  
  if [fields][service] == "nginx" {
    grok {
      match => { "message" => "%{NGINXACCESS}" }
    }
  }
  
  if [fields][service] == "postgresql" {
    grok {
      match => { "message" => "%{POSTGRESLOG}" }
    }
  }
}

output {
  elasticsearch {
    hosts => ["192.168.1.104:9200"]
    index => "btp-logs-%{+YYYY.MM.dd}"
    user => "elastic"
    password => "changeme"
  }
}
```

#### Filebeat Configuration
```yaml
# filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /opt/btp/logs/app/*.log
  fields:
    service: btp
  fields_under_root: true

- type: log
  enabled: true
  paths:
    - /var/log/nginx/*.log
  fields:
    service: nginx
  fields_under_root: true

- type: log
  enabled: true
  paths:
    - /var/log/postgresql/*.log
  fields:
    service: postgresql
  fields_under_root: true

output.logstash:
  hosts: ["192.168.1.104:5044"]

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
```

## Backup & Recovery

### Database Backup Strategy

#### PostgreSQL Backup Script
```bash
#!/bin/bash
# postgres-backup.sh

set -e

# Configuration
PGHOST="192.168.1.100"
PGPORT="5432"
PGUSER="postgres"
PGDATABASE="btp"
BACKUP_DIR="/opt/backups/postgres"
RETENTION_DAYS=30

# Create backup directory
mkdir -p $BACKUP_DIR

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Full database backup
echo "Starting PostgreSQL backup..."
pg_dump -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE \
    --verbose --clean --create --if-exists \
    --format=custom \
    --file="$BACKUP_DIR/btp_full_$TIMESTAMP.dump"

# Compress backup
gzip "$BACKUP_DIR/btp_full_$TIMESTAMP.dump"

# Schema-only backup
pg_dump -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE \
    --schema-only --format=plain \
    --file="$BACKUP_DIR/btp_schema_$TIMESTAMP.sql"

# Remove old backups
find $BACKUP_DIR -name "*.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.sql" -mtime +$RETENTION_DAYS -delete

echo "PostgreSQL backup completed: btp_full_$TIMESTAMP.dump.gz"
```

#### Redis Backup Script
```bash
#!/bin/bash
# redis-backup.sh

set -e

REDIS_HOST="192.168.1.100"
REDIS_PORT="6379"
REDIS_PASSWORD="your_redis_password"
BACKUP_DIR="/opt/backups/redis"
RETENTION_DAYS=7

mkdir -p $BACKUP_DIR

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create Redis backup
echo "Starting Redis backup..."
redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD --rdb "$BACKUP_DIR/redis_$TIMESTAMP.rdb"

# Compress backup
gzip "$BACKUP_DIR/redis_$TIMESTAMP.rdb"

# Remove old backups
find $BACKUP_DIR -name "*.gz" -mtime +$RETENTION_DAYS -delete

echo "Redis backup completed: redis_$TIMESTAMP.rdb.gz"
```

### Full System Backup with Bacula

#### Bacula Director Configuration
```
# bacula-dir.conf
Director {
  Name = btp-dir
  DIRport = 9101
  QueryFile = "/etc/bacula/scripts/query.sql"
  WorkingDirectory = "/var/lib/bacula"
  PidDirectory = "/run/bacula"
  Maximum Concurrent Jobs = 20
  Password = "director_password"
  Messages = Daemon
}

JobDefs {
  Name = "BTP-Job"
  Type = Backup
  Level = Incremental
  Client = btp-fd
  FileSet = "BTP-FileSet"
  Schedule = "BTP-Schedule"
  Storage = File1
  Messages = Standard
  Pool = File
  SpoolAttributes = yes
  Priority = 10
  Write Bootstrap = "/var/lib/bacula/%c.bsr"
}

Job {
  Name = "BTP-Database-Backup"
  JobDefs = "BTP-Job"
  Level = Full
  FileSet = "BTP-DB-FileSet"
  Schedule = "DB-Schedule"
  RunBeforeJob = "/opt/scripts/postgres-backup.sh"
  RunAfterJob = "/opt/scripts/cleanup-temp-backups.sh"
}

FileSet {
  Name = "BTP-FileSet"
  Include {
    Options {
      signature = MD5
      compression = GZIP
    }
    File = /opt/btp
    File = /etc
    File = /var/log
  }
  Exclude {
    File = /opt/btp/data/postgres
    File = /opt/btp/data/redis
    File = /tmp
    File = /proc
    File = /sys
  }
}

Schedule {
  Name = "BTP-Schedule"
  Run = Level=Full 1st sun at 23:05
  Run = Level=Differential 2nd-5th sun at 23:05
  Run = Level=Incremental mon-sat at 23:05
}

Client {
  Name = btp-fd
  Address = 192.168.1.100
  FDPort = 9102
  Catalog = MyCatalog
  Password = "client_password"
  File Retention = 60 days
  Job Retention = 6 months
  AutoPrune = yes
}

Storage {
  Name = File1
  Address = 192.168.1.105
  SDPort = 9103
  Password = "storage_password"
  Device = FileChgr1
  Media Type = File1
  Maximum Concurrent Jobs = 10
}
```

### Disaster Recovery Procedures

#### Recovery Checklist
```markdown
# BTP Disaster Recovery Checklist

## Phase 1: Assessment (15 minutes)
- [ ] Identify scope of failure (hardware, software, data)
- [ ] Determine RTO (Recovery Time Objective) requirements
- [ ] Notify stakeholders and activate DR team
- [ ] Secure alternative infrastructure if needed

## Phase 2: Infrastructure Recovery (30-60 minutes)
- [ ] Provision new hardware/VMs if required
- [ ] Install and configure operating system
- [ ] Restore network connectivity
- [ ] Configure DNS and load balancing

## Phase 3: Data Recovery (60-120 minutes)
- [ ] Restore PostgreSQL database from latest backup
- [ ] Restore Redis data if needed
- [ ] Restore application data and configurations
- [ ] Verify data integrity

## Phase 4: Application Recovery (30-60 minutes)
- [ ] Deploy BTP application stack
- [ ] Configure environment variables and secrets
- [ ] Start all services in proper order
- [ ] Verify service health checks

## Phase 5: Validation (30 minutes)
- [ ] Test critical application functions
- [ ] Verify user authentication
- [ ] Test blockchain network connectivity
- [ ] Monitor system performance

## Phase 6: Failback (when ready)
- [ ] Sync data to primary systems
- [ ] Switch traffic back to primary
- [ ] Decommission DR environment
- [ ] Update documentation and lessons learned
```

#### Automated Recovery Script
```bash
#!/bin/bash
# disaster-recovery.sh

set -e

echo "🚨 Starting BTP Disaster Recovery Process..."

# Configuration
BACKUP_SERVER="192.168.1.105"
BACKUP_PATH="/opt/backups"
RECOVERY_PATH="/opt/btp-recovery"

# Phase 1: Prepare recovery environment
echo "📋 Phase 1: Preparing recovery environment..."
mkdir -p $RECOVERY_PATH/{postgres,redis,app}

# Phase 2: Restore database
echo "💾 Phase 2: Restoring PostgreSQL database..."
LATEST_DB_BACKUP=$(ssh $BACKUP_SERVER "ls -t $BACKUP_PATH/postgres/btp_full_*.dump.gz | head -1")
scp $BACKUP_SERVER:$LATEST_DB_BACKUP $RECOVERY_PATH/postgres/
gunzip $RECOVERY_PATH/postgres/*.dump.gz

# Create database and restore
sudo -u postgres createdb btp_recovery
sudo -u postgres pg_restore -d btp_recovery $RECOVERY_PATH/postgres/*.dump

# Phase 3: Restore Redis
echo "🔴 Phase 3: Restoring Redis data..."
LATEST_REDIS_BACKUP=$(ssh $BACKUP_SERVER "ls -t $BACKUP_PATH/redis/redis_*.rdb.gz | head -1")
scp $BACKUP_SERVER:$LATEST_REDIS_BACKUP $RECOVERY_PATH/redis/
gunzip $RECOVERY_PATH/redis/*.rdb.gz
cp $RECOVERY_PATH/redis/*.rdb /var/lib/redis/dump.rdb
chown redis:redis /var/lib/redis/dump.rdb

# Phase 4: Restore application data
echo "📱 Phase 4: Restoring application data..."
rsync -avz $BACKUP_SERVER:$BACKUP_PATH/app/ $RECOVERY_PATH/app/

# Phase 5: Start services
echo "🚀 Phase 5: Starting services..."
systemctl start postgresql
systemctl start redis
docker-compose -f /opt/btp/docker-compose.yml up -d

# Phase 6: Health checks
echo "🏥 Phase 6: Running health checks..."
sleep 30

# Check PostgreSQL
if pg_isready -h localhost -p 5432; then
    echo "✅ PostgreSQL is healthy"
else
    echo "❌ PostgreSQL health check failed"
    exit 1
fi

# Check Redis
if redis-cli ping | grep -q PONG; then
    echo "✅ Redis is healthy"
else
    echo "❌ Redis health check failed"
    exit 1
fi

# Check BTP application
if curl -f http://localhost/health; then
    echo "✅ BTP application is healthy"
else
    echo "❌ BTP application health check failed"
    exit 1
fi

echo "🎉 Disaster recovery completed successfully!"
echo "📊 Recovery Summary:"
echo "   - Database: Restored from $LATEST_DB_BACKUP"
echo "   - Redis: Restored from $LATEST_REDIS_BACKUP"
echo "   - Application: Services are running"
echo "   - Time: $(date)"
```

## Troubleshooting

### Common Issues and Solutions

#### Performance Issues

##### High CPU Usage
```bash
# Identify CPU-intensive processes
top -p $(pgrep -d',' -f btp)
htop -p $(pgrep -d',' -f postgres)

# Check system load
uptime
vmstat 1 5

# Analyze process threads
ps -eLf | grep btp | wc -l

# Solutions:
# 1. Scale horizontally (add more app servers)
# 2. Optimize database queries
# 3. Implement caching
# 4. Use connection pooling
```

##### Memory Issues
```bash
# Check memory usage
free -h
cat /proc/meminfo

# Check for memory leaks
valgrind --tool=memcheck --leak-check=full ./btp-app

# PostgreSQL memory analysis
SELECT * FROM pg_stat_activity WHERE state = 'active';

# Solutions:
# 1. Increase RAM
# 2. Optimize application memory usage
# 3. Configure swap appropriately
# 4. Tune PostgreSQL shared_buffers
```

##### Disk I/O Issues
```bash
# Monitor disk I/O
iotop -ao
iostat -x 1

# Check disk usage
df -h
du -sh /opt/btp/*

# Analyze slow queries
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;

# Solutions:
# 1. Use faster storage (NVMe SSD)
# 2. Optimize database queries
# 3. Implement read replicas
# 4. Use connection pooling
```

#### Network Issues

##### Connection Timeouts
```bash
# Test network connectivity
ping -c 4 192.168.1.100
telnet 192.168.1.100 5432

# Check network statistics
netstat -i
ss -tuln

# Monitor network traffic
tcpdump -i eth0 host 192.168.1.100

# Solutions:
# 1. Increase timeout values
# 2. Check firewall rules
# 3. Optimize network configuration
# 4. Use connection pooling
```

##### SSL/TLS Issues
```bash
# Test SSL connection
openssl s_client -connect btp.local:443 -servername btp.local

# Check certificate validity
openssl x509 -in /etc/ssl/certs/btp.crt -text -noout

# Verify certificate chain
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/btp.crt

# Solutions:
# 1. Renew expired certificates
# 2. Fix certificate chain
# 3. Update cipher suites
# 4. Check certificate permissions
```

#### Database Issues

##### Connection Pool Exhaustion
```bash
# Check active connections
SELECT count(*) FROM pg_stat_activity;

# Check connection limits
SELECT setting FROM pg_settings WHERE name = 'max_connections';

# Identify long-running queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query 
FROM pg_stat_activity 
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';

# Solutions:
# 1. Implement connection pooling (PgBouncer)
# 2. Increase max_connections
# 3. Optimize slow queries
# 4. Kill long-running queries
```

##### Database Performance
```bash
# Enable query statistics
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
CREATE EXTENSION pg_stat_statements;

# Analyze slow queries
SELECT query, total_time, mean_time, calls, rows
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 20;

# Check for missing indexes
SELECT schemaname, tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE schemaname = 'public'
ORDER BY n_distinct DESC;

# Solutions:
# 1. Add appropriate indexes
# 2. Optimize queries
# 3. Update table statistics
# 4. Consider partitioning
```

### Diagnostic Scripts

#### System Health Check
```bash
#!/bin/bash
# system-health-check.sh

echo "🏥 BTP System Health Check - $(date)"
echo "================================================"

# System resources
echo "📊 System Resources:"
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "Memory Usage: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')"
echo "Disk Usage: $(df -h / | awk 'NR==2{print $5}')"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo

# Network connectivity
echo "🌐 Network Connectivity:"
for host in 192.168.1.100 192.168.1.101 192.168.1.102; do
    if ping -c 1 $host &> /dev/null; then
        echo "✅ $host - Reachable"
    else
        echo "❌ $host - Unreachable"
    fi
done
echo

# Service status
echo "🔧 Service Status:"
services=("docker" "nginx" "postgresql" "redis")
for service in "${services[@]}"; do
    if systemctl is-active --quiet $service; then
        echo "✅ $service - Running"
    else
        echo "❌ $service - Not running"
    fi
done
echo

# Container status (if using Docker)
echo "🐳 Container Status:"
if command -v docker &> /dev/null; then
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo "Docker not installed or not running"
fi
echo

# Database connectivity
echo "💾 Database Connectivity:"
if pg_isready -h localhost -p 5432; then
    echo "✅ PostgreSQL - Connected"
    echo "Active connections: $(psql -h localhost -p 5432 -U postgres -t -c "SELECT count(*) FROM pg_stat_activity;")"
else
    echo "❌ PostgreSQL - Connection failed"
fi

if redis-cli ping &> /dev/null; then
    echo "✅ Redis - Connected"
    echo "Memory usage: $(redis-cli info memory | grep used_memory_human | cut -d: -f2)"
else
    echo "❌ Redis - Connection failed"
fi
echo

# SSL certificate status
echo "🔒 SSL Certificate Status:"
if [ -f /etc/ssl/certs/btp.crt ]; then
    expiry=$(openssl x509 -enddate -noout -in /etc/ssl/certs/btp.crt | cut -d= -f2)
    echo "Certificate expires: $expiry"
    
    days_until_expiry=$(( ($(date -d "$expiry" +%s) - $(date +%s)) / 86400 ))
    if [ $days_until_expiry -lt 30 ]; then
        echo "⚠️  Certificate expires in $days_until_expiry days"
    else
        echo "✅ Certificate valid for $days_until_expiry days"
    fi
else
    echo "❌ SSL certificate not found"
fi
echo

# Backup status
echo "💾 Backup Status:"
if [ -d /opt/backups ]; then
    latest_backup=$(find /opt/backups -name "*.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    if [ -n "$latest_backup" ]; then
        backup_age=$(( ($(date +%s) - $(stat -c %Y "$latest_backup")) / 86400 ))
        echo "Latest backup: $latest_backup ($backup_age days old)"
        if [ $backup_age -gt 1 ]; then
            echo "⚠️  Backup is $backup_age days old"
        else
            echo "✅ Recent backup available"
        fi
    else
        echo "❌ No backups found"
    fi
else
    echo "❌ Backup directory not found"
fi

echo "================================================"
echo "Health check completed at $(date)"
```

## Production Considerations

### Scalability Planning

#### Horizontal Scaling Strategy
```bash
# Load Balancer Configuration for Multiple App Servers
upstream btp_backend {
    least_conn;
    server 192.168.1.101:3000 max_fails=3 fail_timeout=30s weight=1;
    server 192.168.1.102:3000 max_fails=3 fail_timeout=30s weight=1;
    server 192.168.1.103:3000 max_fails=3 fail_timeout=30s weight=1;
    server 192.168.1.104:3000 max_fails=3 fail_timeout=30s weight=1 backup;
    keepalive 32;
}

# Auto-scaling script
#!/bin/bash
# auto-scale.sh
CURRENT_LOAD=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | xargs)
THRESHOLD=8.0

if (( $(echo "$CURRENT_LOAD > $THRESHOLD" | bc -l) )); then
    echo "High load detected ($CURRENT_LOAD), scaling up..."
    # Add logic to provision new server
    ansible-playbook deploy-new-server.yml
fi
```

#### Database Scaling Options

##### Read Replicas Setup
```bash
# Primary server postgresql.conf
wal_level = replica
max_wal_senders = 3
max_replication_slots = 3
synchronous_commit = on

# Replica server setup
pg_basebackup -h 192.168.1.100 -D /var/lib/postgresql/data -U replication -W -P -R

# Configure replica
echo "standby_mode = 'on'" >> /var/lib/postgresql/data/recovery.conf
echo "primary_conninfo = 'host=192.168.1.100 port=5432 user=replication'" >> /var/lib/postgresql/data/recovery.conf
```

##### Connection Pooling with PgBouncer
```ini
# pgbouncer.ini
[databases]
btp = host=192.168.1.100 port=5432 dbname=btp

[pgbouncer]
listen_port = 6432
listen_addr = *
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 50
reserve_pool_size = 5
```

### Performance Optimization

#### Application-Level Optimizations
```javascript
// Connection pooling configuration
const pool = new Pool({
  user: 'btp_user',
  host: 'localhost',
  database: 'btp',
  password: process.env.DB_PASSWORD,
  port: 5432,
  max: 50, // maximum number of clients in the pool
  idleTimeoutMillis: 30000, // how long a client is allowed to remain idle
  connectionTimeoutMillis: 2000, // return an error after 2 seconds if connection could not be established
});

// Redis caching strategy
const redis = require('redis');
const client = redis.createClient({
  host: 'localhost',
  port: 6379,
  password: process.env.REDIS_PASSWORD,
  retry_strategy: (options) => {
    if (options.error && options.error.code === 'ECONNREFUSED') {
      return new Error('The server refused the connection');
    }
    if (options.total_retry_time > 1000 * 60 * 60) {
      return new Error('Retry time exhausted');
    }
    return Math.min(options.attempt * 100, 3000);
  }
});

// Implement caching middleware
const cacheMiddleware = (duration = 300) => {
  return async (req, res, next) => {
    const key = `cache:${req.originalUrl}`;
    try {
      const cached = await client.get(key);
      if (cached) {
        return res.json(JSON.parse(cached));
      }
      
      res.sendResponse = res.json;
      res.json = (body) => {
        client.setex(key, duration, JSON.stringify(body));
        res.sendResponse(body);
      };
      
      next();
    } catch (error) {
      console.error('Cache error:', error);
      next();
    }
  };
};
```

#### Database Optimization
```sql
-- Create appropriate indexes
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
CREATE INDEX CONCURRENTLY idx_transactions_timestamp ON transactions(created_at);
CREATE INDEX CONCURRENTLY idx_blocks_hash ON blocks USING HASH(block_hash);

-- Analyze and vacuum regularly
VACUUM ANALYZE;

-- Update table statistics
ANALYZE users;
ANALYZE transactions;
ANALYZE blocks;

-- Monitor query performance
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    stddev_time,
    rows
FROM pg_stat_statements 
WHERE calls > 100
ORDER BY mean_time DESC
LIMIT 20;
```

### Security Compliance

#### SOC 2 Compliance Checklist
```markdown
# SOC 2 Compliance for BTP Bare Metal Deployment

## Security Controls
- [ ] Multi-factor authentication implemented
- [ ] Role-based access control configured
- [ ] Network segmentation in place
- [ ] Encryption at rest and in transit
- [ ] Regular security assessments conducted
- [ ] Incident response procedures documented

## Availability Controls
- [ ] High availability architecture implemented
- [ ] Backup and recovery procedures tested
- [ ] Monitoring and alerting configured
- [ ] Disaster recovery plan documented
- [ ] Capacity planning and scaling procedures
- [ ] Performance monitoring in place

## Processing Integrity Controls
- [ ] Data validation and integrity checks
- [ ] Change management procedures
- [ ] Version control for all configurations
- [ ] Automated testing procedures
- [ ] Error handling and logging
- [ ] Transaction processing controls

## Confidentiality Controls
- [ ] Data classification implemented
- [ ] Access controls based on need-to-know
- [ ] Data encryption and key management
- [ ] Secure data disposal procedures
- [ ] Privacy controls for personal data
- [ ] Third-party data sharing controls

## Privacy Controls (if applicable)
- [ ] Privacy notice and consent mechanisms
- [ ] Data subject rights procedures
- [ ] Data retention and disposal policies
- [ ] Cross-border data transfer controls
- [ ] Privacy impact assessments
- [ ] Breach notification procedures
```

### Maintenance Procedures

#### Regular Maintenance Schedule
```bash
#!/bin/bash
# maintenance-schedule.sh

# Daily tasks (run at 2 AM)
if [ "$(date +%H)" = "02" ]; then
    # Database maintenance
    sudo -u postgres psql -d btp -c "VACUUM ANALYZE;"
    
    # Log rotation
    logrotate /etc/logrotate.d/btp
    
    # Clean temporary files
    find /tmp -type f -atime +1 -delete
    
    # Update system packages (security only)
    apt update && apt upgrade -y --only-upgrade $(apt list --upgradable 2>/dev/null | grep -i security | cut -d'/' -f1)
fi

# Weekly tasks (run on Sunday at 3 AM)
if [ "$(date +%w)" = "0" ] && [ "$(date +%H)" = "03" ]; then
    # Full database backup
    /opt/scripts/postgres-backup.sh
    
    # System backup
    /opt/scripts/system-backup.sh
    
    # Security scan
    /opt/scripts/security-scan.sh
    
    # Performance analysis
    /opt/scripts/performance-analysis.sh
fi

# Monthly tasks (run on 1st of month at 4 AM)
if [ "$(date +%d)" = "01" ] && [ "$(date +%H)" = "04" ]; then
    # SSL certificate check and renewal
    certbot renew --quiet
    
    # Security updates
    apt update && apt full-upgrade -y
    
    # Disk cleanup
    apt autoremove -y && apt autoclean
    
    # Generate monthly reports
    /opt/scripts/generate-monthly-report.sh
fi
```

This comprehensive bare metal deployment guide provides detailed instructions for deploying BTP without managed services, covering everything from single-server setups to enterprise high-availability deployments. The guide includes real-world configurations, security hardening, monitoring, backup strategies, and production considerations for various deployment scenarios.
