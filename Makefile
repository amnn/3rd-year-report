all: report.pdf

%.pdf: %.md %_template.tex
	pandoc  --template=$*_template.tex \
		--latex-engine=xelatex \
		--variable monofont=Menlo \
		$< -o $@
