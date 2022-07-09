.SHELL:=/bin/bash
.ONESHELL:

datetime := $(shell date +%D%T | sed -e "s/[:\/]//g")

.PHONY: help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)


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
	@cd cluster && make k8s tag=${datetime}


doc_mono:
	@cd docs/monografia && timeout 14 make

doc_apr:
	@cd docs/apresentacao && timeout 14 make

