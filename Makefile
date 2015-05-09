PARAMS =
LISTINGS = prune.md reach.md contribution.md cyk.md parse_trees.md learn.md \
		init_g.md diagnose.md candidate.md interactive_member.md \
		lang_seq.md earley_item.md earley_state.md token_consumer.md \
		null.md interactive_counter.md scfg_sample.md sc_sample.md \
		make_strongly_consistent_star.md strongly_consistent.md \
		enum_sampling.md soft_k_bounded.md soft_memo.md harness.md \
		ancillary_harness.md harness_specialise.md cfg.md inverted.md \
		scfg.md mut_scfg.md hop.md best_rules.md

DIAGRAMS = parens1.png parens2.png ab_plus.png anbn.png addition.png maths.png

all: out/report.pdf

clear:
	rm -rf out/*

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

out/report.tex : $(LISTINGS:%.md=aux/%.tex) $(DIAGRAMS)

count: out/report.tex
	texcount -sum=1,0,0,0,0,0,0 -col out/report.tex

out/%.pdf: out/%.tex references.bib
	latex -output-directory=out out/$*
	bibtex out/$*
	latex -output-directory=out out/$*
	pdflatex -output-directory=out out/$*
