# Dependency Audit Summary

**Date**: 2025-11-11T07:44:54.892531

## Summary

- **Total Packages**: 139
- **Conflicting Packages**: 57
- **High Severity Conflicts**: 11
- **Services Analyzed**: 13

## Conflicts

### uvicorn [LOW]

- **Services**: execution, data, ai, portfolio, api, app, analyze, web, main, monitor
- **Versions**: [standard], >=0.32.0, [standard]>=0.38.0, [standard]>=0.27.0, [standard]>=0.24.0, [standard]>=0.32.0, [standard]==0.24.0

### pydantic [LOW]

- **Services**: execution, ai, api, app, analyze, web, main, portfolio, monitor
- **Versions**: >=2, >=2.5.0, >=2.12.4, ==2.5.0, >=2.9.0, >=2.0, >=2.0.0

### langchain [LOW]

- **Services**: ai, main, analyze
- **Versions**: >=0.3.0,<0.4.0, >=0.3.0

### langchain-core [LOW]

- **Services**: ai, analyze
- **Versions**: >=0.3.0,<0.4.0, >=0.3.0

### langchain-community [LOW]

- **Services**: ai, main, analyze
- **Versions**: >=0.3.0,<0.4.0, >=0.3.0

### langchain-ollama [LOW]

- **Services**: ai, analyze
- **Versions**: >=0.2.0, >=0.1.0,<2.0.0

### ollama [LOW]

- **Services**: web, ai, main, analyze
- **Versions**: >=0.1.7, >=0.3.0, >=0.4.0, >=0.1.0,<1.0.0

### chromadb [LOW]

- **Services**: ai, main, analyze
- **Versions**: >=0.4.0,<1.0.0, >=0.5.0

### sentence-transformers [LOW]

- **Services**: web, ai, main, analyze
- **Versions**: >=2.2.0,<6.0.0, >=3.3.0, >=3.0.0, >=2.2.0

### httpx [LOW]

- **Services**: execution, training, ai, api, analyze, web, portfolio, monitor
- **Versions**: >=0.26.0, >=0.25.0, any, ==0.25.2, >=0.26.0,<0.29.0

### ta-lib [LOW]

- **Services**: ai, main, portfolio, training
- **Versions**: >=0.4.0, >=0.4.28

### pytest [LOW]

- **Services**: training, ai, portfolio, web, main, monitor
- **Versions**: >=7.4.3, >=8.3.0, >=7.4.0

### pytest-asyncio [LOW]

- **Services**: training, ai, web, main, monitor
- **Versions**: >=0.24.0, >=0.21.0, >=0.23.2

### pytest-cov [LOW]

- **Services**: training, ai, portfolio, main, monitor
- **Versions**: >=6.0.0, >=4.1.0

### pydantic-settings [LOW]

- **Services**: analyze, web, monitor
- **Versions**: >=2.1.0, >=2.11.0

### python-multipart [LOW]

- **Services**: analyze, execution
- **Versions**: ==0.0.6, >=0.0.20

### pyyaml [LOW]

- **Services**: analyze, execution, monitor, main
- **Versions**: >=6.0, >=6.0.3, >=6.0.1, ==6.0.1

### prometheus-client [LOW]

- **Services**: execution, analyze, app, main, monitor
- **Versions**: >=0.20.0, >=0.19.0, >=0.21.0, ==0.19.0, >=0.23.1

### google-generativeai [LOW]

- **Services**: web, analyze, main, monitor
- **Versions**: >=0.8.3, >=0.3.0,<1.0.0, >=0.3.0

### pypdf [LOW]

- **Services**: analyze, main
- **Versions**: >=5.1.0, >=3.17.0,<7.0.0

### python-docx [LOW]

- **Services**: analyze, main
- **Versions**: >=1.1.2, >=1.2.0

### loguru [LOW]

- **Services**: training, portfolio, analyze, web, main
- **Versions**: >=0.7.0, >=0.7.3, >=0.7.2

### requests [LOW]

- **Services**: execution, data, api, web, main, portfolio
- **Versions**: ==2.31.0, >=2.31.0, >=2.32.0, >=2.32.3, any

### pytz [LOW]

- **Services**: main, data, training, api
- **Versions**: any, >=2024.2

### mlflow [LOW]

- **Services**: training, api
- **Versions**: ==3.3.2, >=3.3.0

### optuna [LOW]

- **Services**: app, main, training
- **Versions**: >=4.0.0, ==4.5.0

### scikit-learn [LOW]

- **Services**: app, main, training
- **Versions**: >=1.3.0, >=1.5.0, ==1.7.1

### scipy [LOW]

- **Services**: app, main, portfolio, training
- **Versions**: >=1.13.0, >=1.11.0, >=1.10.0

### ccxt [LOW]

- **Services**: app, execution, portfolio, main
- **Versions**: >=4.0.0, >=4.4.0, >=4.5.0

### sqlalchemy [LOW]

- **Services**: web, main, data
- **Versions**: >=2.0.23, >=2.0.44, >=2.0.0

### psycopg2-binary [LOW]

- **Services**: web, main, data
- **Versions**: >=2.9.11, >=2.9.9

### yfinance [LOW]

- **Services**: portfolio, main, data, training
- **Versions**: >=0.2.48, >=0.2.0, >=0.2.28

### cryptography [LOW]

- **Services**: web, execution, data
- **Versions**: >=41.0.0, >=42.0.0, ==41.0.7

### gunicorn [LOW]

- **Services**: web, main, data
- **Versions**: >=21.2.0, >=23.0.0

### python-jose [LOW]

- **Services**: execution, main
- **Versions**: [cryptography]==3.3.0, >=3.5.0

### python-dotenv [LOW]

- **Services**: web, execution, portfolio, main
- **Versions**: >=1.1.1, >=1.0.0, ==1.0.0, >=1.0.1

### whitenoise [LOW]

- **Services**: web, main
- **Versions**: >=6.11.0, >=6.6.0

### aiohttp [LOW]

- **Services**: web, main, monitor
- **Versions**: >=3.13.1, >=3.9.0

### openai [LOW]

- **Services**: web, main
- **Versions**: >=1.54.0, >=1.12.0

### transformers [LOW]

- **Services**: web, main, training
- **Versions**: >=4.46.0, ==4.56.0, >=4.35.0

### accelerate [LOW]

- **Services**: main, training
- **Versions**: >=1.0.0, ==1.10.1

### matplotlib [LOW]

- **Services**: main, training
- **Versions**: ==3.10.6, >=3.9.0

### seaborn [LOW]

- **Services**: main, training
- **Versions**: ==0.13.2, >=0.13.2

### psutil [LOW]

- **Services**: web, main
- **Versions**: >=6.1.0, >=5.9.0

### pytest-mock [LOW]

- **Services**: main, training
- **Versions**: >=3.14.0, >=3.11.0

### mypy [LOW]

- **Services**: main, monitor
- **Versions**: >=1.13.0, >=1.7.0

### fastapi [HIGH]

- **Services**: execution, data, ai, portfolio, api, app, analyze, main, monitor
- **Versions**: >=0.121.1, >=0.104.0, >=0.115.0, ==0.104.1, any

### numpy [HIGH]

- **Services**: data, training, ai, portfolio, api, app, web, main
- **Versions**: >=1.24.0, >=1.23.5,<2.0.0, >=1.26.0,<2.0, >=1.26.0

### pandas [HIGH]

- **Services**: data, training, ai, portfolio, app, web, main
- **Versions**: >=2.2.0, ==2.3.2, >=2.0.0

### redis [HIGH]

- **Services**: web, analyze, main, app
- **Versions**: >=5.2.0, >=5.0.0,<8.0.0, >=5.2.0,<5.3.0, >=5.0.0

### celery [HIGH]

- **Services**: web, app, main, api
- **Versions**: [redis]>=5.5.3, >=5.3.0, [redis]>=5.3.0, >=5.5.3

### djangorestframework [HIGH]

- **Services**: web, main
- **Versions**: >=3.15.2, >=3.16.1

### django-cors-headers [HIGH]

- **Services**: web, main
- **Versions**: >=4.7.0, >=4.9.0

### torch [HIGH]

- **Services**: web, main, training
- **Versions**: >=2.4.0, ==2.8.0, >=2.0.0

### torchvision [HIGH]

- **Services**: main, training
- **Versions**: ==0.23.0, >=0.19.0

### pytest-django [HIGH]

- **Services**: web, main
- **Versions**: >=4.7.0, >=4.9.0

### django-axes [HIGH]

- **Services**: web, main
- **Versions**: >=7.0.0, >=8.0.0

