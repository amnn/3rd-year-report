---
title: Learning Context-Free Languages
author: Ashok Menon
abstract: |
  This project aims to produce an interactive learning algorithm for
  context-free languages. To this end, I modify Angluin's \textit{k-bounded
  learning algorithm} --- an algorithm for learning a subset of context-free
  grammars, with the use of an oracle. The work is split between designing a
  model for the oracle that is conducive to interaction and modifying the
  algorithm itself to take advantage of certain restrictions that we can afford
  to make. In the end I measure the cost of accounting for errors by comparing
  two variants of the algorithm: One that assumes a perfect human oracle, and
  one that is fault-tolerant.
...
\pagebreak

# Introduction
Language inference is a fairly mature topic, with regular languages in
particular receiving much attention in the literature. Comparatively, the body
of work regarding the inference of context-free languages is more sparse. This
disparity could (fairly) be attributed to the added complexity that comes from
attempting to learn a language by inferring its context-free grammar: It is
often useful to not only learn the language, but also a grammar with favourable
structural properties that recognises it. This has been difficult to achieve
in practise.

Various papers --- which we will explore in Section\ \ref{survey} --- have
addressed this issue by restricting themselves to subsets of the context-free
grammars. In doing so, one can assume useful information about the structure of
the grammar at the cost of being unable to learn certain languages.

A prime example of such a property is \textit{ambiguity}: In general, deciding
whether a given grammar is \textit{ambiguous} is undecidable
\cite[Theorem~9.2.0~pp.405-406]{Hopcroft:2000:IAT:557657}, however, by being
careful in picking the subset of the context-free grammars to learn, one can
guarantee that the algorithm always outputs an unambiguous grammar, as in
\cite{Clark06pac-learningunambiguous}.

In this project, I aim to make the distinction clear between learning the
language and learning the grammar which represents it, and will focus almost
entirely on the latter. By making as few assumptions as possible about the
structure of the grammar that should be produced, one can avoid restricting the
set of learnable languages.

# Background

# Technology

# Survey {#survey}

# Angluin's K-Bounded Algorithm

## Algorithm

## Restriction to Chomsky Normal Form

# A Sampling Oracle

## Pruning a Context-Free Grammar

### Contribution and \textsc{HornSAT}

## Enumerating a Context-Free Language

### A Modified Earley Parser

### Nullity and \textsc{HornSAT}

## Parsing CNF Grammars

## Algorithm

# Compensating for an Imperfect Oracle

## Strong Consistency

### \textsc{BestRules}

## Online Kernel Logistic Regression

## Loosening the CNF Restriction

## Algorithm

# Analysis

## Maximal Ambiguity

## Test Cases

### ${(ab)}^+$

### $a^{n}b^{n}$

### $a^{n}b^{m}c^{n+m}$

### Balanced Parantheses

### Mathematical Expressions

# Discussion

## Choosing Non-Terminals

## Kernels

## Learning SCFGs

## Component Analysis

## Disambiguation

# Acknowledgements

# References

# Appendix A <!-- Subsidiary Listings -->

## Representing CFGs

## Representing SCFGs

## \textsc{HornSAT}

## Strongly Connected Components

# Appendix B <!-- Tests -->
