# 🔐 DevSecOps Home Lab

A comprehensive learning environment for practicing DevSecOps concepts, including CI/CD pipelines, containerization, security scanning, and monitoring.

## 📋 Table of Contents

- [What is DevSecOps?](#what-is-devsecops)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Directory Structure](#directory-structure)
- [Documentation](#documentation)
- [Usage Examples](#usage-examples)
- [Contributing](#contributing)
- [License](#license)

## 🔍 What is DevSecOps?

**DevSecOps** stands for Development, Security, and Operations. It's a philosophy that integrates security practices within the DevOps process. Instead of treating security as a separate phase at the end of development, DevSecOps makes security a shared responsibility throughout the entire software development lifecycle.

### Key Principles:
- **Shift Left**: Integrate security early in the development process
- **Automation**: Automate security testing and compliance checks
- **Continuous Monitoring**: Monitor applications and infrastructure for security threats
- **Collaboration**: Foster collaboration between development, security, and operations teams

## ✨ Features

This home lab provides hands-on experience with:

- 🐳 **Docker Containerization** - Build and deploy containerized applications
- 🔄 **Jenkins CI/CD Pipelines** - Automated build, test, and deployment workflows
- 🔒 **Security Scanning** - Integration points for security tools (SAST, DAST, dependency scanning)
- 📊 **Monitoring & Logging** - Observability setup with Prometheus and Grafana
- 🚀 **Sample Applications** - Pre-configured Node.js application for testing
- 📚 **Comprehensive Documentation** - Step-by-step guides for setup and usage

## 📦 Prerequisites

Before getting started, ensure you have the following installed:

- **Docker** (v20.10 or higher)
- **Docker Compose** (v2.0 or higher)
- **Git** (v2.30 or higher)
- **Basic knowledge** of:
  - Command line/terminal usage
  - Docker concepts
  - CI/CD fundamentals

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/nrmrks/devsecops-home-lab.git
cd devsecops-home-lab
```

### 2. Set Up Jenkins

Use the automated setup script:

```bash
chmod +x scripts/setup-jenkins.sh
./scripts/setup-jenkins.sh
```

Or manually with Docker Compose:

```bash
cd docker/jenkins
docker-compose up -d
```

### 3. Access Jenkins

1. Open your browser and navigate to `http://localhost:8080`
2. Retrieve the initial admin password:
   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```
3. Complete the setup wizard
4. Install suggested plugins

### 4. Create Your First Pipeline

1. In Jenkins, click "New Item"
2. Enter a name, select "Pipeline", and click OK
3. Under "Pipeline" section, select "Pipeline script from SCM"
4. Set SCM to "Git"
5. Enter repository URL and set Script Path to `jenkins/Jenkinsfile`
6. Save and run the pipeline

### 5. Test the Application

Once the pipeline completes successfully:

```bash
curl http://localhost:3000
```

You should see a JSON response from the application!

## 📁 Directory Structure

```
devsecops-home-lab/
├── README.md                      # This file - main documentation
├── .gitignore                     # Git ignore patterns
├── docs/                          # Detailed documentation
│   ├── setup-guide.md            # Complete setup instructions
│   ├── jenkins-setup.md          # Jenkins configuration guide
│   └── troubleshooting.md        # Common issues and solutions
├── apps/                          # Sample applications
│   └── nodejs-app/               # Node.js Express application
│       ├── Dockerfile            # Container build instructions
│       ├── app.js                # Application source code
│       ├── package.json          # Dependencies and scripts
│       └── README.md             # App-specific documentation
├── jenkins/                       # Jenkins configuration
│   ├── Jenkinsfile               # Main CI/CD pipeline
│   └── pipelines/                # Example pipeline scripts
│       ├── basic-pipeline.groovy # Simple pipeline example
│       ├── docker-build.groovy   # Docker-focused pipeline
│       └── security-scan.groovy  # Security scanning pipeline
├── docker/                        # Docker configurations
│   ├── jenkins/                  # Jenkins container setup
│   │   └── docker-compose.yml    # Jenkins service definition
│   └── monitoring/               # Monitoring stack
│       └── docker-compose.yml    # Prometheus & Grafana setup
└── scripts/                       # Utility scripts
    ├── setup-jenkins.sh          # Automated Jenkins setup
    └── cleanup.sh                # Environment cleanup
```

## 📖 Documentation

Detailed guides are available in the `docs/` directory:

- **[Setup Guide](docs/setup-guide.md)** - Comprehensive installation and configuration
- **[Jenkins Setup](docs/jenkins-setup.md)** - Jenkins-specific configuration details
- **[Troubleshooting](docs/troubleshooting.md)** - Solutions to common problems

## 💡 Usage Examples

### Running the Node.js Application Locally

```bash
cd apps/nodejs-app
npm install
npm start
```

### Building the Docker Image

```bash
cd apps/nodejs-app
docker build -t devsecops-test:latest .
```

### Running Example Pipelines

Different pipeline examples are available in `jenkins/pipelines/`:

- **Basic Pipeline**: Simple build and test workflow
- **Docker Build**: Focused on container image creation
- **Security Scan**: Template for integrating security tools

To use an example pipeline, copy it to `jenkins/Jenkinsfile` or reference it directly in your Jenkins job configuration.

### Monitoring Setup (Coming Soon)

```bash
cd docker/monitoring
docker-compose up -d
```

Access monitoring dashboards:
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3001`

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Guidelines

- Follow existing code style and conventions
- Update documentation for any changed functionality
- Test your changes thoroughly
- Keep commits focused and atomic

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- Inspired by real-world DevSecOps practices
- Built for learning and educational purposes
- Community contributions welcome!

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Troubleshooting Guide](docs/troubleshooting.md)
2. Search existing [GitHub Issues](https://github.com/nrmrks/devsecops-home-lab/issues)
3. Open a new issue with detailed information

---

**Happy Learning! 🚀**

*Remember: The best way to learn is by doing. Don't be afraid to experiment and break things - that's what a lab environment is for!*
