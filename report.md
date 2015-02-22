---
title: Learning Context-Free Languages
author: Ashok Menon
abstract: |
  This project aims to produce an interactive learning algorithm for
  Context-Free Languages. To this end, I modify Angluin's \textit{k-bounded
  learning algorithm} --- an algorithm for learning a subset of Context-Free
  Grammars, with the use of an Oracle. The work is split between designing a
  model for the Oracle that is conducive to interaction and modifying the
  algorithm itself to take advantage of certain restrictions that we can afford
  to make. In the end I measure the cost of accounting for errors by comparing
  two variants of the algorithm: One that assumes a perfect human Oracle, and
  one that is fault-tolerant.
...
\pagebreak

# Introduction
Language inference is a fairly mature topic, with Regular Languages in
particular receiving much attention in the literature. Comparatively, the body
of work regarding the inference of Context-Free Languages is sparser. This
disparity could (fairly) be attributed to the added complexity that comes from
attempting to learn a language by inferring its Context-Free Grammar: It is
often useful to not only learn the language, but also a grammar with favourable
structural properties that recognises it.

Various papers --- which we will explore in Section\ \ref{survey} --- have
addressed this issue by restricting themselves to various subsets of the
Context-Free Languages. In this project, I attempt to avoid such restrictions by
learning \textit{just} the language, whilst trying to make as few assumptions as
possible about the structure of the grammar that we want to represent it.

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
