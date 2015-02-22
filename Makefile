PARAMS =

all: report.pdf

%.tex: %.md %_template.tex references.bib
	pandoc  --template=$*_template.tex \
		--variable monofont=Menlo \
		--latex-engine=xelatex \
		--number-sections \
		--bibliography=references.bib \
		--natbib \
		$(PARAMS) \
		-f markdown -t latex \
		$< -o out/$@

count: report.tex
	texcount out/report.tex

%.pdf: %.tex references.bib
	latex -output-directory=out out/$*
	bibtex out/$*
	latex -output-directory=out out/$*
	pdflatex -output-directory=out out/$*
