# aws-deployment-project

Jenkins + Docker Hub + CodeDeploy 기반 AWS EC2 자동 배포 파이프라인 구성입니다.  
→ 프로젝트 전체 개요는 [infra-portfolio](https://github.com/Hyungkwon-lee/infra-portfloio.git) 참고  
→ AWS 인프라 구성은 [ansible-iac-project](https://github.com/Hyungkwon-lee/ansible-iac-project) 참고

---

## 배포 흐름

GitHub (main) → Maven Build → Docker Build
→ Docker Hub Push → S3 업로드 → CodeDeploy → EC2 배포

---

## 디렉토리 구조 및 문서

| 경로 | 설명 | 문서 |
|------|------|------|
| `appspec.yml` | CodeDeploy 배포 명세 | [codedeploy.md](./codedeploy.md) |
| `scripts/` | 배포 훅 스크립트 | [codedeploy.md](./codedeploy.md) |
| `Jenkinsfile` | CI/CD 파이프라인 | [codedeploy.md](./codedeploy.md) |

---

## 담당 작업

- Jenkinsfile 작성 (8단계 CI/CD 파이프라인)
- appspec.yml 작성 (CodeDeploy 배포 훅 구성)
- 배포 스크립트 작성 (kill_process.sh, run_process.sh)
- Docker Compose 기반 컨테이너 실행 구성

---

## 기술 스택

`Jenkins` `Docker` `Docker Hub` `AWS CodeDeploy` `S3` `Maven` `Spring-PetClinic`
