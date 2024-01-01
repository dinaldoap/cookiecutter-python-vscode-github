CONFIG_SRC=$(shell prettier . --list-different)
PACKAGE_SRC=$(shell find cookiecutter_python_vscode_github -type f -name '*.py' -not -name 'version.py')
TESTS_SRC=$(shell find tests -type f -name '*.py')
TESTS_DATA=$(shell find tests -type f -name '*.xlsx' -o -name '*.ini')
SHELL_SRC=$(shell find . -type f -name '*.sh' -not -path '*/.venv/*')

## main        : Run all necessary rules to build the Python package (from "clean" to "smoke"). It is designed to be executed whithin a virtual environment created by "venv" rule.
main: clean install lock sync format secure lint test package smoke
.PHONY: main

## clean       : Delete caches and files generated during the build.
.cache/make/clean: Makefile
	rm -rf .cache/make cookiecutter-python-vscode-github.egg-info .pytest_cache tests/.pytest_cache dist
	mkdir --parents .cache/make
	@date > $@
.PHONY: clean
clean: .cache/make/clean

## install     : Install most recent versions of the development dependencies.
.cache/make/install: .cache/make/clean requirements-dev-editable.txt pyproject.toml requirements-dev.txt constraints.txt
	pip install --quiet --requirement=requirements-dev.txt
	pip install --quiet --requirement=requirements-dev-editable.txt
	@date > $@
.PHONY: install
install: .cache/make/install

## lock        : Lock development and production dependencies.
requirements-dev.lock: .cache/make/install requirements-dev.txt constraints.txt pyproject.toml requirements-prod.txt
	pip-compile --quiet --resolver=backtracking --generate-hashes --strip-extras --allow-unsafe --output-file=requirements-dev.lock --no-header --no-annotate requirements-dev.txt pyproject.toml
requirements-prod.lock: pyproject.toml requirements-prod.txt requirements-dev-constraints.txt requirements-dev.lock
	pip-compile --quiet --resolver=backtracking --generate-hashes --strip-extras --allow-unsafe --output-file=requirements-prod.lock --no-header --no-annotate pyproject.toml requirements-dev-constraints.txt
.PHONY: lock
lock: requirements-dev.lock requirements-prod.lock

## unlock      : Unlock development and production dependencies.
.PHONY: unlock
unlock:
	rm -rf requirements-*.lock

## sync        : Syncronize development dependencies in the environment according to requirements-dev.lock.
.cache/make/sync: requirements-dev-editable.txt pyproject.toml requirements-dev.lock
	pip-sync --quiet requirements-dev.lock
	pip install --quiet --requirement=requirements-dev-editable.txt
	@date > $@
.PHONY: sync
sync: .cache/make/sync

## format      : Format source code.
# If docformatter fails, the script ignores exit status 3, because that code is returned when docformatter changes any file.
# If the variable CONFIG_SRC is not empty, prettier is executed. Ignore errors because prettier is not available in GitHub Actions.
.cache/make/format: .cache/make/sync ${CONFIG_SRC} ${PACKAGE_SRC} ${TESTS_SRC}
	pyupgrade --py311-plus --exit-zero-even-if-changed ${PACKAGE_SRC} ${TESTS_SRC}
	isort --profile black cookiecutter_python_vscode_github tests
	black cookiecutter_python_vscode_github tests
	docformatter --in-place --recursive cookiecutter_python_vscode_github tests || [ "$$?" -eq "3" ]
	-[ -z "${CONFIG_SRC}" ] || prettier ${CONFIG_SRC} --write
	@date > $@
.PHONY: format
format: .cache/make/format

## secure      : Run vulnerability scanners on source code and production dependencies.
.cache/make/pip-audit: .cache/make/sync requirements-prod.lock
	pip-audit --cache-dir=${HOME}/.cache/pip-audit --requirement=requirements-prod.lock
	@date > $@
.cache/make/bandit: .cache/make/format ${PACKAGE_SRC}
	bandit --recursive cookiecutter_python_vscode_github
	@date > $@
.PHONY: secure
secure: .cache/make/pip-audit .cache/make/bandit

## lint        : Run static code analysers on source code.
.cache/make/lint: .cache/make/format ${PACKAGE_SRC} ${TESTS_SRC} .pylintrc mypy.ini
	pylint cookiecutter_python_vscode_github
	mypy cookiecutter_python_vscode_github tests
	shellcheck ${SHELL_SRC}
	@date > $@
.PHONY: lint
lint: .cache/make/lint

## test        : Run automated tests.
.cache/make/test: .cache/make/format ${PACKAGE_SRC} ${TESTS_SRC} ${TESTS_DATA}
	pytest --cov=cookiecutter_python_vscode_github --cov-report=term-missing tests
	@date > $@
.PHONY: test
test: .cache/make/test
	
## package     : Create wheel.
.cache/make/package: .cache/make/format ${PACKAGE_SRC} pyproject.toml
	rm -rf dist/
	python -m build
	@date > $@
.PHONY: package
package: .cache/make/package

## smoke       : Smoke test wheel.
.cache/make/smoke: .cache/make/package
	pip install --quiet dist/*.whl
	cookiecutter-python-vscode-github --help
	cookiecutter-python-vscode-github --version
	pip install --quiet --requirement=requirements-dev-editable.txt
	@date > $@
.PHONY: smoke
smoke: .cache/make/smoke

## venv        : Create virtual environemnt, install dependencies and pre-commit hooks.
.PHONY: venv
venv:
	bash make/venv.sh

## bash        : Setup .bashrc and .bash_aliases.
.PHONY: bash
bash:
	bash .devcontainer/bash.sh

## devcontainer: Stop devcontainer and remove vscode-server cache.
.PHONY: devcontainer
devcontainer:
	bash .devcontainer/devcontainer.sh

## testpypi    : Upload Python package to https://test.pypi.org/.
.PHONY: testpypi
testpypi:
	twine upload --repository testpypi dist/*.whl

## cookie      : Update project using cookiecutter-python-vscode-github template.
.PHONY: cookie
cookie:
	cookiecutter --overwrite-if-exists --output-dir=.. --no-input --config-file=cookiecutter.yaml $$(cookiecutter-python-vscode-github)

## help        : Show this help message.
.PHONY: help
help:
	@sed -n 's/^##//p' Makefile
