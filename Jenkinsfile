pipeline {
  agent {
    node {
      label 'k8s'
    }

  }
  stages {
    stage('create_seed_domain') {
      steps {
        echo 'step 1 - create a secret containing the WLS admin credentials, create the base domain definition & image, create the ingress for the domain'
        sh '''
		      git clone -b develop-examples-poc https://github.com/oracle/weblogic-kubernetes-operator.git
		   '''
        dir(path: 'weblogic-kubernetes-operator/kubernetes/examples') {
          sh 'kubectl create secret generic -n sample-domain1-ns domain1-uid-weblogic-credentials --from-literal=username=weblogic --from-literal=password=welcome1'
          sh 'kubectl label secret -n sample-domain1-ns domain1-uid-weblogic-credentials weblogic.domainUID=domain1-uid weblogic.domainName=domain1'
          sh 'rm -rf domain1-def'
          sh 'pwd'
          sh 'cp -rf cicd/domain-definitions/base domain1-def'
          sh 'cp cicd/domain-home-creators/base/Dockerfile1 domain1-def/Dockerfile'
          sh 'wget https://github.com/oracle/weblogic-deploy-tooling/releases/download/weblogic-deploy-tooling-0.24/weblogic-deploy.zip'
          sh 'cp weblogic-deploy.zip domain1-def'
          sh '''
          	  ENCODED_ADMIN_USERNAME=`kubectl get secret -n sample-domain1-ns domain1-uid-weblogic-credentials -o jsonpath=\'{.data.username}\'`
              ENCODED_ADMIN_PASSWORD=`kubectl get secret -n sample-domain1-ns domain1-uid-weblogic-credentials -o jsonpath=\'{.data.password}\'`
              docker build --build-arg ENCODED_ADMIN_USERNAME=${ENCODED_ADMIN_USERNAME} --build-arg ENCODED_ADMIN_PASSWORD=${ENCODED_ADMIN_PASSWORD} --force-rm=true -t domain1:base domain1-def
            '''
          sh 'docker run --detach --name domain1-base domain1:base'
          sleep 60
          sh 'docker cp domain1-base:/u01/domain1.zip .'
          sh 'docker rm -f domain1-base'
          sh 'docker rmi domain1:base'
          sh 'cp load-balancers/domain-traefik.yaml domain1-lb.yaml'
          sh 'kubectl apply -f domain1-lb.yaml'
        }

      }
    }
    stage('create_v1_image_and_test') {
      steps {
        echo 'step 2 - create the v1 domain definition & image, create the domain resource and wait for the servers to start'
        echo 'note: v1 has testwebapp1-v1 (initial app)'
        dir(path: 'weblogic-kubernetes-operator/kubernetes/examples') {
          sh 'rm -r domain1-def'
          sh 'cp -r cicd/domain-definitions/v1 domain1-def'
          sh 'cp cicd/domain-home-creators/derived/Dockerfile1 domain1-def/Dockerfile'
          sh 'cp weblogic-deploy.zip domain1-def'
          sh 'cp domain1.zip domain1-def'
          sh 'docker build --force-rm=true -t $IMAGE1_NAME:v1 --no-cache --force-rm domain1-def'
        }

        withCredentials(bindings: [[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub',usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD']]) {
          sh 'docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD'
          sh 'docker push $IMAGE1_NAME:v1'
          sleep 30
        }

        sh 'helm install $WORKSPACE/charts/domain1 --name domain1 --namespace sample-domain1-ns --set Version=v1,ImageName=$IMAGE1_NAME'
        sleep 60
        sh '$WORKSPACE/waitAndCheckAllPodStart.sh'
        sh 'curl -H \'host: domain1.org\' http://${HOSTNAME}.us.oracle.com:30305/testwebapp1/'
      }
    }
    stage('create_v2_image_and_test') {
      steps {
        echo 'step 3 - create the v2 domain definition & image, create the domain resource and wait for the servers to roll'
        echo 'note: v2 has testwebapp1-v2 (new version of of the first app)'
        dir(path: 'weblogic-kubernetes-operator/kubernetes/examples') {
          sh 'rm -rf domain1-def'
          sh 'cp -r cicd/domain-definitions/v2 domain1-def'
          sh 'cp cicd/domain-home-creators/derived/Dockerfile1 domain1-def/Dockerfile'
          sh 'cp weblogic-deploy.zip domain1-def'
          sh 'cp domain1.zip domain1-def'
          sh 'docker build --force-rm=true -t $IMAGE1_NAME:v2 --no-cache --force-rm domain1-def'
        }

        withCredentials(bindings: [[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub',usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD']]) {
          sh 'docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD'
          sh 'docker push $IMAGE1_NAME:v2'
          sleep 30
        }

        sh 'helm upgrade domain1 $WORKSPACE/charts/domain1 --reuse-values --set Version=v2,ImageName=$IMAGE1_NAME'
        sleep 60
        sh '$WORKSPACE/waitAndCheckAllPodStart.sh'
        sh 'curl -H \'host: domain1.org\' http://${HOSTNAME}.us.oracle.com:30305/testwebapp1/'
      }
    }
    stage('create_v3_image_and_test') {
      steps {
        echo 'step 4 - create the v3 domain definition & image, create the domain resource and wait for the servers to roll'
        echo 'note: v3 has testwebapp1-v2 & testwabapp2-v1 (same version of the first app, adds the first version of the second app)'
        dir(path: 'weblogic-kubernetes-operator/kubernetes/examples') {
          sh 'rm -rf domain1-def'
          sh 'cp -r cicd/domain-definitions/v3 domain1-def'
          sh 'cp cicd/domain-home-creators/derived/Dockerfile1 domain1-def/Dockerfile'
          sh 'cp weblogic-deploy.zip domain1-def'
          sh 'cp domain1.zip domain1-def'
          sh 'docker build --force-rm=true -t $IMAGE1_NAME:v3 --no-cache --force-rm domain1-def'
        }

        withCredentials(bindings: [[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub',usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD']]) {
          sh 'docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD'
          sh 'docker push $IMAGE1_NAME:v3'
          sleep 30
        }

        sh 'helm upgrade domain1 $WORKSPACE/charts/domain1 --reuse-values --set Version=v3,ImageName=$IMAGE1_NAME'
        sleep 60
        sh '$WORKSPACE/waitAndCheckAllPodStart.sh'
        sh 'curl -H \'host: domain1.org\' http://${HOSTNAME}.us.oracle.com:30305/testwebapp1/'
        sh 'curl -H \'host: domain1.org\' http://${HOSTNAME}.us.oracle.com:30305/testwebapp2/'
      }
    }
    stage('create_v4_image_and_test') {
      steps {
        echo 'step 5 - create the v4 domain definition & image, create the domain resource and wait for the servers to roll'
        echo 'note: v4 only testwebapp2-v2 (removes the first app, new version of the second app)'
        dir(path: 'weblogic-kubernetes-operator/kubernetes/examples') {
          sh 'rm -rf domain1-def'
          sh 'cp -r cicd/domain-definitions/v4 domain1-def'
          sh 'cp cicd/domain-home-creators/derived/Dockerfile1 domain1-def/Dockerfile'
          sh 'cp weblogic-deploy.zip domain1-def'
          sh 'cp domain1.zip domain1-def'
          sh 'docker build --force-rm=true -t $IMAGE1_NAME:v4 --no-cache --force-rm domain1-def'
        }

        withCredentials(bindings: [[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub',usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD']]) {
          sh 'docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD'
          sh 'docker push $IMAGE1_NAME:v4'
          sleep 30
        }

        sh 'helm upgrade domain1 $WORKSPACE/charts/domain1 --reuse-values --set Version=v4,ImageName=$IMAGE1_NAME'
        sleep 60
        sh '$WORKSPACE/waitAndCheckAllPodStart.sh'
        sh 'curl -H \'host: domain1.org\' http://${HOSTNAME}.us.oracle.com:30305/testwebapp1/'
        sh 'curl -H \'host: domain1.org\' http://${HOSTNAME}.us.oracle.com:30305/testwebapp2/'
      }
    }
    stage('tear_down') {
      steps {
        echo 'step 6 - teardown'
        dir(path: 'weblogic-kubernetes-operator/kubernetes/examples') {
          sh 'kubectl delete -f domain1-lb.yaml'
          sh 'helm delete --purge domain1'
          sleep 60
          sh '$WORKSPACE/waitAndCheckAllPodStop.sh'
          sh 'docker rmi $IMAGE1_NAME:v4'
          sh 'docker rmi $IMAGE1_NAME:v3'
          sh 'docker rmi $IMAGE1_NAME:v2'
          sh 'docker rmi $IMAGE1_NAME:v1'
          sh 'kubectl delete secret -n sample-domain1-ns domain1-uid-weblogic-credentials'
          sh 'rm domain1-lb.yaml'
          sh 'rm -rf domain1-def'
          sh 'rm domain1.zip'
        }

      }
    }
  }
  environment {
    IMAGE1_NAME = 'changharry126com/domain1'
    http_proxy = 'http://www-proxy-hqdc.us.oracle.com:80'
    https_proxy = 'http://www-proxy-hqdc.us.oracle.com:80'
    no_proxy = 'localhost,127.0.0.1,.us.oracle.com,.oraclecorp.com,/var/run/docker.sock,10.241.99.189,10.241.99.190'
  }
  post {
    success {
      echo 'Congratulations! Succeeded!'
	  cleanWs(cleanWhenAborted: true, cleanWhenFailure: true, cleanWhenNotBuilt: true, cleanWhenSuccess: true, cleanWhenUnstable: true, deleteDirs: true, cleanupMatrixParent: true)
    }

    failure {
      echo 'Sorry! failed :('

    }

  }
}