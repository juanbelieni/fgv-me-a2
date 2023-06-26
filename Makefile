
compile-article:
	Rscript code/viz.R
	typst compile article/main.typ

.PHONY: compile-article
