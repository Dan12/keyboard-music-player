zip:
	zip -r final.zip README.md install src -x src/_build/* src/*.byte

log:
	git log --stat > gitlog.txt