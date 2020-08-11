#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PROJECT_NAME = stargan-v2
PYTHON_INTERPRETER = python3
OS_NAME := $(shell uname -s | tr A-Z a-z)

ifeq (,$(shell which conda))
HAS_CONDA=False
else
HAS_CONDA=True
endif
CONDA_ACTIVATE=source $$(conda info --base)/etc/profile.d/conda.sh ; conda activate ; conda activate

#################################################################################
# COMMANDS                                                                      #
#################################################################################

.PHONY: lint
## Delete all compiled Python files
clean:
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -delete

.PHONY: lint
## Lint using pre-commit hooks (see .pre-commit-config.yaml)
lint:
	tox -e lint

.PHONY: provision_environment
## Set up python interpreter environment
provision_environment:
ifeq (True,$(HAS_CONDA))
	@echo ">>> Detected conda, creating conda environment."
	conda create -y --name $(PROJECT_NAME) python=3.6.7
ifneq ($(OS_NAME),darwin)
	($(CONDA_ACTIVATE) $(PROJECT_NAME); \
		conda install -y cudatoolkit=10.0 -c pytorch;)
endif
	($(CONDA_ACTIVATE) $(PROJECT_NAME); \
		conda install -y pytorch=1.4.0 torchvision=0.5.0 -c pytorch; \
		conda install -y x264=='1!152.20180717' ffmpeg=4.0.2 -c conda-forge; \
		pip install -r requirements.txt)
	@echo ">>> New conda env created. Activate with:"
ifeq ($(OS_NAME),Windows_NT)
	@echo "source activate $(PROJECT_NAME)"
else
	@echo "conda activate $(PROJECT_NAME)"
endif
else
	@echo ">>> Error: please install conda before running this target"
endif

#################################################################################
# PROJECT RULES                                                                 #
#################################################################################



#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
.PHONY: help
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
