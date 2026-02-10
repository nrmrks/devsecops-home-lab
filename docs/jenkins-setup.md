# 🔧 Jenkins Setup Guide

Comprehensive guide for Jenkins installation, configuration, and pipeline setup for the DevSecOps home lab.

## 📋 Table of Contents

1. [Jenkins Installation](#jenkins-installation)
2. [Plugin Installation](#plugin-installation)
3. [Credential Setup](#credential-setup)
4. [Pipeline Job Creation](#pipeline-job-creation)
5. [Webhook Configuration](#webhook-configuration)
6. [Advanced Configuration](#advanced-configuration)
7. [Best Practices](#best-practices)

## 🐳 Jenkins Installation

### Installation as Docker Container

#### Option 1: Using Docker Compose (Recommended)

Navigate to the docker directory and use the provided configuration:

```bash
cd docker/jenkins
docker-compose up -d
```

The `docker-compose.yml` includes:
- Jenkins LTS version
- Persistent volume for Jenkins home
- Docker socket mounting for Docker-in-Docker
- Port mappings (8080 for web, 50000 for agents)
- Auto-restart policy

#### Option 2: Using Docker CLI

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

### Initial Setup

1. **Access Jenkins**:
   ```
   http://localhost:8080
   ```

2. **Get Initial Admin Password**:
   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```

3. **Complete Setup Wizard**:
   - Paste the initial admin password
   - Choose "Install suggested plugins"
   - Create first admin user
   - Configure Jenkins URL

## 🔌 Plugin Installation

### Essential Plugins

Install these plugins for full DevSecOps functionality:

#### Core Plugins (Usually Pre-installed)
- **Git Plugin** - Git repository integration
- **Pipeline Plugin** - Pipeline as code support
- **Credentials Plugin** - Secure credential management
- **Workspace Cleanup Plugin** - Clean workspace between builds

#### Docker Plugins
- **Docker Plugin** - Docker integration
- **Docker Pipeline Plugin** - Docker commands in pipelines
- **Docker Commons Plugin** - Common Docker functionality

#### Additional Recommended Plugins
- **Blue Ocean** - Modern UI for pipelines
- **GitHub Plugin** - GitHub integration
- **Slack Notification Plugin** - Slack notifications
- **Email Extension Plugin** - Advanced email notifications
- **Build Timeout Plugin** - Timeout configuration

### Installing Plugins

#### Via Web UI:

1. Navigate to **Manage Jenkins** → **Manage Plugins**
2. Click **Available** tab
3. Search for plugin name
4. Check the box next to desired plugins
5. Click **Install without restart** or **Download now and install after restart**

#### Via Jenkins CLI:

```bash
# Download Jenkins CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# Install plugin
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:password install-plugin docker-workflow
```

#### Via Dockerfile (Pre-install):

Create a custom Jenkins image with pre-installed plugins:

```dockerfile
FROM jenkins/jenkins:lts

# Install plugins
RUN jenkins-plugin-cli --plugins \
    git \
    docker-workflow \
    pipeline-stage-view \
    blueocean \
    credentials-binding \
    github
```

### Verify Plugin Installation

1. Go to **Manage Jenkins** → **Manage Plugins**
2. Click **Installed** tab
3. Search for plugin to verify installation

## 🔐 Credential Setup

### Types of Credentials

Jenkins supports various credential types:
- Username with password
- SSH Username with private key
- Secret text
- Secret file
- Certificate

### Adding Credentials

#### 1. Access Credentials Manager

**Manage Jenkins** → **Manage Credentials** → **System** → **Global credentials**

#### 2. Add Docker Hub Credentials (Optional)

For private Docker registries:

1. Click **Add Credentials**
2. Select **Username with password**
3. Fill in:
   - **Username**: Your Docker Hub username
   - **Password**: Your Docker Hub password
   - **ID**: `dockerhub-credentials`
   - **Description**: "Docker Hub Login"
4. Click **OK**

#### 3. Add GitHub Credentials

For private repositories:

1. Generate GitHub Personal Access Token:
   - Go to GitHub → Settings → Developer settings → Personal access tokens
   - Click "Generate new token"
   - Select scopes: `repo`, `admin:repo_hook`
   - Copy the token

2. Add to Jenkins:
   - Click **Add Credentials**
   - Select **Secret text** or **Username with password**
   - Fill in:
     - **Secret/Password**: Your GitHub token
     - **ID**: `github-token`
     - **Description**: "GitHub Access Token"
   - Click **OK**

#### 4. Add SSH Keys (For Git over SSH)

1. Generate SSH key pair:
   ```bash
   ssh-keygen -t rsa -b 4096 -C "jenkins@devsecops-lab"
   ```

2. Add public key to GitHub/GitLab
3. Add private key to Jenkins:
   - Click **Add Credentials**
   - Select **SSH Username with private key**
   - Fill in:
     - **Username**: `git`
     - **Private Key**: Paste private key
     - **ID**: `git-ssh-key`
     - **Passphrase**: If applicable
   - Click **OK**

### Using Credentials in Pipelines

#### With Credentials Binding:

```groovy
pipeline {
    agent any
    environment {
        DOCKER_CREDENTIALS = credentials('dockerhub-credentials')
    }
    stages {
        stage('Docker Login') {
            steps {
                sh 'echo $DOCKER_CREDENTIALS_PSW | docker login -u $DOCKER_CREDENTIALS_USR --password-stdin'
            }
        }
    }
}
```

#### With withCredentials:

```groovy
withCredentials([usernamePassword(
    credentialsId: 'dockerhub-credentials',
    usernameVariable: 'DOCKER_USER',
    passwordVariable: 'DOCKER_PASS'
)]) {
    sh 'docker login -u $DOCKER_USER -p $DOCKER_PASS'
}
```

## 📝 Pipeline Job Creation

### Creating a Pipeline Job

#### 1. Create New Item

1. Click **New Item** from Jenkins dashboard
2. Enter job name: `devsecops-nodejs-pipeline`
3. Select **Pipeline**
4. Click **OK**

#### 2. Configure General Settings

- **Description**: "DevSecOps pipeline for Node.js application"
- **Discard old builds**: Keep last 10 builds
- **GitHub project**: (Optional) Add repository URL

#### 3. Configure Build Triggers

Choose one or more:

**Poll SCM**:
```
H/5 * * * *  # Check every 5 minutes
```

**GitHub hook trigger** (requires webhook setup):
- Check "GitHub hook trigger for GITScm polling"

**Build periodically** (not recommended for production):
```
H 2 * * *  # Every day at 2 AM
```

#### 4. Configure Pipeline

**Definition**: Pipeline script from SCM

**SCM**: Git
- **Repository URL**: `https://github.com/nrmrks/devsecops-home-lab.git`
- **Credentials**: Select if private repository
- **Branch Specifier**: `*/main` or `*/master`

**Script Path**: `jenkins/Jenkinsfile`

**Additional Options**:
- **Lightweight checkout**: Uncheck for full clone
- **Clean before checkout**: Check for clean workspace

#### 5. Save and Build

1. Click **Save**
2. Click **Build Now** to test
3. View build progress in **Build History**
4. Click on build number → **Console Output** for logs

### Pipeline Configuration Examples

#### Simple Inline Pipeline:

```groovy
pipeline {
    agent any
    stages {
        stage('Hello') {
            steps {
                echo 'Hello DevSecOps!'
            }
        }
    }
}
```

#### Multi-Branch Pipeline:

For projects with multiple branches:

1. **New Item** → **Multibranch Pipeline**
2. Add **Branch Source** → **Git**
3. Set repository URL
4. **Discover branches** → All branches
5. **Build Configuration** → by Jenkinsfile
6. **Script Path**: `jenkins/Jenkinsfile`
7. Save

## 🔔 Webhook Configuration

### GitHub Webhooks

Automate builds on code push/PR:

#### 1. In Jenkins:

1. Install **GitHub Plugin**
2. Go to **Manage Jenkins** → **Configure System**
3. Under **GitHub**, add GitHub server:
   - **API URL**: `https://api.github.com`
   - **Credentials**: Add GitHub token
   - Test connection
4. In job configuration:
   - Check **GitHub hook trigger for GITScm polling**

#### 2. In GitHub:

1. Go to repository → **Settings** → **Webhooks**
2. Click **Add webhook**
3. Fill in:
   - **Payload URL**: `http://your-jenkins-url:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Which events**: Just the push event (or customize)
   - **Active**: Checked
4. Click **Add webhook**
5. Test webhook by pushing a commit

#### Troubleshooting Webhooks:

```bash
# Check webhook deliveries in GitHub
# Settings → Webhooks → Recent Deliveries

# Check Jenkins logs
docker logs jenkins | grep webhook

# Verify Jenkins is accessible from internet
curl http://your-public-ip:8080/github-webhook/
```

### GitLab Webhooks

Similar process:

1. In GitLab: **Settings** → **Webhooks**
2. URL: `http://your-jenkins-url:8080/project/job-name`
3. Trigger: Push events
4. Add webhook

## ⚙️ Advanced Configuration

### Docker-in-Docker Setup

Allow Jenkins to use Docker:

```bash
# Give Jenkins user Docker permissions
docker exec -u root jenkins chmod 666 /var/run/docker.sock

# Or add jenkins user to docker group
docker exec -u root jenkins usermod -aG docker jenkins
docker restart jenkins
```

### Global Tool Configuration

Configure tools globally:

1. **Manage Jenkins** → **Global Tool Configuration**

2. **JDK**:
   - Name: `JDK11`
   - Install automatically from Oracle/AdoptOpenJDK

3. **Git**:
   - Name: `Default`
   - Path: `git`

4. **Docker**:
   - Name: `docker`
   - Installation directory: `/usr/bin/docker`

### Environment Variables

Set global environment variables:

1. **Manage Jenkins** → **Configure System**
2. **Global properties** → **Environment variables**
3. Add:
   - `DOCKER_REGISTRY`: `docker.io`
   - `APP_NAME`: `devsecops-app`

### Shared Libraries

For reusable pipeline code:

1. Create library repository with structure:
   ```
   vars/
     buildDockerImage.groovy
     deployApp.groovy
   ```

2. In Jenkins: **Manage Jenkins** → **Configure System**
3. **Global Pipeline Libraries**:
   - Name: `devsecops-lib`
   - Default version: `main`
   - Repository URL: `https://github.com/your-org/jenkins-library`

4. Use in Jenkinsfile:
   ```groovy
   @Library('devsecops-lib') _
   buildDockerImage()
   ```

## 🎯 Best Practices

### Security Best Practices

1. **Use Credentials Plugin**: Never hardcode secrets
2. **Role-Based Access**: Configure matrix-based security
3. **Regular Updates**: Keep Jenkins and plugins updated
4. **Audit Logs**: Enable and review audit logs
5. **HTTPS**: Use HTTPS for Jenkins (with reverse proxy)

### Pipeline Best Practices

1. **Use Declarative Syntax**: More structured and easier
2. **Parameterize**: Use parameters for flexibility
3. **Error Handling**: Implement try-catch blocks
4. **Notifications**: Add Slack/email notifications
5. **Cleanup**: Always cleanup in `post` section

### Performance Best Practices

1. **Agents**: Use specific agents for different jobs
2. **Parallel Execution**: Run independent stages in parallel
3. **Caching**: Cache dependencies when possible
4. **Workspace Cleanup**: Clean unnecessary files
5. **Resource Limits**: Set timeout and resource limits

### Example Optimized Pipeline:

```groovy
pipeline {
    agent any
    
    options {
        timeout(time: 1, unit: 'HOURS')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'])
        booleanParam(name: 'RUN_TESTS', defaultValue: true)
    }
    
    stages {
        stage('Parallel Tasks') {
            parallel {
                stage('Build') {
                    steps { /* build steps */ }
                }
                stage('Test') {
                    when { expression { params.RUN_TESTS } }
                    steps { /* test steps */ }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
```

## 📚 Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Pipeline Syntax Reference](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Plugin Index](https://plugins.jenkins.io/)
- [Jenkins Best Practices](https://www.jenkins.io/doc/book/pipeline/pipeline-best-practices/)

---

**Next**: [Troubleshooting Guide](troubleshooting.md) | [Back to Setup Guide](setup-guide.md)
