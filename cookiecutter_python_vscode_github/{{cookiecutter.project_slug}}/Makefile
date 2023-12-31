PRETTIER_DIFF=$(shell prettier . --list-different)
PACKAGE_SRC=$(shell git ls-files '{{cookiecutter.project_slug_underscore}}/*.py')
PACKAGE_DATA=$(shell git ls-files -z '{{cookiecutter.project_slug_underscore}}' | tr '\0' '\n' | grep --invert-match '\.py$$')
TESTS_SRC=$(shell git ls-files 'tests/*.py')
TESTS_DATA=$(shell git ls-files -z 'tests' | tr '\0' '\n' | grep --invert-match '\.py$$')
SHELL_SRC=$(shell git ls-files '*.sh')

## main        : Run all necessary rules to build the Python package (from "clean" to "smoke"). It is designed to be executed whithin a virtual environment created by "venv" rule.
main: clean install lock sync format secure lint test package smoke
.PHONY: main

## clean       : Delete caches and files generated during the build.
.cache/make/clean: Makefile
	rm -rf .cache/make {{cookiecutter.project_slug}}.egg-info .pytest_cache tests/.pytest_cache dist
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
# If the variable PRETTIER_DIFF is not empty, prettier is executed. Ignore errors because prettier is not available in GitHub Actions.
.cache/make/format: .cache/make/sync ${PRETTIER_DIFF} ${PACKAGE_SRC} ${TESTS_SRC}
	pyupgrade --py311-plus --exit-zero-even-if-changed ${PACKAGE_SRC} ${TESTS_SRC}
	isort --profile black {{cookiecutter.project_slug_underscore}} tests
	black {{cookiecutter.project_slug_underscore}} tests
	docformatter --in-place --recursive {{cookiecutter.project_slug_underscore}} tests || [ "$$?" -eq "3" ]
	-[ -z "${PRETTIER_DIFF}" ] || prettier ${PRETTIER_DIFF} --write
	@date > $@
.PHONY: format
format: .cache/make/format

## secure      : Run vulnerability scanners on source code and production dependencies.
.cache/make/pip-audit: .cache/make/sync requirements-prod.lock
	pip-audit --cache-dir=${HOME}/.cache/pip-audit --requirement=requirements-prod.lock
	@date > $@
.cache/make/bandit: .cache/make/format ${PACKAGE_SRC}
	bandit --recursive {{cookiecutter.project_slug_underscore}}
	@date > $@
.PHONY: secure
secure: .cache/make/pip-audit .cache/make/bandit

## lint        : Run static code analysers on source code.
.cache/make/lint: .cache/make/format ${PACKAGE_SRC} ${TESTS_SRC} ${SHELL_SRC} .pylintrc mypy.ini .shellcheckrc
	pylint {{cookiecutter.project_slug_underscore}}
	mypy {{cookiecutter.project_slug_underscore}} tests
	shellcheck ${SHELL_SRC}
	@date > $@
.PHONY: lint
lint: .cache/make/lint

## test        : Run automated tests.
.cache/make/test: .cache/make/format ${PACKAGE_SRC} ${PACKAGE_DATA} ${TESTS_SRC} ${TESTS_DATA}
	pytest --cov={{cookiecutter.project_slug_underscore}} --cov-report=term-missing tests
	@date > $@
.PHONY: test
test: .cache/make/test
	
## package     : Create wheel.
.cache/make/package: .cache/make/format ${PACKAGE_SRC} ${PACKAGE_DATA} pyproject.toml
	rm -rf dist/
	python -m build
	@date > $@
.PHONY: package
package: .cache/make/package

## smoke       : Smoke test wheel.
.cache/make/smoke: .cache/make/package
	pip install --quiet dist/*.whl
	{{cookiecutter.project_slug}} --help
	{{cookiecutter.project_slug}} --version
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
