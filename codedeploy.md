# codedeploy

CodeDeploy를 활용한 AWS EC2 자동 배포 구성입니다.
Jenkins 파이프라인에서 S3에 배포 번들을 업로드하면
CodeDeploy가 ASG 인스턴스에 배포를 수행합니다.

---

## 배포 흐름

```
Jenkins 파이프라인
→ Maven Build → Docker Build → Docker Hub Push → 로컬 이미지 삭제
→ 배포 번들 생성 (appspec.yml + scripts/)
→ S3 업로드
→ CodeDeploy 배포 트리거
→ EC2: ApplicationStop → ApplicationStart
```

---

## 파일별 설명

### appspec.yml

CodeDeploy 배포 명세 파일입니다.

```yaml
files:
  - source: /
    destination: /home/ubuntu
    overwrite: yes

hooks:
  ApplicationStop:
    - location: scripts/kill_process.sh
      timeout: 100
      runas: ubuntu
  ApplicationStart:
    - location: scripts/run_process.sh
      timeout: 300
      runas: ubuntu
```

**배포 순서**
1. S3에서 번들을 다운로드해 `/home/ubuntu`에 복사
2. `ApplicationStop`: 기존 컨테이너 종료 + 이미지 삭제
3. `ApplicationStart`: 새 이미지로 컨테이너 실행

**overwrite: yes + files_exists_behavior: OVERWRITE**
재배포 시 기존 파일을 덮어씁니다.
두 옵션을 함께 설정한 이유는 버전에 따라 적용되는 옵션이 다를 수 있어 안전하게 둘 다 명시했습니다.

---

### scripts/kill_process.sh

```bash
docker-compose down || true
docker rmi -f hklee2748/aws-spring-petclinic:latest || true
```

컨테이너를 종료하고 기존 이미지를 강제 삭제합니다.
이미지를 삭제하는 이유는 `latest` 태그 특성상 명시적으로 삭제하지 않으면
`run_process.sh`에서 새 이미지를 pull하지 않고 캐시를 사용할 수 있기 때문입니다.

`|| true`로 컨테이너/이미지가 없어도 오류 없이 넘어갑니다.

---

### scripts/run_process.sh

```bash
cd /home/ubuntu/scripts
docker-compose up -d
```

`docker-compose.yml` 기준으로 컨테이너를 실행합니다.

---

### scripts/docker-compose.yml

```yaml
services:
  spring-petclinic:
    image: hklee2748/aws-spring-petclinic
    container_name: spring_petclinic
    ports:
      - "80:8080"
```

포트 매핑 `80:8080` — ALB Health Check와 외부 트래픽을 80으로 수신합니다.
`imagePullPolicy`가 없어 `docker-compose up -d` 실행 시 항상 최신 이미지를 pull합니다.

---

## Jenkinsfile 주요 포인트

### K8s 파이프라인과의 차이

| 항목 | K8s 파이프라인 | AWS 파이프라인 |
|------|--------------|--------------|
| 배포 방식 | kubectl rolling update | CodeDeploy |
| 이미지 태그 | BUILD_NUMBER만 | latest + BUILD_NUMBER 둘 다 |
| 배포 트리거 | kubectl set image | S3 → CodeDeploy |
| 로컬 이미지 정리 | 없음 | 빌드 후 강제 삭제 |

### latest + BUILD_NUMBER 동시 Push

```bash
docker tag spring-petclinic:$BUILD_NUMBER $DOCKERHUB_USER/aws-spring-petclinic:latest
docker tag spring-petclinic:$BUILD_NUMBER $DOCKERHUB_USER/aws-spring-petclinic:$BUILD_NUMBER
```

`latest`는 CodeDeploy 배포 시 EC2에서 항상 최신 이미지를 pull하기 위해,
`BUILD_NUMBER`는 버전 추적 및 롤백을 위해 함께 push합니다.

### 로컬 이미지 삭제 (STAGE.5)

```bash
docker rmi -f spring-petclinic:$BUILD_NUMBER
docker rmi -f $DOCKERHUB_USER/aws-spring-petclinic:latest
docker rmi -f $DOCKERHUB_USER/aws-spring-petclinic:$BUILD_NUMBER
```

Jenkins 서버(EC2) 디스크 용량 관리를 위해 빌드 후 로컬 이미지를 삭제합니다.
K8s 파이프라인에는 없는 단계로, EC2 환경 특성상 디스크 관리가 필요합니다.

### post { always }

```bash
post {
  always {
    sh 'rm -f scripts.zip || true'
  }
}
```

파이프라인 성공/실패 여부와 관계없이 임시 zip 파일을 정리합니다.

---

## 수동 구성 항목

아래 항목은 Ansible 모듈 미지원으로 콘솔에서 직접 구성했습니다.

| 항목 | 설명 |
|------|------|
| S3 버킷 (`user03-codedeploy-bucket`) | 배포 번들 저장소 |
| CodeDeploy 애플리케이션 (`user03-code-deploy`) | 배포 애플리케이션 |
| CodeDeploy 배포 그룹 (`user03-app-code-deploy`) | ASG 연동 배포 그룹 |
