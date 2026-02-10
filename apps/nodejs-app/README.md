# 📦 Node.js Express Application

A simple Express.js application designed for testing CI/CD pipelines, containerization, and DevSecOps practices.

## 📋 Description

This is a lightweight Node.js application built with Express that provides basic REST API endpoints. It's specifically designed to be used as a sample application for learning and testing:

- CI/CD pipeline configurations
- Docker containerization
- Automated testing
- Deployment strategies
- Monitoring and logging

## 🚀 Features

- **Health Check Endpoint** - Monitor application health
- **JSON API Response** - RESTful API design
- **Timestamp Tracking** - Track request timing
- **Version Information** - Application versioning
- **Minimal Dependencies** - Only Express.js for simplicity

## 📦 Prerequisites

- Node.js (v18.x or higher)
- npm (v8.x or higher)
- Docker (optional, for containerized deployment)

## 🔧 Installation

### Local Development

1. Navigate to the app directory:
   ```bash
   cd apps/nodejs-app
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the application:
   ```bash
   npm start
   ```

The application will start on port 3000 (or the port specified in the `PORT` environment variable).

## 🐳 Building with Docker

### Build the Docker Image

```bash
docker build -t devsecops-nodejs-app:latest .
```

### Run the Container

```bash
docker run -d -p 3000:3000 --name nodejs-app devsecops-nodejs-app:latest
```

### Stop and Remove Container

```bash
docker stop nodejs-app
docker rm nodejs-app
```

## 🔌 API Endpoints

### Root Endpoint

**GET** `/`

Returns application information and current timestamp.

**Example Request:**
```bash
curl http://localhost:3000/
```

**Example Response:**
```json
{
  "message": "Hello from Jenkins CI/CD!",
  "timestamp": "2024-02-10T16:38:47.583Z",
  "version": "1.0.0"
}
```

### Health Check

**GET** `/health`

Returns health status of the application.

**Example Request:**
```bash
curl http://localhost:3000/health
```

**Example Response:**
```json
{
  "status": "healthy"
}
```

## 🧪 Testing

Run the test suite:

```bash
npm test
```

The current test configuration runs a simple validation test. In a production environment, you would add:
- Unit tests
- Integration tests
- API endpoint tests
- Security tests

## 🌍 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Application port | `3000` |

**Example:**
```bash
PORT=8080 npm start
```

## 📝 Package.json Scripts

- `npm start` - Start the application
- `npm test` - Run tests (currently a placeholder)

## 🐳 Dockerfile Details

The Dockerfile uses a multi-stage approach for optimization:

- **Base Image**: `node:18-alpine` (lightweight Linux distribution)
- **Working Directory**: `/app`
- **Port Exposed**: `3000`
- **Entry Point**: `node app.js`

### Build Optimization

The Dockerfile is optimized for:
- Layer caching (dependencies installed before code copy)
- Small image size (Alpine Linux)
- Security (non-root user can be added)
- Fast builds (minimal layers)

## 🔒 Security Considerations

For production deployments, consider:

1. **Run as non-root user** - Add a non-root user in the Dockerfile
2. **Environment variables** - Never commit sensitive data
3. **Dependencies** - Regularly update dependencies for security patches
4. **Input validation** - Add validation for all inputs
5. **Rate limiting** - Implement rate limiting for API endpoints
6. **HTTPS** - Use HTTPS in production environments

## 📊 Monitoring

### Application Logs

View application logs when running in Docker:

```bash
docker logs nodejs-app
```

### Container Stats

Monitor resource usage:

```bash
docker stats nodejs-app
```

## 🔄 CI/CD Integration

This application is integrated with Jenkins pipeline (`../../jenkins/Jenkinsfile`) which:

1. Checks out code from repository
2. Builds Docker image
3. Runs tests inside container
4. Deploys container
5. Verifies deployment

## 🚀 Future Enhancements

Potential improvements for this application:

- [ ] Add comprehensive test suite (Jest/Mocha)
- [ ] Add database connectivity (PostgreSQL/MongoDB)
- [ ] Implement authentication/authorization
- [ ] Add Swagger/OpenAPI documentation
- [ ] Implement logging framework (Winston/Bunyan)
- [ ] Add metrics collection (Prometheus client)
- [ ] Implement graceful shutdown
- [ ] Add request validation middleware

## 🤝 Contributing

When adding features to this application:

1. Maintain simplicity - it's meant to be a learning tool
2. Add tests for new endpoints
3. Update this README with new endpoints/features
4. Ensure Docker build still works
5. Test with the Jenkins pipeline

## 📚 Additional Resources

- [Express.js Documentation](https://expressjs.com/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [Docker Node.js Guide](https://nodejs.org/en/docs/guides/nodejs-docker-webapp/)

---

**Note**: This is a sample application for learning purposes. For production use, implement proper security measures, error handling, logging, and testing.
