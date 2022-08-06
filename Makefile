
lint:
	black -C -t py38 boa/
	isort boa/
	flake8 boa/
	mypy --install-types --non-interactive --follow-imports=silent --ignore-missing-imports --disallow-incomplete-defs -p boa

# note: for pypi upload,
# rm -r titanoboa.egg-info/ dist/
# python -m build
# twine upload dist/*
