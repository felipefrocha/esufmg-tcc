.SHELL:=/bin/bash

datetime := $(shell date +%D%T | sed -e "s/[:\/]//g")

local:
	@docker build -t felipefrocha89/esufmg:tcc-airflow-${datetime} container/dags/
	@echo "AIRFLOW_IMAGE_NAME=felipefrocha89/esufmg:tcc-airflow-${datetime}" > container/airflow_local/.env
	@echo "AIRFLOW_UID=$$(id -u)" >> container/airflow_local/.env
	@docker-compose -f container/airflow_local/docker-compose.yaml up -d 
	@sudo cp container/dags/*.py container/airflow_local/dags/
	@docker-compose -f container/airflow_local/docker-compose.yaml logs -f

clear_local:
	@docker-compose -f container/airflow_local/docker-compose.yaml down -v
	@cd container/airflow_local && sudo rm -rf logs dags tmp plugins

deploy_k8s_config: 
	@echo ${datetime}
	@git add .
	@git commit -am "chore(docker): Create a new deployment with tag ${datetime}" || git commit --amend -am "chore(docker): Create a new deployment with tag ${datetime}"
	@docker build -t felipefrocha89/esufmg:tcc-airflow-${datetime} container/dags/
	@docker build -t felipefrocha89/esufmg:tcc-jupyter-${datetime} container/jupyter/
	@echo "${PASSWD}" | docker login -u felipefrocha89 --password-stdin
	@docker push felipefrocha89/esufmg:tcc-airflow-${datetime} 
	@docker push felipefrocha89/esufmg:tcc-jupyter-${datetime} 
	@cd cluster && make k8s tag=tcc-airflow-${datetime}
	@cd cluster && make k8s tag=tcc-jupyter-${datetime}

docs:
	@(cd docs/apresentacao && make) & (cd docs/monografia && make) & wait

