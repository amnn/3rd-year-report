PARAMS =

all: report.pdf

%.tex: %.md %_template.tex
	pandoc  --template=$*_template.tex \
		--variable monofont=Menlo \
		$(PARAMS) \
		-f markdown -t latex \
		$< -o $@

count: report.tex
	texcount report.tex

%.pdf: %.md %_template.tex
	pandoc  --template=$*_template.tex \
		--latex-engine=xelatex \
		--variable monofont=Menlo \
		$(PARAMS) \
		$< -o $@
