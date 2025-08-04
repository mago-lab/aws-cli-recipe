# MAGO AWS CLI Recipe

AWS 클라우드 인프라 관리를 위한 MAGO의 CLI 도구 모음입니다. 이 프로젝트는 AWS 서비스들을 효율적으로 관리하고 배포하기 위한 스크립트들과 유틸리티를 제공합니다.

## 📋 목차

- [개요](#개요)
- [설치 및 설정](#설치-및-설정)
- [프로젝트 구조](#프로젝트-구조)
- [주요 기능](#주요-기능)
- [사용법](#사용법)
- [배포 가이드](#배포-가이드)
- [유틸리티](#유틸리티)
- [환경 변수](#환경-변수)

## 🎯 개요

이 프로젝트는 AWS 클라우드 인프라를 효율적으로 관리하기 위한 도구 모음입니다. 주요 기능은 다음과 같습니다:

- **VPC 및 네트워크 구성**: VPC, 서브넷, 보안 그룹 생성 및 관리
- **EC2 인스턴스 관리**: 인스턴스 생성, Elastic IP 할당, 연결
- **로드 밸런서 관리**: ALB/NLB 생성 및 설정
- **컨테이너 관리**: ECR 이미지 빌드 및 푸시
- **서비스 배포**: Docker 기반 서비스 배포 자동화
- **데이터 전송**: EC2 인스턴스 간 파일 전송

## 🚀 설치 및 설정

### 1. 사전 요구사항

- Ubuntu/Debian 기반 시스템
- Python 3.8+
- Docker
- AWS CLI v2

### 2. AWS CLI 설치

```bash
# AWS CLI v2 설치
./tools/install_awscliv2.sh

# AWS 자격 증명 설정
aws configure
```

### 3. Docker 설치

```bash
# Docker 설치
./tools/install_docker.sh
```

### 4. Python 가상환경 설정

```bash
# 가상환경 설치 및 의존성 설치
./scripts/install.sh
```

## 📁 프로젝트 구조

```
aws-cli-recipe/
├── cli/                    # AWS CLI 도구들
│   ├── vpc/               # VPC 관리 스크립트
│   ├── ec2/               # EC2 인스턴스 관리
│   ├── elb/               # Elastic Load Balancer 관리
│   ├── tg/                # Target Group 관리
│   ├── config/            # 설정 파일들
│   ├── utils/             # 유틸리티 함수들
│   ├── functions.sh       # 공통 함수들
│   └── create_deault_service.sh  # 기본 서비스 생성
├── deploy/                # 서비스 배포 스크립트
├── ecr/                   # ECR 이미지 관리
├── scripts/               # 설치 및 연결 스크립트
├── tools/                 # 도구 스크립트들
├── transfer/              # 데이터 전송 도구
├── utils/                 # 공통 유틸리티
├── cdk/                   # AWS CDK 코드
├── env.sh                 # 환경 변수
└── requirements.txt       # Python 의존성
```

## 🔧 주요 기능

### 1. VPC 관리 (`cli/vpc/`)

VPC, 서브넷, 보안 그룹을 생성하고 관리합니다.

```bash
# VPC 생성
cd cli/vpc
./create_vpc.sh <vpc_name>

# VPC 정보 조회
./get_vpc_info.sh <vpc_name>
```

**주요 함수들:**
- `get_vpc_id()`: VPC ID 조회
- `get_subnet_id()`: 서브넷 ID 조회
- `get_sg_id()`: 보안 그룹 ID 조회

### 2. EC2 인스턴스 관리 (`cli/ec2/`)

EC2 인스턴스 생성 및 Elastic IP 관리

```bash
# EC2 인스턴스 생성
cd cli/ec2
./create_instance.sh --instance-name <name> <vpc_name>

# Elastic IP 할당
create_eip_with_name <eip_name>
associate_eip <eip> <instance_id>
```

**주요 함수들:**
- `get_instance_id()`: 인스턴스 ID 조회
- `create_eip_with_name()`: Elastic IP 할당
- `associate_eip()`: Elastic IP 연결

### 3. 로드 밸런서 관리 (`cli/elb/`)

Application Load Balancer 생성 및 설정

```bash
# ALB 생성
cd cli/elb
./create_elb.sh --elb-name <name> <vpc_name>

# Route 53 레코드 생성
./create_record.sh --domain-name <domain> --elb-name <name> <vpc_name>
```

**주요 함수들:**
- `get_elb_arn()`: ALB ARN 조회
- `get_listener_arn()`: 리스너 ARN 조회
- `get_listener_protocol_80/443()`: 포트별 프로토콜 조회

### 4. Target Group 관리 (`cli/tg/`)

Target Group 생성 및 타겟 등록

```bash
# Target Group 생성
cd cli/tg
./create_tg.sh \
    --tg-name <name> \
    --instance-name <instance> \
    --elb-name <elb> \
    --domain-name <domain> \
    <vpc_name>
```

**주요 함수들:**
- `get_tg_arn()`: Target Group ARN 조회

### 5. ECR 이미지 관리 (`ecr/`)

Docker 이미지 빌드 및 ECR 푸시

```bash
# 이미지 빌드
cd ecr
./build-image.sh

# 이미지 태그
./tag_image.sh

# 이미지 푸시
./push_image.sh
```

### 6. 서비스 배포 (`deploy/`)

다양한 서비스 배포 스크립트

```bash
# JunctionMed 서비스 배포
./deploy/deploy_junctionmed.sh

# ABM 서비스 배포
./deploy/deploy_abm.sh

# 기타 서비스들...
```

## 📖 사용법

### 1. 기본 서비스 생성

전체 인프라를 한 번에 생성하는 방법:

```bash
cd cli
./create_deault_service.sh <vpc_name>
```

이 명령어는 다음을 자동으로 생성합니다:
- VPC 및 서브넷
- 보안 그룹
- Elastic Load Balancer
- EC2 인스턴스
- Target Group
- Route 53 레코드

### 2. 개별 리소스 생성

#### VPC 생성
```bash
cd cli/vpc
./create_vpc.sh my-vpc
```

#### EC2 인스턴스 생성
```bash
cd cli/ec2
./create_instance.sh --instance-name my-instance my-vpc
```

#### 로드 밸런서 생성
```bash
cd cli/elb
./create_elb.sh --elb-name my-elb my-vpc
```

### 3. 서비스 배포

```bash
# JunctionMed 서비스 배포
./deploy/deploy_junctionmed.sh

# 배포 후 확인
ssh -i mago-aws.pem ubuntu@<ec2_ip>
cd mago-services/mago-jm
docker-compose up -d
```

## 🚀 배포 가이드

### 1. 환경 준비

```bash
# 1. AWS CLI 설정
aws configure

# 2. Python 가상환경 설정
./scripts/install.sh

# 3. Docker 설치
./tools/install_docker.sh
```

### 2. 인프라 생성

```bash
# 기본 서비스 환경 생성
cd cli
./create_deault_service.sh my-service-vpc
```

### 3. 서비스 배포

```bash
# 서비스 배포
./deploy/deploy_service.sh

# 또는 특정 서비스 배포
./deploy/deploy_junctionmed.sh
```

### 4. 연결 및 확인

```bash
# EC2 연결
./scripts/connect_ec2.sh

# 서비스 상태 확인
docker ps
docker logs <container_name>
```

## 🛠️ 유틸리티

### 1. 데이터 전송 (`transfer/`)

EC2 인스턴스 간 파일 전송:

```bash
# 파일/폴더 전송
./transfer/tranfer_data.sh --ec2 <ec2_name> <path>
```

사용 가능한 EC2:
- `cv`: cassette_dev_ec2_ip
- `cs`: cassette_stg_ec2_ip
- `jm`: junctionmed_ec2_ip

### 2. 도구 스크립트 (`tools/`)

```bash
# AWS 계정 ID 조회
./tools/account_id.sh

# Docker 이미지 풀
./tools/pull_image.sh <image_name>

# 옵션 파싱 유틸리티
source ./utils/parse_options.sh
```

### 3. 연결 스크립트 (`scripts/`)

```bash
# EC2 연결
./scripts/connect_ec2.sh

# 설치 스크립트
./scripts/install.sh
```

## 🔧 환경 변수

`env.sh` 파일에서 EC2 IP 주소들을 관리합니다:

```bash
export cassette_dev_ec2_ip=13.124.19.99
export cassette_stg_ec2_ip=3.37.73.206
export junctionmed_ec2_ip=43.203.111.178
```

## 📝 주요 함수들

### Certificate Manager

- `get_certificate_arn()`: 도메인명으로 인증서 ARN 조회

### VPC 관리

- `get_vpc_id()`: VPC ID 조회
- `get_subnet_id()`: 서브넷 ID 조회

### 보안 그룹

- `get_sg_id()`: 보안 그룹 ID 조회
- `get_default_sg_id()`: 기본 보안 그룹 ID 조회
- `check_inbound_rule()`: 인바운드 규칙 확인

### 로드 밸런서

- `get_elb_arn()`: ALB ARN 조회
- `get_listener_arn()`: 리스너 ARN 조회
- `get_listener_protocol_80/443()`: 포트별 프로토콜 조회

### EC2 관리

- `get_instance_id()`: 인스턴스 ID 조회

### Elastic IP

- `get_eip_id()`: EIP ID 조회
- `get_eip()`: EIP 주소 조회
- `create_eip_with_name()`: 이름으로 EIP 할당
- `associate_eip()`: EIP 연결

### Target Group

- `get_tg_arn()`: Target Group ARN 조회

## 🔒 보안 고려사항

1. **AWS 자격 증명**: IAM 사용자/역할을 사용하여 최소 권한 원칙 적용
2. **보안 그룹**: 필요한 포트만 열어두기
3. **키 페어**: EC2 접속용 키 페어 안전하게 보관
4. **환경 변수**: 민감한 정보는 환경 변수로 관리

## 🐛 문제 해결

### 일반적인 문제들

1. **AWS CLI 인증 오류**

   ```bash
   aws configure
   ```

2. **Docker 권한 오류**

   ```bash
   sudo usermod -aG docker $USER
   ```

3. **EC2 연결 오류**

   ```bash
   chmod 400 mago-aws.pem
   ssh -i mago-aws.pem ubuntu@<ip>
   ```

## 📞 지원

문제가 발생하거나 추가 도움이 필요한 경우:
- 이슈를 생성하거나
- galois@holamago.com 로 문의

---
