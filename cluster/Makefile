
# Root directory of the project (absolute path).
ROOTDIR=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
# Base path used to install.
DESTDIR ?= /usr/local
# Emojis
WHALE = "🇩"
ONI = "👹"
PHONY=help

all: clear docker_lb vagrant

setup: ## Install all requirements for your system
	@echo Installing packages
	@sudo apt-get update && \
		sudo apt-get install -y \
			wget \
			curl \
			python3 \
			python3-pip
	@pip3 install -U pip ansible molecule


clear: ## Removes all roles and VM's installed
	@rm -rf ./roles/*

cms: ## Configure bastion host
	@cd ansible \
		&& ansible-playbook -i hosts main.yml

ansible_roles: ## Install all required roles
	@cd ansible \
		&& ansible-galaxy install --roles-path ./roles -r requirements.yml 

help: ## this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort
