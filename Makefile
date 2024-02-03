PRETTIER_DIFF=$(shell prettier . --list-different)
GIT_FILES=git ls-files -z | tr '\0' '\n'
GIT_UNTRACKED_FILES=git ls-files -z --exclude-standard --others | tr '\0' '\n'
# If there is no deleted file, "grep --invert-match" is deactivated by the NULL string returned by "echo -e '\0'",
#    otherwise, "grep --invert-match" uses the list of deleted files.
GREP_NOT_DELETED=grep --invert-match "$$( ( [ -z $$(git ls-files --deleted) ] && echo -e '\0' ) || ( git ls-files -z --deleted | tr '\0' '\n' ) )"
GREP_PACKAGE=grep '^cookiecutter_python_vscode_github/'
GREP_TESTS=grep '^tests/'
GREP_PYTHON=grep '\.py$$'
GREP_NOT_PYTHON=grep --invert-match '\.py$$'
GREP_SHELL=grep '\.sh$$'
PACKAGE_SRC=$(shell ${GIT_FILES} | ${GREP_PACKAGE} | ${GREP_PYTHON} | ${GREP_NOT_DELETED}) $(shell ${GIT_UNTRACKED_FILES} | ${GREP_PACKAGE} | ${GREP_PYTHON})
PACKAGE_DATA=$(shell ${GIT_FILES} | ${GREP_PACKAGE} | ${GREP_NOT_PYTHON} | ${GREP_NOT_DELETED}) $(shell ${GIT_UNTRACKED_FILES} | ${GREP_PACKAGE} | ${GREP_NOT_PYTHON})
TESTS_SRC=$(shell ${GIT_FILES} | ${GREP_TESTS} | ${GREP_PYTHON} | ${GREP_NOT_DELETED}) $(shell ${GIT_UNTRACKED_FILES} | ${GREP_TESTS} | ${GREP_PYTHON})
TESTS_DATA=$(shell ${GIT_FILES} | ${GREP_TESTS} | ${GREP_NOT_PYTHON} | ${GREP_NOT_DELETED}) $(shell ${GIT_UNTRACKED_FILES} | ${GREP_TESTS} | ${GREP_NOT_PYTHON})
SHELL_SRC=$(shell ${GIT_FILES} | ${GREP_SHELL} | ${GREP_NOT_DELETED}) $(shell ${GIT_UNTRACKED_FILES} | ${GREP_SHELL})

## main        : Run all necessary rules to build the Python package (from "clean" to "smoke"). It is designed to be executed whithin a virtual environment created by "venv" rule.
main: clean install lock sync format secure lint test package smoke
.PHONY: main

## clean       : Delete caches and files generated during the build.
.cache/make/clean: Makefile
	rm -rf .cache/make cookiecutter-python-vscode-github.egg-info .pytest_cache tests/.pytest_cache dist requirements-dev-*.txt
	mkdir --parents .cache/make
	@date > $@
.PHONY: clean
clean: .cache/make/clean

## install     : Install most recent versions of the development dependencies.
.cache/make/install: .cache/make/clean pyproject.toml requirements-dev.txt constraints.txt
	pip install --quiet --requirement=requirements-dev.txt --editable=. --constraint=constraints.txt
	@date > $@
.PHONY: install
install: .cache/make/install

## lock        : Lock development and production dependencies.
requirements-dev.lock: .cache/make/install requirements-dev.txt constraints.txt pyproject.toml requirements-prod.txt
	pip-compile --quiet --resolver=backtracking --generate-hashes --strip-extras --allow-unsafe --output-file=requirements-dev.lock --no-header --no-annotate requirements-dev.txt pyproject.toml --constraint=constraints.txt
requirements-prod.lock: pyproject.toml requirements-prod.txt requirements-dev.lock
	pip-compile --quiet --resolver=backtracking --generate-hashes --strip-extras --allow-unsafe --output-file=requirements-prod.lock --no-header --no-annotate pyproject.toml --constraint=requirements-dev.lock
.PHONY: lock
lock: requirements-dev.lock requirements-prod.lock

## unlock      : Unlock development and production dependencies.
.PHONY: unlock
unlock:
	rm -rf requirements-*.lock

## sync        : Syncronize development dependencies in the environment according to requirements-dev.lock.
.cache/make/sync: pyproject.toml requirements-dev.lock
	pip-sync --quiet requirements-dev.lock
	pip install --quiet --editable=.
	@date > $@
.PHONY: sync
sync: .cache/make/sync

## format      : Format source code.
# If docformatter fails, the script ignores exit status 3, because that code is returned when docformatter changes any file.
# If the variable PRETTIER_DIFF is not empty, prettier is executed. Ignore errors because prettier is not available in GitHub Actions.
.cache/make/format: .cache/make/sync ${PRETTIER_DIFF} ${PACKAGE_SRC} ${TESTS_SRC}
	pyupgrade --py311-plus --exit-zero-even-if-changed ${PACKAGE_SRC} ${TESTS_SRC}
	isort --profile black cookiecutter_python_vscode_github tests
	black cookiecutter_python_vscode_github tests
	docformatter --in-place --recursive cookiecutter_python_vscode_github tests || [ "$$?" -eq "3" ]
	-[ -z "${PRETTIER_DIFF}" ] || prettier ${PRETTIER_DIFF} --write
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
.cache/make/lint: .cache/make/format ${PACKAGE_SRC} ${TESTS_SRC} ${SHELL_SRC} .pylintrc mypy.ini .shellcheckrc
	pylint cookiecutter_python_vscode_github
	mypy cookiecutter_python_vscode_github tests
	shellcheck ${SHELL_SRC}
	@date > $@
.PHONY: lint
lint: .cache/make/lint

## test        : Run automated tests.
.cache/make/test: .cache/make/format ${PACKAGE_SRC} ${PACKAGE_DATA} ${TESTS_SRC} ${TESTS_DATA}
	pytest --cov=cookiecutter_python_vscode_github --cov-report=term-missing tests
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
	cookiecutter-python-vscode-github --help
	cookiecutter-python-vscode-github --version
	pip install --quiet --editable=.
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
