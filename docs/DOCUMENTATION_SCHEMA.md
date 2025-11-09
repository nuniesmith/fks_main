# FKS Documentation Schema

**Version**: 1.0  
**Last Updated**: November 2025  
**Purpose**: Standardized documentation structure for all FKS microservices

## 📋 Schema Overview

All FKS service documentation must follow this standardized structure to ensure consistency, maintainability, and ease of onboarding.

## 📁 Service README.md Structure

Every service README.md must include the following sections in this order:

### 1. Service Header
```markdown
# {Service Name}

{One-line description of the service's purpose}

**Port**: {port_number}  
**Framework**: {language/framework}  
**Role**: {primary responsibility}
```

### 2. 🎯 Purpose
```markdown
## 🎯 Purpose

Clear explanation of what this service does and why it exists in the FKS ecosystem.
```

### 3. 🏗️ Architecture
```markdown
## 🏗️ Architecture

- How the service fits into the overall FKS architecture
- Key components and their relationships
- Data flow diagrams (if applicable)
```

### 4. 🚀 Quick Start
```markdown
## 🚀 Quick Start

### Development
[Local development setup]

### Docker
[Docker setup]

### Kubernetes
[K8s deployment]
```

### 5. 📡 API Endpoints
```markdown
## 📡 API Endpoints

### Health Checks
- `GET /health` - Health check
- `GET /ready` - Readiness check
- `GET /live` - Liveness probe

### Service-Specific Endpoints
[List all endpoints]
```

### 6. 🔧 Configuration
```markdown
## 🔧 Configuration

### Environment Variables
[List all environment variables with descriptions]

### Configuration Files
[Any config files]
```

### 7. 🧪 Testing
```markdown
## 🧪 Testing

```bash
# Run tests
{test_command}
```
```

### 8. 🐳 Docker
```markdown
## 🐳 Docker

### Build
[Build instructions]

### Run
[Run instructions]
```

### 9. ☸️ Kubernetes
```markdown
## ☸️ Kubernetes

[K8s deployment instructions]
```

### 10. 📚 Documentation
```markdown
## 📚 Documentation

- [API Documentation](docs/API.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Architecture Details](docs/ARCHITECTURE.md)
```

### 11. 🔗 Integration
```markdown
## 🔗 Integration

### Dependencies
- Services this depends on
- External services/APIs

### Consumers
- Services that depend on this
```

### 12. 📊 Monitoring
```markdown
## 📊 Monitoring

- Health check endpoints
- Metrics exposed
- Logging configuration
```

### 13. 🛠️ Development
```markdown
## 🛠️ Development

### Setup
[Development setup]

### Code Structure
[Directory structure]

### Contributing
[Contributing guidelines]
```

### 14. Footer
```markdown
---

**Repository**: [nuniesmith/{repo_name}](https://github.com/nuniesmith/{repo_name})  
**Docker Image**: `nuniesmith/fks:{service_name}-latest`  
**Status**: {Active/Development/Deprecated}
```

## 📝 Service-Specific Documentation

Each service should have a `docs/` directory with:

- `API.md` - Complete API documentation
- `DEPLOYMENT.md` - Deployment instructions
- `ARCHITECTURE.md` - Detailed architecture (if complex)
- `CHANGELOG.md` - Service changelog

## 🎨 Documentation Standards

### Language & Tone
- Clear, concise, and professional
- Use active voice
- Avoid jargon unless necessary
- Include examples

### Code Blocks
- Always specify language
- Include expected output
- Show error handling

### Links
- Use relative paths for internal docs
- Use absolute URLs for external resources
- Keep links up-to-date

### Versioning
- Include version numbers for APIs
- Document breaking changes
- Maintain changelogs

## ✅ Validation Checklist

Before marking documentation as complete, verify:

- [ ] All required sections are present
- [ ] Code examples are tested and working
- [ ] Environment variables are documented
- [ ] API endpoints are complete
- [ ] Links are valid
- [ ] Service role is clearly defined
- [ ] Integration points are documented
- [ ] Deployment instructions are accurate
- [ ] Health check endpoints are documented
- [ ] Repository and Docker image links are correct

## 🔄 Maintenance

- Update documentation with each release
- Review quarterly for accuracy
- Keep examples current
- Remove deprecated information
- Add migration guides for breaking changes

