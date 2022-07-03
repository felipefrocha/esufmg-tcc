.SHELL:=/bin/bash

teste := $(shell date +%D%T | sed -e "s/[:\/]//g")

local:
	@docker build -t felipefrocha89/esufmg:tcc-airflow-${teste} container/dags/
	@echo "AIRFLOW_IMAGE_NAME=felipefrocha89/esufmg:tcc-airflow-${teste}" > container/airflow_local/.env
	@echo "AIRFLOW_UID=$$(id -u)" >> container/airflow_local/.env
	@docker-compose -f container/airflow_local/docker-compose.yaml up -d 
	@sudo cp container/dags/*.py container/airflow_local/dags/
	@docker-compose -f container/airflow_local/docker-compose.yaml logs -f

clear_local:
	@docker-compose -f container/airflow_local/docker-compose.yaml down -v
	@cd container/airflow_local && sudo rm -rf logs dags tmp plugins

deploy_dag: 
	@echo ${teste}
	@git add .
	@git commit -am "chore(docker): Create a new deployment with tag ${teste}" || git commit --amend -am "chore(docker): Create a new deployment with tag ${teste}"
	@docker build -t felipefrocha89/esufmg:tcc-airflow-${teste} container/dags/
	@echo "${PASSWD}" | docker login -u felipefrocha89 --password-stdin
	@docker push felipefrocha89/esufmg:tcc-airflow-${teste} 
	@cd cluster && make k8s tag=tcc-airflow-${teste}

docs:
	@(cd docs/apresentacao && make) & (cd docs/monografia && make) & wait

