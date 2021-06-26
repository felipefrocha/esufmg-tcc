.SHELL:=/bin/bash

teste := $(shell date +%D%T | sed -e "s/[:\/]//g")

deploy_dag: 
	@echo ${teste}
	@git add .
	@git commit -am "chore(docker): Create a new deployment with tag ${teste}"
	@docker build -t felipefrocha89/esufmg:tcc-airflow-${teste} container/dags/
	@echo "${PASSWD}" | docker login -u felipefrocha89 --password-stdin
	@docker push felipefrocha89/esufmg:tcc-airflow-${teste} 
	@cd cluster && make k8s tag=tcc-airflow-${teste}

docs:
	@(cd docs/apresentacao && make) & (cd docs/monografia && make) & wait

