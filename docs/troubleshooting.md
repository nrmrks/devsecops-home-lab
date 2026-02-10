# 🔍 Troubleshooting Guide

Common issues and solutions for the DevSecOps home lab environment.

## 📋 Table of Contents

1. [Docker Issues](#docker-issues)
2. [Jenkins Connectivity Problems](#jenkins-connectivity-problems)
3. [Permission Errors](#permission-errors)
4. [Container Issues](#container-issues)
5. [Port Conflicts](#port-conflicts)
6. [Pipeline Failures](#pipeline-failures)
7. [Log Checking Commands](#log-checking-commands)
8. [Network Issues](#network-issues)

## 🐳 Docker Issues

### Docker Daemon Not Running

**Symptoms**: `Cannot connect to the Docker daemon`

**Solutions**:

```bash
# Check Docker status
sudo systemctl status docker

# Start Docker service
sudo systemctl start docker

# Enable Docker to start on boot
sudo systemctl enable docker

# On macOS, ensure Docker Desktop is running
open -a Docker

# Verify Docker is running
docker ps
```

### Docker Socket Permission Denied

**Symptoms**: `permission denied while trying to connect to the Docker daemon socket`

**Solutions**:

```bash
# Add your user to docker group
sudo usermod -aG docker $USER

# Apply group changes (or logout/login)
newgrp docker

# Verify
docker ps

# Alternative: Change socket permissions (temporary)
sudo chmod 666 /var/run/docker.sock
```

### Docker Image Pull Fails

**Symptoms**: `Error response from daemon: pull access denied`

**Solutions**:

```bash
# Check internet connectivity
ping google.com

# Check Docker Hub status
curl https://status.docker.com/

# Try pulling with latest tag explicitly
docker pull jenkins/jenkins:lts

# Check for typos in image name
docker search jenkins

# If behind proxy, configure Docker proxy settings
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo nano /etc/systemd/system/docker.service.d/http-proxy.conf
```

Example proxy configuration:
```ini
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:80"
Environment="HTTPS_PROXY=http://proxy.example.com:80"
Environment="NO_PROXY=localhost,127.0.0.1"
```

Then restart:
```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### Docker Disk Space Issues

**Symptoms**: `no space left on device`

**Solutions**:

```bash
# Check disk usage
df -h

# Check Docker disk usage
docker system df

# Remove unused images
docker image prune -a

# Remove unused containers
docker container prune

# Remove unused volumes
docker volume prune

# Remove everything unused (careful!)
docker system prune -a --volumes

# Check again
docker system df
```

## 🔌 Jenkins Connectivity Problems

### Cannot Access Jenkins Web UI

**Symptoms**: Browser shows "This site can't be reached" or connection timeout

**Checklist**:

```bash
# 1. Check if Jenkins container is running
docker ps | grep jenkins

# If not running, check all containers
docker ps -a | grep jenkins

# Check container logs
docker logs jenkins

# 2. Check if port 8080 is listening
sudo netstat -tulpn | grep 8080
# Or
sudo ss -tulpn | grep 8080

# 3. Try accessing from command line
curl http://localhost:8080

# 4. Check firewall
sudo ufw status

# 5. Check Docker network
docker network ls
docker network inspect bridge
```

**Solutions**:

```bash
# Restart Jenkins container
docker restart jenkins

# If container is stopped, start it
docker start jenkins

# If container doesn't exist, recreate it
cd docker/jenkins
docker-compose up -d

# Check for port conflicts (see Port Conflicts section)
sudo lsof -i :8080
```

### Jenkins Taking Too Long to Start

**Symptoms**: Container running but web UI not responding

**Solutions**:

```bash
# Check logs for initialization progress
docker logs -f jenkins

# Look for: "Jenkins is fully up and running"

# Be patient - first startup can take 2-5 minutes

# If stuck after 10 minutes, restart
docker restart jenkins
```

### Cannot Retrieve Initial Admin Password

**Symptoms**: `cat: /var/jenkins_home/secrets/initialAdminPassword: No such file or directory`

**Solutions**:

```bash
# Ensure Jenkins container is running
docker ps | grep jenkins

# Wait for Jenkins to fully start (check logs)
docker logs jenkins | grep "Jenkins is fully up and running"

# Try retrieving password again
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# If still not found, check Jenkins home volume
docker volume inspect jenkins_home

# Access Jenkins home directly
docker exec -it jenkins ls -la /var/jenkins_home/secrets/
```

## 🔒 Permission Errors

### Jenkins Cannot Access Docker Socket

**Symptoms**: `permission denied while trying to connect to the Docker daemon socket` inside Jenkins

**Solutions**:

```bash
# Give Jenkins container access to Docker socket
docker exec -u root jenkins chmod 666 /var/run/docker.sock

# Or add jenkins user to docker group (more permanent)
docker exec -u root jenkins usermod -aG docker jenkins

# Restart Jenkins
docker restart jenkins

# Verify Docker works inside Jenkins
docker exec jenkins docker ps
```

### Permission Denied in Pipeline

**Symptoms**: Pipeline fails with permission errors when accessing files

**Solutions**:

```bash
# Check workspace permissions
docker exec jenkins ls -la /var/jenkins_home/workspace/

# Fix permissions if needed
docker exec -u root jenkins chown -R jenkins:jenkins /var/jenkins_home/workspace/

# In Jenkinsfile, you can also run specific commands as root:
# sh 'sudo command'  # If sudo is available
```

### Cannot Write to Mounted Volume

**Symptoms**: `cannot create directory: Permission denied`

**Solutions**:

```bash
# Check volume ownership
docker volume inspect jenkins_home

# Fix volume permissions
docker run --rm -v jenkins_home:/var/jenkins_home \
  alpine chown -R 1000:1000 /var/jenkins_home

# Or recreate the volume
docker-compose down -v
docker-compose up -d
```

## 📦 Container Issues

### Container Keeps Restarting

**Symptoms**: `docker ps` shows container restarting repeatedly

**Solutions**:

```bash
# Check container logs
docker logs jenkins --tail 100

# Check container restart count
docker inspect jenkins | grep RestartCount

# Common causes and fixes:

# 1. Port already in use
sudo lsof -i :8080
# Kill the process using the port

# 2. Out of memory
docker stats jenkins
# Increase Docker memory limit in Docker settings

# 3. Configuration error
# Review docker-compose.yml or Dockerfile

# Stop auto-restart temporarily to debug
docker update --restart=no jenkins
docker stop jenkins
```

### Container Exited Unexpectedly

**Symptoms**: Container status is "Exited" instead of "Up"

**Solutions**:

```bash
# Check exit code and reason
docker ps -a | grep jenkins

# View logs to find cause
docker logs jenkins

# Common exit codes:
# 0: Successful exit (rare for Jenkins)
# 1: Application error
# 137: Out of memory (killed by OOM killer)
# 139: Segmentation fault

# Try starting with more verbose logging
docker start jenkins
docker logs -f jenkins
```

### Application Container Not Starting

**Symptoms**: `my-test-app` container fails to start in pipeline

**Solutions**:

```bash
# Check if image was built successfully
docker images | grep devsecops-test

# Check container logs
docker logs my-test-app

# Common issues:

# 1. Node modules not installed
# Rebuild image: docker build -t devsecops-test:latest apps/nodejs-app/

# 2. Port already in use
sudo lsof -i :3000
# Stop conflicting process

# 3. Application error
# Check app.js for syntax errors

# Try running container interactively
docker run -it --rm devsecops-test:latest /bin/sh
# Then manually start app to see errors
```

## 🔌 Port Conflicts

### Port Already in Use

**Symptoms**: `Bind for 0.0.0.0:8080 failed: port is already allocated`

**Identify what's using the port**:

```bash
# Linux
sudo lsof -i :8080
sudo netstat -tulpn | grep 8080
sudo ss -tulpn | grep 8080

# macOS
sudo lsof -i :8080

# Find process ID and kill it
sudo kill -9 <PID>
```

**Solutions**:

**Option 1**: Stop the conflicting service
```bash
# Example: If another web server
sudo systemctl stop apache2
sudo systemctl stop nginx
```

**Option 2**: Change Jenkins port
```yaml
# In docker-compose.yml
ports:
  - "8081:8080"  # Use 8081 instead
```

**Option 3**: Use Docker's host network mode (not recommended)
```bash
docker run --network host jenkins/jenkins:lts
```

### Multiple Port Conflicts

Check all required ports:

```bash
# Check all lab ports
for port in 8080 50000 3000 9090 3001; do
    echo "Checking port $port:"
    sudo lsof -i :$port
done
```

## 🚨 Pipeline Failures

### Pipeline Fails at Checkout Stage

**Symptoms**: `Couldn't find any revision to build`

**Solutions**:

```bash
# Verify repository URL in Jenkins job config
# Check branch name (main vs master)

# Test Git access manually
git ls-remote https://github.com/nrmrks/devsecops-home-lab.git

# For private repos, verify credentials
# Jenkins → Manage Credentials → check git credentials

# In Jenkins job, try:
# - Branch: */main and */master
# - Or use specific commit SHA
```

### Pipeline Fails at Docker Build

**Symptoms**: `docker: command not found` or `permission denied`

**Solutions**:

```bash
# Verify Docker socket is mounted
docker inspect jenkins | grep /var/run/docker.sock

# Check Docker permissions
docker exec jenkins docker ps

# If permission denied, fix socket permissions
docker exec -u root jenkins chmod 666 /var/run/docker.sock
docker restart jenkins
```

### Pipeline Fails at Docker Run

**Symptoms**: `docker: Error response from daemon: Conflict`

**Solutions**:

```bash
# Container name already exists
docker ps -a | grep my-test-app

# Remove old container
docker rm -f my-test-app

# Or the pipeline should handle this in "Stop Old Container" stage
```

### Tests Fail in Pipeline

**Symptoms**: npm test returns non-zero exit code

**Solutions**:

```bash
# Run tests locally first
cd apps/nodejs-app
npm install
npm test

# Check test configuration in package.json
cat package.json

# If tests are placeholder, ensure they exit with 0
# In package.json:
# "test": "echo 'Running tests...' && exit 0"
```

## 📋 Log Checking Commands

### Essential Log Commands

```bash
# Jenkins container logs
docker logs jenkins
docker logs jenkins --tail 100
docker logs jenkins --follow
docker logs jenkins --since 10m

# Application container logs  
docker logs my-test-app
docker logs my-test-app --tail 50

# All container logs
docker-compose logs

# Specific service logs
docker-compose logs jenkins

# Real-time logs
docker-compose logs -f

# Docker daemon logs (Linux)
sudo journalctl -u docker.service
sudo journalctl -u docker.service --since today

# Jenkins internal logs
docker exec jenkins cat /var/jenkins_home/logs/tasks/Periodic\ background\ build\ discarder.log
```

### Finding Errors in Logs

```bash
# Search for errors
docker logs jenkins 2>&1 | grep -i error
docker logs jenkins 2>&1 | grep -i exception

# Search for specific terms
docker logs jenkins 2>&1 | grep -i "permission denied"

# Count errors
docker logs jenkins 2>&1 | grep -i error | wc -l

# Save logs to file for analysis
docker logs jenkins > jenkins-logs.txt 2>&1
```

## 🌐 Network Issues

### Container Cannot Connect to Internet

**Symptoms**: Cannot pull packages, timeout errors

**Solutions**:

```bash
# Test internet from container
docker exec jenkins ping google.com

# Check DNS resolution
docker exec jenkins nslookup google.com

# Check Docker network
docker network inspect bridge

# Restart Docker networking
sudo systemctl restart docker

# Configure custom DNS in docker-compose.yml
dns:
  - 8.8.8.8
  - 8.8.4.4
```

### Containers Cannot Communicate

**Symptoms**: Jenkins cannot reach application container

**Solutions**:

```bash
# Ensure containers are on same network
docker network ls
docker network inspect devsecops_default

# Create custom network
docker network create devsecops-network

# In docker-compose.yml, specify network
networks:
  default:
    name: devsecops-network
```

### Cannot Access Container from Host

**Symptoms**: `curl localhost:3000` fails but container is running

**Solutions**:

```bash
# Check port mapping
docker ps | grep my-test-app

# Verify container is listening
docker exec my-test-app netstat -tlnp

# Check if app started correctly
docker logs my-test-app | grep "Server running"

# Try using container IP directly
docker inspect my-test-app | grep IPAddress
curl http://<container-ip>:3000
```

## 🛠️ General Debugging Tips

### Complete System Check

```bash
#!/bin/bash
echo "=== Docker Version ==="
docker --version

echo "=== Docker Status ==="
sudo systemctl status docker

echo "=== Running Containers ==="
docker ps

echo "=== All Containers ==="
docker ps -a

echo "=== Docker Images ==="
docker images

echo "=== Docker Networks ==="
docker network ls

echo "=== Docker Volumes ==="
docker volume ls

echo "=== Disk Space ==="
docker system df

echo "=== Listening Ports ==="
sudo ss -tulpn | grep LISTEN

echo "=== Jenkins Status ==="
docker logs jenkins --tail 20
```

### Reset Everything (Nuclear Option)

**Warning**: This removes all containers, images, and volumes!

```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all images
docker rmi $(docker images -q)

# Remove all volumes
docker volume rm $(docker volume ls -q)

# Remove all networks (except defaults)
docker network prune -f

# Clean system
docker system prune -a --volumes -f

# Restart Docker
sudo systemctl restart docker

# Start fresh
cd docker/jenkins
docker-compose up -d
```

## 📞 Getting Help

If issues persist:

1. **Check Jenkins logs** thoroughly
2. **Search existing issues** on GitHub
3. **Check Docker/Jenkins documentation**
4. **Ask in community forums**:
   - Jenkins Users Google Group
   - Stack Overflow (tag: jenkins)
   - Docker Community Slack

When asking for help, include:
- Operating system and version
- Docker version
- Error messages
- Relevant log output
- Steps to reproduce

## 📚 Additional Resources

- [Docker Troubleshooting](https://docs.docker.com/config/daemon/)
- [Jenkins Troubleshooting](https://www.jenkins.io/doc/book/troubleshooting/)
- [Docker Debugging Guide](https://docs.docker.com/config/containers/logging/)

---

**Remember**: Most issues are related to permissions, ports, or networking. Start with the basics! 🔍
