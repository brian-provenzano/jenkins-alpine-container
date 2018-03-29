
build:
	@docker build -t warpigg/jenkinsalpine-lts:$(version) .
run:
	@docker run -p 8080:8080 --name=jenkins-alplts-master -d -v jenkins_home:/var/jenkins_home warpigg/jenkinsalpine-lts:$(version)
# @docker run -p 8080:8080 --name=jenkinslts-master -d --env JAVA_OPTS="-Xmx2048m" --env JENKINS_OPTS="" jenkins/jenkins:lts
start:
	@docker container start jenkins-alplts-master
stop:
	@docker container stop jenkins-alplts-master
show:
	@docker container ls
logs: 
	@docker logs jenkins-alplts-master
cli:
	@docker container exec -it -u root jenkins-alplts-master /bin/bash
prune:
	@docker volume prune
clean:	stop
	@docker container rm jenkins-alplts-master
cleanall: clean prune
