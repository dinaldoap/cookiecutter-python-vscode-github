PACKAGE_SRC=$(shell find capgain -type f -name '*.py' ! -name 'version.py')
TESTS_SRC=$(shell find tests -type f -name '*.py')
TESTS_DATA=$(shell find tests -type f -name '*.xlsx' -name '*.ini')

main: clean install lock sync format secure lint test package smoke
.PHONY: main

.cache/make/clean:
	rm -rf .cache/make capgain.egg-info .pytest_cache tests/.pytest_cache dist
	mkdir --parents .cache/make
	@date > $@
.PHONY: clean
clean: .cache/make/clean

.cache/make/install: requirements-editable.txt pyproject.toml requirements-dev.txt constraints.txt
	pip install --quiet --requirement=requirements-editable.txt --requirement=requirements-dev.txt
	@date > $@
.PHONY: install
install: .cache/make/install

.cache/make/lock: .cache/make/install requirements-dev.txt constraints.txt pyproject.toml requirements-bridge.txt
	pip-compile --quiet --resolver=backtracking --generate-hashes --strip-extras --output-file=requirements-dev.lock --no-header --no-annotate requirements-dev.txt pyproject.toml
	pip-compile --quiet --resolver=backtracking --generate-hashes --strip-extras --output-file=requirements-prod.lock --no-header --no-annotate pyproject.toml requirements-bridge.txt
	@date > $@
.PHONY: lock
lock: .cache/make/lock

.PHONY: unlock
unlock:
	rm requirements-*.lock

.cache/make/sync: .cache/make/lock requirements-editable.txt pyproject.toml requirements-dev.lock
	pip-sync --quiet requirements-dev.lock
	pip install --quiet --requirement=requirements-editable.txt
	@date > $@
.PHONY: sync
sync: .cache/make/sync

.cache/make/format: .cache/make/sync ${PACKAGE_SRC} ${TESTS_SRC}
	isort --profile black capgain tests
	black capgain tests
	docformatter --in-place --recursive capgain tests
	@date > $@
.PHONY: format
format: .cache/make/format

.cache/make/pip-audit: .cache/make/sync requirements-prod.lock
	pip-audit --cache-dir=${HOME}/.cache/pip-audit --requirement=requirements-prod.lock
	@date > $@
.cache/make/bandit: .cache/make/sync ${PACKAGE_SRC}
	bandit --recursive capgain
	@date > $@
.PHONY: secure
secure: .cache/make/pip-audit .cache/make/bandit

.cache/make/lint: .cache/make/sync ${PACKAGE_SRC} .pylintrc
	pylint capgain
	@date > $@
.PHONY: lint
lint: .cache/make/lint

.cache/make/test: .cache/make/sync ${PACKAGE_SRC} ${TESTS_SRC} ${TESTS_DATA}
	pytest --cov=capgain --cov-report=term-missing tests
	@date > $@
.PHONY: test
test: .cache/make/test
	
.cache/make/package: .cache/make/sync ${PACKAGE_SRC} pyproject.toml
	rm -rf dist/
	python -m build
	@date > $@
.PHONY: package
package: .cache/make/package

.cache/make/smoke: .cache/make/package
	pip install --quiet dist/*.whl
	capgain --help
	capgain --version
	pip install --quiet --requirement=requirements-editable.txt
	@date > $@
.PHONY: smoke
smoke: .cache/make/smoke

.PHONY: venv
venv:
	bash make/venv.sh

.PHONY: venv-init
venv-init:
	bash make/venv-init.sh

.PHONY: devcontainer
devcontainer:
	bash .devcontainer/devcontainer.sh

.PHONY: testpypi
testpypi:
	twine upload --repository testpypi dist/capgain*.whl