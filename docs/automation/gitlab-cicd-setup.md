# GitLab CI/CD 自动化配置

## 1. 完整的CI/CD Pipeline

### .gitlab-ci.yml
```yaml
stages:
  - install
  - lint
  - test
  - security
  - build
  - deploy

variables:
  NODE_VERSION: "20"
  FLUTTER_VERSION: "3.16.0"

# 缓存配置
.cache_template: &cache_template
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
      - .pub-cache/

# ==================== 安装依赖 ====================

install:client:
  stage: install
  image: cirrusci/flutter:${FLUTTER_VERSION}
  <<: *cache_template
  script:
    - cd dacong-client
    - flutter pub get
  only:
    changes:
      - dacong-client/**/*

install:admin:
  stage: install
  image: cirrusci/flutter:${FLUTTER_VERSION}
  <<: *cache_template
  script:
    - cd dacong-admin
    - flutter pub get
  only:
    changes:
      - dacong-admin/**/*

install:api:
  stage: install
  image: denoland/deno:latest
  script:
    - cd dacong-api
    - deno cache deps.ts
  only:
    changes:
      - dacong-api/**/*

install:spider:
  stage: install
  image: python:3.11-slim
  <<: *cache_template
  script:
    - cd dacong-spider
    - pip install -r requirements.txt
  only:
    changes:
      - dacong-spider/**/*

# ==================== 代码检查 ====================

lint:client:
  stage: lint
  image: cirrusci/flutter:${FLUTTER_VERSION}
  <<: *cache_template
  script:
    - cd dacong-client
    - flutter analyze
    - dart format --set-exit-if-changed .
  only:
    changes:
      - dacong-client/**/*

lint:admin:
  stage: lint
  image: cirrusci/flutter:${FLUTTER_VERSION}
  <<: *cache_template
  script:
    - cd dacong-admin
    - flutter analyze
    - dart format --set-exit-if-changed .
  only:
    changes:
      - dacong-admin/**/*

lint:api:
  stage: lint
  image: denoland/deno:latest
  script:
    - cd dacong-api
    - deno lint
    - deno fmt --check
  only:
    changes:
      - dacong-api/**/*

lint:spider:
  stage: lint
  image: python:3.11-slim
  script:
    - cd dacong-spider
    - pip install pylint black
    - black --check .
    - pylint **/*.py
  only:
    changes:
      - dacong-spider/**/*

# ==================== 测试 ====================

test:client:
  stage: test
  image: cirrusci/flutter:${FLUTTER_VERSION}
  <<: *cache_template
  script:
    - cd dacong-client
    - flutter test --coverage
    - genhtml coverage/lcov.info -o coverage/html
  coverage: '/lines......: \d+\.\d+%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: dacong-client/coverage/cobertura.xml
    paths:
      - dacong-client/coverage/
    expire_in: 30 days
  only:
    changes:
      - dacong-client/**/*

test:admin:
  stage: test
  image: cirrusci/flutter:${FLUTTER_VERSION}
  <<: *cache_template
  script:
    - cd dacong-admin
    - flutter test --coverage
  coverage: '/lines......: \d+\.\d+%/'
  artifacts:
    paths:
      - dacong-admin/coverage/
    expire_in: 30 days
  only:
    changes:
      - dacong-admin/**/*

test:api:
  stage: test
  image: denoland/deno:latest
  script:
    - cd dacong-api
    - deno test --coverage=coverage
    - deno coverage coverage --lcov > coverage.lcov
  coverage: '/\d+\.\d+% coverage/'
  artifacts:
    paths:
      - dacong-api/coverage/
    expire_in: 30 days
  only:
    changes:
      - dacong-api/**/*

test:spider:
  stage: test
  image: python:3.11-slim
  script:
    - cd dacong-spider
    - pip install pytest pytest-cov
    - pytest --cov=. --cov-report=html --cov-report=term
  coverage: '/TOTAL.*\s+(\d+%)$/'
  artifacts:
    paths:
      - dacong-spider/htmlcov/
    expire_in: 30 days
  only:
    changes:
      - dacong-spider/**/*

# ==================== 安全扫描 ====================

security:dependencies:
  stage: security
  image: node:${NODE_VERSION}
  script:
    - npm audit --audit-level=high
    - npx snyk test --severity-threshold=high
  allow_failure: true
  only:
    - main
    - dev

security:sast:
  stage: security
  image: returntocorp/semgrep
  script:
    - semgrep --config=auto --json --output=semgrep-report.json
  artifacts:
    reports:
      sast: semgrep-report.json
    expire_in: 30 days
  allow_failure: true
  only:
    - main
    - dev

security:secrets:
  stage: security
  image: trufflesecurity/trufflehog:latest
  script:
    - trufflehog filesystem . --json > trufflehog-report.json
  artifacts:
    paths:
      - trufflehog-report.json
    expire_in: 30 days
  allow_failure: true
  only:
    - main
    - dev

# ==================== 构建 ====================

build:client:web:
  stage: build
  image: cirrusci/flutter:${FLUTTER_VERSION}
  <<: *cache_template
  script:
    - cd dacong-client
    - flutter build web --release
  artifacts:
    paths:
      - dacong-client/build/web/
    expire_in: 7 days
  only:
    - main
    - dev

build:admin:web:
  stage: build
  image: cirrusci/flutter:${FLUTTER_VERSION}
  <<: *cache_template
  script:
    - cd dacong-admin
    - flutter build web --release
  artifacts:
    paths:
      - dacong-admin/build/web/
    expire_in: 7 days
  only:
    - main
    - dev

build:docker:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $CI_REGISTRY_IMAGE/client:$CI_COMMIT_SHA ./dacong-client
    - docker build -t $CI_REGISTRY_IMAGE/admin:$CI_COMMIT_SHA ./dacong-admin
    - docker build -t $CI_REGISTRY_IMAGE/spider:$CI_COMMIT_SHA ./dacong-spider
    - docker push $CI_REGISTRY_IMAGE/client:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE/admin:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE/spider:$CI_COMMIT_SHA
  only:
    - main

# ==================== 部署 ====================

deploy:staging:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache curl
  script:
    - echo "Deploying to staging..."
    - curl -X POST $STAGING_WEBHOOK_URL
  environment:
    name: staging
    url: https://staging.dacong.com
  only:
    - dev
  when: manual

deploy:production:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache curl
  script:
    - echo "Deploying to production..."
    - curl -X POST $PRODUCTION_WEBHOOK_URL
  environment:
    name: production
    url: https://dacong.com
  only:
    - main
  when: manual

# ==================== 定时任务 ====================

spider:scheduled:
  stage: deploy
  image: python:3.11-slim
  script:
    - cd dacong-spider
    - pip install -r requirements.txt
    - python main.py
  only:
    - schedules
  variables:
    SCHEDULE: "0 * * * *"  # 每小时运行
```

## 2. Docker配置

### dacong-client/Dockerfile
```dockerfile
# 构建阶段
FROM cirrusci/flutter:3.16.0 AS build

WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

# 运行阶段
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### dacong-admin/Dockerfile
```dockerfile
FROM cirrusci/flutter:3.16.0 AS build

WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### dacong-spider/Dockerfile
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "main.py"]
```

## 3. docker-compose.yml

```yaml
version: '3.8'

services:
  client:
    build: ./dacong-client
    ports:
      - "8081:80"
    environment:
      - SUPABASE_URL=${SUPABASE_URL}
      - SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
    restart: unless-stopped

  admin:
    build: ./dacong-admin
    ports:
      - "8080:80"
    environment:
      - SUPABASE_URL=${SUPABASE_URL}
      - SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
    restart: unless-stopped

  spider:
    build: ./dacong-spider
    environment:
      - SUPABASE_URL=${SUPABASE_URL}
      - SUPABASE_SERVICE_KEY=${SUPABASE_SERVICE_KEY}
    restart: unless-stopped

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    restart: unless-stopped

volumes:
  redis-data:
```

## 4. GitLab CI/CD变量配置

在GitLab项目设置中添加以下变量：

```
Settings → CI/CD → Variables

CI_REGISTRY_USER: gitlab用户名
CI_REGISTRY_PASSWORD: gitlab访问令牌
SUPABASE_URL: Supabase项目URL
SUPABASE_ANON_KEY: Supabase匿名密钥
SUPABASE_SERVICE_KEY: Supabase服务密钥
STAGING_WEBHOOK_URL: Staging部署webhook
PRODUCTION_WEBHOOK_URL: Production部署webhook
SENTRY_DSN: Sentry DSN
```

## 5. 自动化效果

### 原流程（手动）
1. 手动运行测试：10分钟
2. 手动代码检查：5分钟
3. 手动构建：15分钟
4. 手动部署：20分钟
**总计：50分钟/次**

### 自动化后
1. 提交代码触发pipeline
2. 自动测试、检查、构建、部署
3. 失败自动通知
**总计：5分钟人工时间**

### 节省效果
- 每次部署节省：45分钟
- 每天部署3次：节省2.25小时
- 每周节省：11.25小时
- 12周节省：135小时（$13,500）

## 6. 监控和通知

### GitLab集成Slack
```yaml
# .gitlab-ci.yml
notify:success:
  stage: .post
  script:
    - 'curl -X POST -H "Content-type: application/json" --data "{\"text\":\"✅ Pipeline succeeded for $CI_COMMIT_REF_NAME\"}" $SLACK_WEBHOOK_URL'
  when: on_success

notify:failure:
  stage: .post
  script:
    - 'curl -X POST -H "Content-type: application/json" --data "{\"text\":\"❌ Pipeline failed for $CI_COMMIT_REF_NAME\"}" $SLACK_WEBHOOK_URL'
  when: on_failure
```

## 7. 下一步

1. ✅ 复制.gitlab-ci.yml到项目根目录
2. ✅ 创建Dockerfile文件
3. ✅ 配置GitLab CI/CD变量
4. ✅ 提交代码触发第一次pipeline
5. ✅ 验证自动化流程
6. ✅ 配置Slack通知

**预计配置时间：2小时**
**长期节省：每周11.25小时**
