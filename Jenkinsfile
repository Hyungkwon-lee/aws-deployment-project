pipeline {
  agent any

  tools {
    maven 'MVN3'
    jdk 'JDK21'
  }

  environment {
    REGION = 'ap-northeast-2'
    DOCKERHUB_USER = 'hklee2748' 
    DOCKERHUB_CREDENTIALS = credentials('Docker-Creds')
  }

  stages {
    stage('1. Git clone') {
      steps {
        git url: 'https://github.com/kwony93/spring-petclinic.git/', branch: 'main'
      }
    }

    stage('2. Maven Build') {
      steps {
        sh 'mvn -Dmaven.test.failure.ignore=true clean package'
      }
    }

    stage('3. Docker Image Build') {
      steps {
        sh '''
          docker build -t spring-petclinic:$BUILD_NUMBER .
          docker tag spring-petclinic:$BUILD_NUMBER $DOCKERHUB_USER/aws-spring-petclinic:latest
          docker tag spring-petclinic:$BUILD_NUMBER $DOCKERHUB_USER/aws-spring-petclinic:$BUILD_NUMBER
        '''
      }
    }

    stage('4. Docker Image Upload') {
      steps {
        sh '''
          echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
          docker push $DOCKERHUB_USER/aws-spring-petclinic:latest
          docker push $DOCKERHUB_USER/aws-spring-petclinic:$BUILD_NUMBER
        '''
      }
    }

    stage('5. Docker Image Remove') {
      steps {
        sh '''
          docker rmi -f spring-petclinic:$BUILD_NUMBER
          docker rmi -f $DOCKERHUB_USER/aws-spring-petclinic:latest
          docker rmi -f $DOCKERHUB_USER/aws-spring-petclinic:$BUILD_NUMBER
        '''
      }
    }

    stage('6. Create Deployment Bundle') {
      steps {
        sh '''
          rm -f scripts.zip
          zip -r scripts.zip scripts appspec.yml
        '''
      }
    }

    stage('7. Upload to S3') {
      steps {
        sh "aws s3 cp scripts.zip s3://user03-codedeploy-bucket/scripts.zip --region $REGION"
      }
    }
    
    stage('8. CodeDeploy') {
      steps {
        sh """
        aws deploy create-deployment \
          --application-name user03-code-deploy \
          --deployment-group-name user03-app-code-deploy \
          --deployment-config-name CodeDeployDefault.OneAtATime \
          --s3-location bucket=user03-codedeploy-bucket,bundleType=zip,key=scripts.zip \
          --region $REGION
        """
      }
    }
  }

  post {
    always {
      sh 'rm -f scripts.zip || true'
    }
  }
}
