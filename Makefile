compile-article:
	Rscript code/viz.R
	typst compile article/main.typ
	mv article/main.pdf article.pdf

.PHONY: compile-article
