PARAMS =
LISTINGS = prune.md reach.md contribution.md cyk.md parse_trees.md learn.md \
		init_g.md diagnose.md candidate.md

all: out/report.pdf

out/%.tex: %.md %_template.tex references.bib
	pandoc  --template=$*_template.tex \
		--variable monofont=Menlo \
		--latex-engine=xelatex \
		--number-sections \
		--bibliography=references.bib \
		--natbib \
		$(PARAMS) \
		-f markdown -t latex \
		$< -o $@

aux/%.tex: %.md
	pandoc --latex-engine=xelatex \
	       -f markdown -t latex \
	       $< -o $@

out/report.tex : $(LISTINGS:%.md=aux/%.tex)

count: out/report.tex
	texcount -sum=1,0,0,0,0,0,0 -col out/report.tex

out/%.pdf: out/%.tex references.bib
	latex -output-directory=out out/$*
	bibtex out/$*
	latex -output-directory=out out/$*
	pdflatex -output-directory=out out/$*
