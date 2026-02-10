# 📘 Setup Guide

Complete guide to setting up your DevSecOps home lab environment from scratch.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [System Requirements](#system-requirements)
3. [Docker Installation](#docker-installation)
4. [Jenkins Container Setup](#jenkins-container-setup)
5. [Network Configuration](#network-configuration)
6. [First Pipeline Run](#first-pipeline-run)
7. [Verification Steps](#verification-steps)
8. [Next Steps](#next-steps)

## 🔧 Prerequisites

Before starting, ensure you have:

### Software Requirements

- **Operating System**: Linux (Ubuntu/Debian recommended), macOS, or Windows with WSL2
- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher
- **Git**: Version 2.30 or higher
- **Text Editor**: VS Code, Vim, or your preferred editor
- **Web Browser**: Chrome, Firefox, or Safari

### Knowledge Prerequisites

- Basic command line/terminal usage
- Understanding of Docker concepts (containers, images, volumes)
- Basic Git operations (clone, commit, push)
- Understanding of CI/CD concepts

### Hardware Requirements

- **CPU**: 2+ cores recommended
- **RAM**: 4GB minimum, 8GB recommended
- **Disk Space**: 20GB free space minimum
- **Network**: Internet connection for pulling Docker images

## 🖥️ System Requirements

### For Linux (Ubuntu/Debian)

Check your system:
```bash
# Check OS version
lsb_release -a

# Check available memory
free -h

# Check disk space
df -h

# Check Docker socket
ls -la /var/run/docker.sock
```

### For macOS

```bash
# Check macOS version
sw_vers

# Check available memory
sysctl hw.memsize

# Check disk space
df -h
```

### For Windows (WSL2)

```bash
# Check WSL version
wsl --list --verbose

# Ensure WSL2 is default
wsl --set-default-version 2
```

## 🐳 Docker Installation

### Ubuntu/Debian Linux

```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up stable repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verify installation
docker --version
docker compose version

# Add your user to docker group (avoid using sudo)
sudo usermod -aG docker $USER

# Apply group changes (or log out and back in)
newgrp docker

# Test Docker
docker run hello-world
```

### macOS

```bash
# Install using Homebrew
brew install --cask docker

# Or download Docker Desktop from:
# https://www.docker.com/products/docker-desktop

# Start Docker Desktop from Applications

# Verify installation
docker --version
docker compose version
```

### Windows (WSL2)

1. Install WSL2: Follow [Microsoft's WSL2 installation guide](https://docs.microsoft.com/en-us/windows/wsl/install)
2. Install Docker Desktop for Windows
3. Enable WSL2 integration in Docker Desktop settings
4. Verify in WSL terminal:
   ```bash
   docker --version
   docker compose version
   ```

## 🚀 Jenkins Container Setup

### Method 1: Using Docker Compose (Recommended)

1. Navigate to the Jenkins Docker directory:
   ```bash
   cd docker/jenkins
   ```

2. Review the docker-compose.yml configuration:
   ```bash
   cat docker-compose.yml
   ```

3. Start Jenkins:
   ```bash
   docker-compose up -d
   ```

4. Check container status:
   ```bash
   docker-compose ps
   ```

5. View logs:
   ```bash
   docker-compose logs -f jenkins
   ```

### Method 2: Using Setup Script

1. Make the script executable:
   ```bash
   chmod +x scripts/setup-jenkins.sh
   ```

2. Run the setup script:
   ```bash
   ./scripts/setup-jenkins.sh
   ```

3. The script will:
   - Pull the Jenkins Docker image
   - Create necessary volumes
   - Configure network settings
   - Start the Jenkins container
   - Display the initial admin password

### Method 3: Manual Docker Command

```bash
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

### Post-Installation Docker Permissions

If Jenkins needs to use Docker (Docker-in-Docker), configure permissions:

```bash
# Get the jenkins container user ID
docker exec jenkins id -u

# Change docker socket permissions (temporary)
sudo chmod 666 /var/run/docker.sock

# Or add jenkins user to docker group (persistent)
docker exec -u root jenkins usermod -aG docker jenkins
docker restart jenkins
```

## 🌐 Network Configuration

### Port Mappings

The following ports are used:

| Service | Port | Purpose |
|---------|------|---------|
| Jenkins Web UI | 8080 | Jenkins dashboard |
| Jenkins Agent | 50000 | Jenkins agent connections |
| Node.js App | 3000 | Sample application |
| Prometheus | 9090 | Metrics collection (future) |
| Grafana | 3001 | Monitoring dashboard (future) |

### Firewall Configuration

If using a firewall, allow these ports:

```bash
# Ubuntu/Debian with ufw
sudo ufw allow 8080/tcp
sudo ufw allow 50000/tcp
sudo ufw allow 3000/tcp

# Check status
sudo ufw status
```

### Verify Network Connectivity

```bash
# Test Jenkins port
curl http://localhost:8080

# Check all listening ports
sudo netstat -tulpn | grep LISTEN

# Or using ss
ss -tulpn | grep LISTEN
```

## 🔑 Initial Jenkins Configuration

### 1. Access Jenkins Web UI

Open your browser and navigate to:
```
http://localhost:8080
```

### 2. Retrieve Initial Admin Password

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Copy the password and paste it in the Jenkins setup page.

### 3. Install Plugins

Choose **"Install suggested plugins"** for a standard setup.

Required plugins for this lab:
- Git plugin
- Pipeline plugin
- Docker plugin
- Docker Pipeline plugin
- Credentials plugin

### 4. Create Admin User

Fill in the admin user creation form:
- Username
- Password
- Full name
- Email address

### 5. Configure Jenkins URL

Confirm the Jenkins URL (usually `http://localhost:8080`).

## 🔄 First Pipeline Run

### 1. Create a New Pipeline Job

1. Click **"New Item"** in Jenkins dashboard
2. Enter name: `devsecops-pipeline`
3. Select **"Pipeline"**
4. Click **"OK"**

### 2. Configure Pipeline

In the pipeline configuration:

1. **General Tab**:
   - Add description: "DevSecOps sample pipeline"

2. **Build Triggers** (optional):
   - Poll SCM: `H/5 * * * *` (every 5 minutes)
   - Or set up webhook for push-based builds

3. **Pipeline Section**:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/nrmrks/devsecops-home-lab.git`
   - Branch: `*/main` (or your default branch)
   - Script Path: `jenkins/Jenkinsfile`

4. Click **"Save"**

### 3. Run the Pipeline

1. Click **"Build Now"**
2. Watch the build progress in the left sidebar
3. Click on the build number to see details
4. Click **"Console Output"** to see logs

### 4. Monitor Build Progress

The pipeline will execute these stages:
- ✅ Cleanup Workspace
- ✅ Checkout Code
- ✅ Verify Files
- ✅ Build Docker Image
- ✅ Run Tests
- ✅ Stop Old Container
- ✅ Deploy Container
- ✅ Verify Deployment

## ✅ Verification Steps

### 1. Verify Jenkins is Running

```bash
docker ps | grep jenkins
```

Expected output should show jenkins container running.

### 2. Verify Jenkins Logs

```bash
docker logs jenkins --tail 50
```

Should show Jenkins startup logs without errors.

### 3. Verify Application Deployment

After pipeline completes:

```bash
# Check if container is running
docker ps | grep my-test-app

# Test the application
curl http://localhost:3000

# Should return JSON response
curl http://localhost:3000/health
```

### 4. Verify Docker Images

```bash
docker images | grep devsecops
```

Should show the built image with latest tag.

### 5. Check Container Logs

```bash
docker logs my-test-app
```

Should show "Server running on port 3000".

## 🎯 Next Steps

After successful setup:

1. **Explore Example Pipelines**
   - Check `jenkins/pipelines/` for different pipeline examples
   - Modify and test different configurations

2. **Add More Applications**
   - Create additional apps in `apps/` directory
   - Create corresponding pipelines

3. **Set Up Monitoring**
   - Deploy monitoring stack from `docker/monitoring/`
   - Configure Prometheus and Grafana

4. **Implement Security Scanning**
   - Add SAST tools (SonarQube, etc.)
   - Add dependency scanning
   - Add container scanning

5. **Configure Webhooks**
   - Set up GitHub webhooks for automatic builds
   - Configure notifications (email, Slack)

6. **Explore Advanced Features**
   - Multi-branch pipelines
   - Parallel execution
   - Shared libraries
   - Integration testing

## 📚 Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Docker Documentation](https://docs.docker.com/)
- [Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 🆘 Troubleshooting

If you encounter issues, check:
- [Troubleshooting Guide](troubleshooting.md)
- [Jenkins Setup Guide](jenkins-setup.md)
- Container logs: `docker logs jenkins`
- Docker daemon: `sudo systemctl status docker`

---

**Congratulations!** 🎉 Your DevSecOps home lab is now set up and ready for learning!
