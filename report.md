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
\textit{Most definitions in this section can be found in greater detail in the
  appropriate sections of\ \cite{Sipser:1996:ITC:524279}.}

\vbox{
  \begin{definition}[alphabet]
    An \textit{alphabet} is a set of symbols, $\Sigma$.
  \end{definition}
}

\vbox{
  \begin{definition}[string]
    A \textit{string} $w = w_0w_1\ldots{}w_n$ is an ordered sequence of symbols.
    We use $\varepsilon$ to represent the empty string.
    We write $w_{ij}$ to mean the substring of $w$ containing symbols
    $w_iw_{i+1}\ldots{}w_{j}$.
  \end{definition}
}

\vbox{
  \begin{definition}[Kleene star]
    The \textit{Kleene star} of an alphabet, $\Sigma^*$ is then defined as the
    set of all finite strings of symbols in $\Sigma$:
    $$
    \Sigma^* \equiv
    \{w_0w_1\ldots w_k : w_i \in \Sigma, k \geq 0, 0 \leq i \leq k\}
    $$
  \end{definition}
}

\vbox{
  \begin{definition}[language]
    A \textit{language}, in turn, is a subset of the Kleene star over an
    alphabet, $L \subseteq \Sigma^*$.
  \end{definition}
}

## Context-Free Grammars

\vbox{
  \begin{definition}[context-free grammar] \label{context-free grammar}
    A \textit{context-free grammar} (CFG) is a 4-tuple
    $G = (N,\Sigma,\mathcal{R},S)$, for
    \begin{itemize*}
    \item $N$, a finite set of \textit{non-terminals}.
    \item $\Sigma$, a finite \textit{alphabet} (also called \textit{terminals})
    \item $\mathcal{R} : N\times{(\Sigma \cup N)}^*$, a finite set of
      \textit{productions}, of the form $X \rightarrow \alpha$ for some
      non-terminal $X$, and string of terminals/non-terminals $\alpha$.
    \item $S \in N$, a start state.
    \end{itemize*}
  \end{definition}
}

Suppose, w.r.t. grammar $G$ we define the relations
\begin{align*}
  \alpha X \gamma &\Rightarrow \alpha\beta\gamma
  &\iff X \rightarrow \beta \in \mathcal{R}
  \tag*{$\forall\alpha,\beta,\gamma\in{(\Sigma\cup{}N)}^{*}$} \\
  w X \gamma &\Rightarrow_l \alpha\beta\gamma
  &\iff X \rightarrow \beta \in \mathcal{R}
  \tag*{$\forall{}w\in\Sigma^*,\beta,\gamma\in{(\Sigma\cup{}N)}^{*}$}
\end{align*}
With reflexive transitive closures $\cdot\Rightarrow^*\cdot$ and
$\cdot\Rightarrow_l^*\cdot$ respectively. Then we may say
$\alpha$ \textit{yields} $\beta$ iff $\alpha \Rightarrow \beta$,
$\alpha$ \textit{derives} $\beta$ iff $\alpha \Rightarrow^* \beta$,
and $\alpha$ \textit{left-most derives} $\beta$ iff
$\alpha \Rightarrow_l^* \beta$.

Every left-most derivation also uniquely defines a \textit{parse tree}. A parse
tree $t$ for grammar $G$ deriving a string $w$ is a tree with

 * Elements of $N$ as internal nodes.
 * Elements of $\Sigma$ as leaf nodes s.t. their in-order traversal produces
   $w$.

Furthermore, a node $X$ in $t$ has children
$\alpha_1\alpha_2\ldots\alpha_k = \alpha$ iff
$X\rightarrow\alpha\in\mathcal{R}$.

\vbox{
  \begin{definition}[$L(\cdot)$]
    The \textit{language of $G$} is given by
    $$
    L(G) = \{w\in\Sigma^*:S\Rightarrow^*w\}
    $$
  \end{definition}
}

\vbox{
  \begin{definition}[ambiguity]
    $G$ is \textit{ambiguous} if for some $w\in\Sigma^*$, There is more than one
    left-most derivation of $w$ from $S$.  Otherwise $G$ is
    \textit{unambiguous}.
  \end{definition}
}

\vbox{
  \begin{definition}[Chomsky Reduced Form]
    $G$ is in \textit{Chomsky Reduced Form} (CRF) if all of its rules are in one
    of two forms:
    \begin{align*}
      A &\rightarrow BC \tag*{$\forall A,B,C \in N$}\\
      A &\rightarrow a \tag*{$\forall A \in N, a\in\Sigma$}
    \end{align*}
    Observe that grammars in CRF can generate any language that does not contain
    $\varepsilon$.
  \end{definition}
}

# Technology

words

# Survey {#survey}

words

# Angluin's K-Bounded Algorithm

words

## Algorithm

words

## Restriction to Chomsky Reduced Form

words

# A Sampling Oracle

words

## Pruning a Context-Free Grammar

words

### Contribution and \textsc{HornSAT}

words

## Enumerating a Context-Free Language

words

### A Modified Earley Parser

words

### Nullity and \textsc{HornSAT}

words

## Parsing CRF Grammars

words

## Algorithm

words

# Compensating for an Imperfect Oracle

words

## Strong Consistency

words

### \textsc{BestRules}

words

## Online Kernel Logistic Regression

words

## Loosening the CRF Restriction

words

## Algorithm

words

# Analysis

words

## Maximal Ambiguity

words

## Test Cases

words

### ${(ab)}^+$

words

### $a^{n}b^{n}$

words

### $a^{n}b^{m}c^{n+m}$

words

### Balanced Parantheses

words

### Mathematical Expressions

words

# Discussion

words

## Choosing Non-Terminals

words

## Kernels

words

## Learning SCFGs

words

## Component Analysis

words

## Disambiguation

words

# Acknowledgements

words

# References

\bibliography{references}

# Appendix A <!-- Subsidiary Listings -->

words

## Representing CFGs

words

## Representing SCFGs

words

## \textsc{HornSAT}

words

## Strongly Connected Components

words

# Appendix B <!-- Tests -->

test
