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

```{.clojure}
```

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

One could also focus on learning the language, without expecting any favourable
properties from the grammar. This is the approach we will follow in this
project, starting from the algorithm proposed in\ \cite{angluin1987learning},
which assumes only that a grammar is \textit{k-bounded}. Whilst this assumption
restricts the learnable grammars, it does not restrict the learnable
\textit{languages}, which we will later show.

A major limitation of the algorithm, however, is that an \textit{oracle} is
required, capable of answering queries that would normally be undecidable.
Consequently, we cannot rely on purely automated responses to such queries, as
to do so, the program providing the answers would already ``know too much''
about the language we intend to learn.

We overcome this hurdle in the most straightforward way possible: By making the
learning process interactive. Allowing a user to act as the oracle effectively
eliminates the strong restriction that the undecidable nature of the queries
originally posed, but introduces new concerns. Firstly, if the user were able to
answer the questions in the form they are asked by the algorithm, it is highly
likely that they would easily be able construct a grammar to recognise the
language themselves. In order that the learning algorithm provide some sort of
utility then, one must somehow ask less of the user and construct the
information needed from their responses. Secondly, we cannot presume that a user
will always provide perfect answers, after all, ``to err is human''.

In this project, I hope to show that these two new considerations are more
manageable than the restriction they replace, by offering solutions to both.
Moreover, I explore the cost of relying on user queries: Provided all parts of
the algorithm are reasonably efficient (polynomial time complexity w.r.t. size,
let us say), the rate limiting step becomes the user. I take this into account
when analysing variants of the algorithm by using a cost model in which the unit
operation is a query to the user.

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
      \textit{productions} or \textit{rules}, of the form $X \rightarrow \alpha$
      for some non-terminal $X$, and string of terminals/non-terminals $\alpha$.
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
$\cdot\Rightarrow_l^*\cdot$ respectively. Then we may say $\alpha$
\textit{1-step derives} $\beta$ iff $\alpha \Rightarrow \beta$, $\alpha$
\textit{derives} $\beta$ iff $\alpha \Rightarrow^* \beta$, and $\alpha$
\textit{left-most derives} $\beta$ iff $\alpha \Rightarrow_l^* \beta$. The term
\textit{yields} is also often used interchangeably with \textit{derives},
especially in the context of \textit{parse trees}.

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
  \begin{definition}[Chomsky Reduced Form] \label{def:crf}
    $G$ is in \textit{Chomsky Reduced Form} (CRF) if all of its rules are in one
    of two forms:
    \begin{align*}
      A &\rightarrow BC \tag*{$A,B,C \in N$}\\
      A &\rightarrow a \tag*{$A \in N, a\in\Sigma$}
    \end{align*}
    The former will be referred to as a \textit{branch} rule, and the latter as
    a \textit{leaf} rule.

    Observe that grammars in CRF can generate any context-free language that
    does not contain $\varepsilon$. For convenience, we shall denote this class
    of languages $\mathcal{L}^{\bar \varepsilon}$.
  \end{definition}
}

## Stochastic Context-Free Grammars
\textit{The definitions from here onwards can be found explained in greater
  detail in the appropariate sections of\ \cite{Manning:1999:FSN:311445}.}

\vbox{
  \begin{definition}[stochastic context-free grammar]
    A \textit{stochastic context-free grammar} (SCFG) is a 5-tuple
    $G~=~(N,\Sigma,\mathcal{R},S,p)$, for
    \begin{itemize*}
    \item $N, \Sigma, \mathcal{R}, S$, as defined in
      Definition\ \ref{context-free grammar}.
    \item $p : \mathcal{R} \rightarrow \mathbb{R}^+$ A family of probability
      mass functions, one for each $X \in \mathcal{R}$ s.t.
      \begin{align*}
        \sum_{X \rightarrow \alpha \in \mathcal{R}}{p_X(\alpha)} &= 1
      \end{align*}
    \end{itemize*}
  \end{definition}
}

As the first four elements of the 5-tuple representing an SCFG are analogous to
the definition of a CFG, all the definitions from the previous section also
apply here. In addition, SCFGs define a probability distribution over
$\Sigma^*$.

\vbox{
  \begin{definition}[probability of a derivation]
    Given a stochastic grammar $G~=~(N,\Sigma,\mathcal{R},S,p)$,
    and a derivation $\alpha_0 \Rightarrow^* \alpha_n$
    $$
    \alpha_0
    \overset{R_1}{\Rightarrow} \alpha_1
    \overset{R_2}{\Rightarrow}\dotsb
    \overset{R_n}{\Rightarrow} \alpha_n
    $$
    Where we take $\alpha_i \overset{R_{i+1}}{\Rightarrow} \alpha_{i+1}$ to mean
    that we yield $\alpha_{i+1}$ from $\alpha_{i}$ by applying some rule
    $R_{i+1} = X_{i+1} \rightarrow \gamma_{i+1} \in \mathcal{R}$, to a
    non-terminal in $\alpha_i$.

    We take the \textit{derivation probability} to be
    $$
    \mathbb{P}(\alpha_0 \Rightarrow^* \alpha_n \mid G) \equiv
    \prod_{i=1}^n{p_{X_i}(\gamma_i)}
    $$
    In cases where $G$ is obvious, it can be omitted.
  \end{definition}
}

\vbox{
  \begin{definition}[total probability]
    The \textit{total probability} of deriving a string $\beta$ given a
    starting string $\alpha$, in $G$, written $\mathbb{P}(\beta \mid \alpha, G)$,
    is the sum of the probabilities of all left-most derivations starting at
    $\alpha$, deriving $\beta$.
    \begin{align*}
    \mathbb{P}(w\mid\alpha, G) \equiv
    \sum_{\alpha \Rightarrow_l \alpha_1 \Rightarrow_l\dotsb\Rightarrow_l \beta}{
      \mathbb{P}(\alpha \Rightarrow_l \alpha_1
      \Rightarrow_l\dotsb\Rightarrow_l \beta \mid G)
    }
    \tag*{$\forall\alpha,\beta\in(\Sigma\cup{}N)^*$}
    \end{align*}
    If the $G$ in question is obvious from the context, it is sometimes omitted.
  \end{definition}
}

\vbox{
  \begin{definition}[inside probability]
    The \textit{inside probability} of deriving a string $w\in\Sigma^*$ given an
    $X\in{}N$ is simply $\mathbb{P}(w \mid X)$.
  \end{definition}
}

\vbox{
  \begin{definition}[outside probability]
    For completeness, we also define the \textit{outside probability} of
    $\alpha\in(\Sigma\cup{}N)^*$ as $\mathbb{P}(\alpha \mid S)$.
  \end{definition}
}

\vbox{
  \begin{definition}[probability distribution]
    A stochastic grammar $G$ defines a distribution $D_G$ over $w\in\Sigma^*$
    s.t.
    \begin{align*}
      \mathbb{P}(W = w) \equiv \mathbb{P}(w \mid S)
      \tag*{$W\sim{}D_G$}
    \end{align*}
    Such a distribution is said to be \textit{consistent} iff
    $$
    \sum_{w\in\Sigma^*}\mathbb{P}(W = w) = 1
    $$
    And is \textit{inconsistent} otherwise.
  \end{definition}
}

\vbox{
  \begin{definition}[most likely parse]
    The \textit{most likely parse} of a string $w$ by a stochastic grammar $G$,
    is the left-most derivation of highest probability from $S$ to $w$.
    $$
    \operatorname*{arg\,max}_{S \Rightarrow_l \alpha_1 \Rightarrow_l\dotsb\Rightarrow_l w}{
      \mathbb{P}(S \Rightarrow_l \alpha_1 \Rightarrow_l\dotsb\Rightarrow_l w)
    }
    $$
  \end{definition}
}

It is worth noting that the previous observation in Definition\ \ref{def:crf}
still holds for SCFGs.

# Technology

## Language and Runtime
The implementation of this project will be written in \textit{Clojure}, a LISP
dialect that runs on the JVM. I chose \textit{Clojure} for its

 * Strong but practical focus on functional programming paradigms.
 * Access to the large echosystem of Java libraries.
 * Read-Eval-Print Loop (REPL), which affords an interactive development
   workflow.
 * Macro system, which allows for the creation of embedded Domain-Specific
   Languages (DSL).

## Libraries
The wealth of libraries written in and for \textit{Clojure} allow me to focus on
the main ideas of the project, without being distracted by the definitions of
ancillary functions. In this section, I outline the dependencies used in the
project.

\phantomsection{}
\addcontentsline{toc}{subsubsection}{\texttt clojure.data/priority-map}
\subsubsection*{\texttt{clojure.data/priority-map} \\
  \small{\cite{clojure_data_prioritymap}}}

An ordered key-value data structure sorted by its value, with a uniqueness
constraint on keys. Used in situations similar to a heap.

\phantomsection{}
\addcontentsline{toc}{subsubsection}{\texttt bigml/sampling}
\subsubsection*{\texttt{bigml/sampling} \\
  \small{\cite{bigml_sampling}}}

A library of sampling functions, for picking random elements from both finite
collections and infinite streams.

\phantomsection{}
\addcontentsline{toc}{subsubsection}{\texttt net.mikera/core.matrix}
\subsubsection*{\texttt{net.mikera/core.matrix} \\
  \small{\cite{net_mikera_core_matrix}}}

A language extension to \textit{Clojure} adding generalised N-dimensional array
programming protocols. By default these protocols are only implemented by the
standard library collections which are not well-suited to array programming
operations.

\phantomsection{}
\addcontentsline{toc}{subsubsection}{\texttt net.mikera/vectorz-clj}
\subsubsection*{\texttt{net.mikera/vectorz-clj} \\
  \small{\cite{net_mikera_vectorz_clj}}}

\textit{Clojure} wrapper over the \textit{Vectorz} Java library. This provides a
high performance implementation of the \texttt{core.matrix} protcols for
arbitrary N-dimensional arrays.

## Architecture
Interaction with the software will be via a \textit{Clojure} REPL session. This
approach allows for state to be saved in the session between invocations of the
learning algorithms, making experimentation with parameters easier.

\textit{Clojure} is a dynamically typed language, so verification will be, for
the most part, in the form of unit tests. The tests for each module can be found
in the Appendices.

# Survey {#survey}

It follows from the results in\ \cite{Gold1967447} that it is impossible to
learn context-free languages in the limit, using only positive and negative
examples. And furthermore, it follows from\ \cite{Kearns:1994:CLL:174644.174647}
that we cannot PAC learn CFLs using only positive and negative examples
either. Various methods have been used to avoid these restrictions, such as
leveraging structural information, or assuming properties of the grammar being
learnt or the distribution the samples are coming from. In this section, we will
briefly explore the specific techniques used in three different papers.

## Learning Unambiguous NTS Grammars

In\ \cite{Clark06pac-learningunambiguous}, we assume three things: Firstly, the
grammar must be unambiguous, secondly, the grammar is NTS (as defined below),
and finally, the positive samples must be sampled from the distribution of some
(unknown) SCFG.

\vbox{
  \begin{definition}[Non-Terminally Separated]\label{def_nts}
    A grammar $G = (N,\Sigma,\mathcal{R},S)$ is
    \textit{non-terminally separated} iff
    \begin{align*}
      \text{when}~& B\Rightarrow^*\beta \tag*{$\beta\in\Sigma^*,B \in N$} \\
      \text{then}~& A \Rightarrow^* \alpha\beta\gamma
                    \implies A \Rightarrow^* \alpha B \gamma
      \tag*{$\forall \alpha, \gamma \in \Sigma^*, A \in N$}
    \end{align*}
    In other words, if we can derive some string $\beta$ from $B$ in $G$,
    and $\beta$ appears as a substring of some other derivation, then it must,
    in that derivation, be derived from $B$.
  \end{definition}
}

By making the aforementioned assumptions, Clark is able to efficiently PAC learn
this subset of the CFLs. The algorithm works by examining the contexts that
strings appear in, within the corpus of samples provided. Essentially, strings
that appear in the same context are derived from the same non-terminal in the
grammar being learnt. Contexts can be used in this way due to the assumption
that the samples are coming from an SCFG.

The cost of these assumptions, however, is that certain trivial languages can no
longer be presented: Take, for instance, the regular language described by
$aa^*$. Clark shows that this language is not representable by an unambiguous
NTS grammar: An NTS grammar that represents it must necessarily be ambiguous.

## Efficient learning of context-free grammars from positive structural examples {#sakakibara}

This algorithm, explained fully in \cite{Sakakibara199223}, makes use of
``positive structural examples'' --- unlabeled parse trees --- from
\textit{reversible} context-free grammars as well as structural membership and
structural equivalence queries in the learning process.

\vbox{
  \begin{definition}[Reversible]
    A grammar $G = (N,\Sigma,\mathcal{R},S)$ is \textit{reversible} if
    \begin{align*}
      &A\rightarrow\alpha, B\rightarrow\alpha\in\mathcal{R}
      &\implies A = B \tag{1}\\
      &A\rightarrow\alpha{}B\beta, A\rightarrow\alpha{}C\beta\in\mathcal{R}
      &\implies B=C \tag{2}
    \end{align*}
  \end{definition}
}

There seem to be similarities between this definition and
Definition\ \ref{def_nts} of NTS grammars, but it is only skin deep. In fact
neither class of grammars is entirely contained within the other, as shown
in Figure\ \ref{rev_nts_counter}.

As explained in the paper, the restriction to \textit{reversible} grammars is
not a restriction at all: \textit{Reversible} grammars are a normal form for
context-free grammars. Therefore, this algorithm is capable of learning
\textit{any} context-free language.

While this seems to be a promising start point, the requirement for structural
information in the samples and the membership queries is quite a powerful
tool. As we will see in Section\ \ref{angluin}, we can make do with less, if we
are not concerned with learning in the limit.

\begin{figure}
  \begin{subfigure}[t]{0.45\textwidth}

    \begin{align*}
      S &\rightarrow ab \mid S^\prime \\
      S^\prime &\rightarrow Abc \\
      A &\rightarrow a
    \end{align*}
  \end{subfigure}
  \begin{subfigure}[t]{0.45\textwidth}

    \begin{align*}
      S &\rightarrow A \mid B \\
      A &\rightarrow aC \mid d \\
      B &\rightarrow bC \mid d \\
      C &\rightarrow c
    \end{align*}
  \end{subfigure}
  \caption{The grammar on the left is \textit{reversible} but not \textit{NTS},
    whilst the grammar on the right is \textit{NTS} but not \textit{reversible},
    thus indicating that neither class of grammars is contained within the
    other.}
  \label{rev_nts_counter}
\end{figure}

## Learning Context-Free Grammars with a Simplicity Bias
\cite{langley2000learning} assumes nothing about the grammar, or the language,
and works from positive samples only, so seems to buck the trend followed by
other algorithms. However, it does not learn languages in the limit, nor in a
distribution-free (PAC) model. Instead, it performs a beam search through the
space of all context-free grammars, looking for a locally optimal grammar.

Optimality, in this case is measured by ``Simplicity''. A grammar is simple if
its description (in terms of number of rules and rule length) is small,
\textit{and} the parse trees of all the samples given are also small. These two
restrictions on size ensure that the algorithm neither over- nor under-fits the
sample. From here on, we shall call this the \textit{simplicity bias} algorithm.

The \textit{simplicity bias} procedure starts at a trivial grammar where for
each string $\alpha$ in the sample, there is a rule $S \rightarrow \alpha$, and
moves through the search space by transforming grammars in its frontier using
one of two operations:
\begin{description}
  \item[Extract] takes a substring $\alpha$ that occurs in multiple rules,
    replaces its occurence in those rules by a fresh non-terminal $A$, to which
    rule $A \rightarrow \alpha$ has been added.

  \item[Merge] if two non-terminals $A, B$ occur in similar contexts within the
    rules of the grammar, then they may be merged by replacing all occurrences
    of $B$ with $A$, adding all rules from $B$ to $A$, and then removing $B$.
\end{description}

This approach suffers from the same issues of any beam search in that it can get
stuck at a local optimum that is not globally optimal, by pruning its frontier
too aggressively. It is also difficult to pinpoint the subset of the
context-free languages the algorithm can learn, simply because, given an unlucky
choice of sample, it can be led astray.

It is interesting to note that, although it is not explicitly stated in
\cite{langley2000learning}, the heuristic used in the \textit{simplicity bias}
algorithm favours \textit{reversible} grammars, as defined
in\ \cite{Sakakibara199223}. This does not mean that the output of the algorithm
is guaranteed to be reversible, however. Indeed, it is possible to violate
condition (2) of reversibility when performing a \textsc{Merge}, although the
\textsc{Extract} procedure is designed precisely to combat this.

# Angluin's K-Bounded Algorithm {#angluin}

As hinted in previous sections, most of the work in this project will be based
on the algorithm originally proposed in\ \cite{angluin1987learning}, which can,
with polynomially many queries to an oracle, learn any \textit{k-bounded}
context-free grammar.

\vbox{
  \begin{definition}[k-bounded]\label{def:kbounded}
    A grammar $G$ is $k$-bounded iff for every
    $X \rightarrow \alpha \in \mathcal{R}$ there are at most $k$ non-terminals
    in $\alpha$.
  \end{definition}
}

That is to say, the algorithm is parametrised by a $k$, given which, it finds a
$k$-bounded grammar that accepts the target language. To do so, the algorithm
must also be given the set of non-terminals, $N$, in a grammar accepting the
language.

## The Oracle

Suppose you are attempting to learn a grammar
$G~=~(N,\Sigma,\mathcal{R},S)$. Angluin's algorithm relies on an oracle to
answer questions about the grammar being learnt that are, in general,
undecidable. These queries come in one of two forms:

\begin{description}
  \item[Non-Terminal Membership] Given some non-terminal $X \in N$ and a string
    $w \in \Sigma^*$ does $N \Rightarrow^* w$ hold in $G$? In other words, in
    the grammar we have in mind, is it possible to derive $w$ from $N$ through
    rules in $\mathcal{R}$. The response to this is simply a truth value.

  \item[Equivalence] Given some grammar $G^\prime$, is $L(G) = L(G^\prime)$? The
    oracle responds with \textit{true} if the assertion holds, or otherwise,
    produces a witness $w \in \Sigma^*$ to $L(G) \not= L(G^\prime)$.
\end{description}

It is possible to draw parallels here with the framework set up
in\ \cite{Sakakibara199223} (as described in Section\ \ref{sakakibara}).
However, where Sakakibara's algorithm needs to know whether a parse tree could
be rooted at some non-terminal $N$, we only ask about the yield from $N$. This
is strictly less information, as more than one parse tree could give the same
yield.

In general it is preferable to rely on a weaker oracle (one that is capable of
providing less information). As our implementation will be relying on human input
to form the answers to its queries, this preference becomes more compelling: A
weaker oracle, means less work for the user.

## Algorithm {#sec:k-bounded-algo}

As input, the algorithm takes $N$, the set of non-terminals, $\Sigma$, the
alphabet, and $S \in N$ the starting non-terminal. From these, it attempts to
learn the productions in the target grammar.

The algorithm repeatedly requests counter-examples, and uses them to add or
remove productions from the grammar it is learning, $G^\prime$. If it is given a
false-positive $c_+$, it finds a parse tree $t$ of G yielding $c_+$ and analyses
it to find and remove a \textit{bad rule}: A rule in $G^\prime$ used in $t$ that
is not in the target. If it is given a false-negative, $c_{-}$, it introduces
new rules to $G^\prime$, at least one of which is guaranteed to be in the
target. In this way, each counter-example is used to bring $G^\prime$ closer to
the target grammar, until there are no counter-examples left, at which point it
is equivalent to the target. Pseudocode is provided in
Algorithm\ \ref{algo:kbounded}, with supporting definitions in
Algorithms\ \ref{algo:diagnose},\ \ref{algo:candidate}.

\begin{algorithm}
\caption{
  Learning routine. \textsc{Parse} returns the parse tree of a grammar for a
  given word. $\textsc{Equal}^*$ and $\textsc{Counter-example}^*$ together
  represent an equivalence query to the oracle.
}

\label{algo:kbounded}
\begin{algorithmic}
\Function{Learn}{N, $\Sigma$, S, k}
  \LineComment{\textbf{input} $N$, The non-terminals in the target grammar.}
  \LineComment{\textbf{input} $\Sigma$, The terminal alphabet of the grammar.}
  \LineComment{\textbf{input} $S \in N$, The start non-terminal.}
  \LineComment{\textbf{input} $k$, A bound on the number of non-terminals in a
    rule.}
  \LineComment{\textbf{output} $G^\prime$, a grammar accepting the target
    language.}
  \State $\mathcal{R}^\prime \gets \emptyset$
  \State $\mathbf{let}~G^\prime = (N,\Sigma,\mathcal{R}^\prime,S)$
  \While{$\lnot\Call{Equal$^\ast$}{G^\prime}$}
    \State $c \gets \Call{Counter-example$^\ast$}{G^\prime}$
    \If {$c \in L(G^\prime)$}
      \State $t \gets \Call{Parse}{G^\prime, c}$
      \State $\mathcal{R}^\prime
      \gets \mathcal{R}^\prime \setminus \{\Call{Diagnose}{t}\}$
    \Else
      \State $\mathcal{R}^\prime
      \gets \mathcal{R}^\prime \cup \Call{Candidate}{c, k}$
    \EndIf
  \EndWhile
  \State \Return $G^\prime$
\EndFunction
\end{algorithmic}
\end{algorithm}

\begin{algorithm}
\caption{
  Diagnose a bad parse. $\textsc{Member}^*$ represents a non-terminal membership
  query to the oracle.
}
\label{algo:diagnose}
\begin{algorithmic}
\Function{Diagnose}{T}
  \LineComment{\textbf{input} A parse tree, for a false-positive string.}
  \LineComment{\textbf{output} A bad production in $G^\prime$}
  \ForAll{children $(T^\prime, x)$ of $T$}
    \If {$\lnot\Call{Member$^\ast$}{T^\prime, x}$}
      \Comment{is the child bad?}
      \State \Return $\Call{Diagnose}{T^\prime}$
    \EndIf
  \EndFor

  \State \Return $T$
\EndFunction
\end{algorithmic}
\end{algorithm}

\begin{algorithm}
\caption{Candidate rules for generating the missing string.}
\label{algo:candidate}
\begin{algorithmic}
\Function{Candidate}{w, k}
  \LineComment{\textbf{input} $w$, A string not currently in $L(G^\prime)$}
  \LineComment{\textbf{input} $k$, A bound on the number of non-terminals in a
    rule.}
  \LineComment{\textbf{output} A set of candidate productions}
  \State $C \gets \emptyset$
  \ForAll{substrings $y$ of $w$}
    \For{$m = 0 \ldots k$}
      \ForAll{$y = x_0y_0 \ldots x_my_mx_{m+1}$}
        \ForAll{$(A, A_0,\ldots,A_m) \in N^{m+1}$}
          \State $C \gets C \cup \{A \rightarrow x_0A_0 \ldots x_mA_mx_{m+1}\}$
        \EndFor
      \EndFor
    \EndFor
  \EndFor
  \State \Return $C$
\EndFunction
\end{algorithmic}
\end{algorithm}

## Restriction to Chomsky Reduced Form {#sec:k-bounded-restrict}

It is obvious, but worth mentioning, that neither $k$ nor $N$ are trivial
parameters to the algorithm: When learning some language $L$, if we fix
particular values for $k$ and $N$ we cannot be certain of the existence of a
$k$-bounded grammar that uses at most $\lvert N \rvert$ non-terminals. In fact,
if we fix some $N$ there is no guarantee that we can find a grammar recognising
the language at all, regardless of the value of $k$. Happily however, if
$L\in\mathcal{L}^{\bar \varepsilon}$, the converse does hold: If we fix the
value of $k > 1$, we can guarantee that for some set of non-terminals $N$, there
is a $k$-bounded grammar $G=(N,\Sigma,\mathcal{R},S)$ s.t. $L(G) = L$.

\begin{theorem}
  For any $n \in \mathbb{N}$, there is a language, $L$ s.t. for any grammar
  $G = (N,\Sigma,\mathcal{R},S)$ where $L(G) = G$, $\lvert N \rvert > n$.

  \begin{proof}[Proof by Contradiction]
    Consider some $n \in \mathbb{N}$, $L=\{\alpha_i^k:0\leq i\leq n, k\geq 0\}$

    Suppose there is some
    $G=(N,\Sigma=\{\alpha_0,\dotsc,\alpha_n\},\mathcal{R},S)$\\
    s.t. $L(G)=L$ and $\lvert N \rvert \leq n$
    \begin{enumerate}[$\implies$]
      \item $S \Rightarrow^* \alpha_i^k$ in $G$
        \hfill $0 \leq i \leq n, k \geq 0$
    \end{enumerate}
    W.l.o.g, assume that for each $X \in N$, $X$ appears in the derivation of
    some $\alpha_i^k \in L$. As otherwise, we may simply discard $X$ from the
    grammar, whilst maintaining that $L(G) = L$ and $\lvert N\rvert \leq n$.
    \begin{enumerate}[$\implies$]
      \item[$\iff$] $X \Rightarrow^* \alpha_i^k$
        \hfill $\forall X\in N.~\exists i,k\in \mathbb{N}$
      \item $X\Rightarrow^*\alpha_i^k$ and $X\Rightarrow^*\alpha_j^l$
        where $i \neq j$ for some $X$
        \hfill $\lvert N \rvert \leq n, \lvert\Sigma\rvert = n+1$\\
        \begingroup\raggedleft
        (pigeon-hole principle)
        \par\endgroup
    \end{enumerate}

    Consider a derivation of $\alpha_i^m$ in $G$, with $m\geq k$:
    \begin{align*}
      S &\Rightarrow^*\alpha_i^pX\alpha_i^q \tag*{$p+q+k = m$}\\
        &\Rightarrow^*\alpha_i^m
      \tag{by our assumption, such a derivation must exist}
    \end{align*}
    \begin{enumerate}[$\implies$]
      \item $S\Rightarrow^*\alpha_i^pX\alpha_i^q
        \Rightarrow^*\alpha_i^p\alpha_j^l\alpha_i^q$\hfill$i\neq j$
      \item[$\overset{\text\textreferencemark}{\implies}$] $L(G) \neq L$\qedhere
    \end{enumerate}
  \end{proof}
\end{theorem}

\begin{theorem}\label{thm:2bounded}
  There is a fixed value of $k$ such that for any
  $L\in\mathcal{L}^{\bar \varepsilon}$, there is a $k$-bounded grammar $G$ s.t.
  $L(G) = L$.

  \begin{proof}
    Observe that, every CRF grammar is 2-bounded, and, as stated
    in Definition\ \ref{def:crf}, every $L\in\mathcal{L}^{\bar \varepsilon}$ is
    recognised by some grammar in CRF.

    From these observations, it follows that our proposition holds for
    $k \geq 2$. \qedhere
  \end{proof}
\end{theorem}

These results suggest a possible simplification: If there is a CRF grammar for
any $L\in\mathcal{L}^{\bar \varepsilon}$, then why not devote our time to
finding grammars solely in this form? Theorem\ \ref{thm:2bounded} shows us that
doing so would remove the need for the parameter $k$: It would always be 2. This
is not to say that, when before, we called $\textsc{Learn}(N,\Sigma,S,k)$,
instead we can always call $\textsc{Learn}(N,\Sigma,S)$ to learn the same
language, it means instead that for \textit{some} $N^\prime$, we can call
$\textsc{Learn}(N^\prime,\Sigma,S)$. The question as to which $N^\prime$ remains
non-trivial and --- to maintain focus --- is out of the scope of this project,
however we touch on some possibilities in Section\ \ref{sec:choosing-nts} of the
Discussion.

In practise, looking only for CRF grammars actually slows down the progress of
our algorithm. As a consequence of the fact that terminals cannot appear in
branch rules in a CRF grammar, often it becomes necessary to introduce a
non-terminal $X$ just to generate some terminal $x$. Our algorithm is unaware of
this fact, so initially, $X$ is given all possible branch and leaf rules, which
must then be systematically removed. By loosening the CRF restriction, and
allowing branch rules to contain terminal symbols, we avoid this situation and
the superfluous non-terminals it entails.

Whilst our restriction to CRF grammars has allowed us to make some useful
simplifications, it seems as though our new algorithm only learns languages in
$\mathcal{L}^{\bar\varepsilon}$. We can in actuality adapt our algorithm to
learn any context-free language by applying a straightforward transformation.
\begin{theorem}
  An algorithm that learns grammars with languages in
  $\mathcal{L}^{\bar\varepsilon}$, can be used to learn grammars for any
  context-free language.

  \textbf{STP:} Such an algorithm can be used to learn a grammar recognising a
  context-free language $L\notin\mathcal{L}^{\bar\varepsilon}$.
  \begin{proof}
    Suppose we wish to learn $G = (N,\Sigma,\mathcal{R},S)$ s.t.
    $L(G)=L\notin\mathcal{L}^{\bar\varepsilon}$.

    Use our algorithm to learn $G^\prime =
    (N^\prime,\Sigma,\mathcal{R}^\prime,S^\prime)$ s.t.
    $L(G^\prime)=L\setminus\{\varepsilon\}\in\mathcal{L}^{\bar\varepsilon}$

    Transform $G^\prime$ to $G$ with the addition of a new start state, $S$:
    \begin{align*}
      N &= N^\prime \cup \{S\} \tag*{$S \notin N^\prime$}\\
      \mathcal{R} &= \mathcal{R}^\prime \cup
      \{S \rightarrow \varepsilon,
      S \rightarrow S^\prime \}\\
    \end{align*}
    Then
    \begin{align*}
      L(G) & = \{w \in \Sigma^* : S \Rightarrow^* w~\text{in}~G\}\\
      & = \{\varepsilon\} \cup
      \{w \in \Sigma^* : S \Rightarrow S^\prime \Rightarrow^* w~\text{in}~G\}
      \tag{derivations of $S$ in $G$}\\
      & = \{\varepsilon\} \cup
      \{w \in \Sigma^* : S^\prime \Rightarrow^* w~\text{in}~G^\prime\}
      \tag{no rule of form $X\rightarrow\alpha{}S\beta$ in $\mathcal{R}$}\\
      & = \{\varepsilon\} \cup L(G^\prime)\\
      & = L \tag*{\qedhere}
    \end{align*}
  \end{proof}
\end{theorem}

## Pruning a Context-Free Grammar {#sec:prune-cfg}

It will be advantageous for us to remove extraneous rules and non-terminals from
the grammar we are learning before performing oracle queries on it. Removing
such artefacts from the grammar will not affect the language it represents, but
will reduce its size.

The benefit here is that whilst pruning a grammar $G$ has worst-case
$\Theta(\lvert{}G\rvert)$ time complexity, parsing a counter-example of size $n$
will have $\Theta(n^3\lvert{}G\rvert)$ time complexity, so if we can reduce the
size of $G$, we will notice a speed difference in practise, even if we do not
affect the asymptotic time complexity. This is especially true initially: As we
will see in Section\ \ref{sec:implementation}, our implementation of the
learning algorithm will begin with a potential grammar that contains many
superfluous rules which it will eliminate eventually through the running
of the algorithm.

\begin{figure}[htbp]
  \caption{Implementation of \textit{pruning} in \textit{Clojure}.}
  \input{aux/prune.tex}
\end{figure}

When pruning a CFG, $G=(N,\Sigma,\mathcal{R},S)$, we aim to remove $X\in{}N$ for
which the following does not hold:
\begin{align*}
  S\overset{(1)}{\Rightarrow^*}\alpha{}X\beta\overset{(2)}{\Rightarrow^*}w
  \tag*{$\exists{}\alpha,\beta\in(\Sigma\cup{}N)^*,w\in\Sigma^*$}
\end{align*}
As these are (by definition) the non-terminals we may remove without affecting
$L(G)$. To remove such $X$'s we perform removals in the following order:
\begin{enumerate*}
  \item \textit{Non-contributing} non-terminals: Non-terminals with no
    derivations of form $(2)$.
  \item Rules mentioning non-terminals that we removed in the previous step.
  \item \textit{Unreachable} non-terminals: Non-terminals with no derivations of
    form $(1)$.
\end{enumerate*}

\begin{remark}
The order of removals is important here: By removing a \textit{non-contributing}
non-terminal in step 1, we may end up removing a rule in step 2 that results in
another non-terminal becoming \textit{unreachable} from $S$.
\end{remark}

\begin{remark}
  The opposite does not hold however: We cannot make a non-terminal $X$
  \textit{non-contributing} by removing an \textit{unreachable} $Y$.
  \begin{proof}
    Suppose $X$ is \textit{non-contributing} after removing $Y$.

    As a Corollary to Remark~\ref{rem:clean-reach}, $X$ cannot mention $Y$ or it
    would itself have been removed.
    \begin{enumerate*}
    \item[$\implies$] Rules of the form $X\rightarrow\alpha$ are preserved in
      the removal of $Y$.
    \item[$\implies$] $X$ must have been \textit{non-contributing} before the
      removal of $Y$.\qedhere
    \end{enumerate*}
  \end{proof}
\end{remark}

\begin{remark}\label{rem:clean-reach}
  We do not have to ``clean up'' after step 3, by removing rules mentioning any
  \textit{unreachable} non-terminals.

  \begin{proof}[Proof by Contradiction]
    Suppose $X\rightarrow\alpha$ --- a rule left in $G$ after step 3 of pruning
    --- mentions an unreachable non-terminal, $Y$.
    \begin{enumerate*}
    \item[$\implies$] $X$ is reachable from $S$ in $G$.
    \item[$\implies$] $S\Rightarrow^*X\rightarrow\alpha=\beta{}Y\gamma$
    \item[$\overset{\text\textreferencemark}{\implies}$] $Y$ is
      \textit{reachable}
    \item[$\implies$] $X\rightarrow\alpha$ cannot exist. \qedhere
    \end{enumerate*}
  \end{proof}
\end{remark}

### Reachability

Instead of finding the set of \textit{unreachable} non-terminals, it is more
convenient to consider the problem of finding \textit{reachable} non-terminals,
and then take the complement of this set w.r.t. $N$.

\begin{figure}[htbp]
  \caption{Implementation of \textit{Reachability}.}\label{list:reach}
  \input{aux/reach.tex}
\end{figure}

Finding the set of non-terminals $N^\prime$ that are reachable from $S$ can be
phrased straightforwardly as a graph problem. Given a grammar
$G=(N,\Sigma,\mathcal{R},S)$, we may construct a directed graph $R$ wherein:
\begin{align*}
  V(R) & = N \\
  E(R) & = \{(X,Y) \in N^2
           : \exists\alpha,\beta\in(\Sigma\cup{}N)^*
           .~X\rightarrow\alpha{}Y\beta\in\mathcal{R}\}
\end{align*}

Then $N^\prime$ is precisely the set of nodes in $R$ reachable (in the graph
theoretic sense) from $S$. In our implementation (Figure\ \ref{list:reach}), we
do not explicitly construct $R$, but implicitly traverse it by a breadth-first
search.

### Contribution and \textsc{HornSAT} {#sec:contribution}

As with reachability, it will be useful here to concentrate on the complement of
\textit{non-contribution}: Given a grammar $G = (N,\Sigma,\mathcal{R},S)$, find
the set of non-terminals $C$ that contribute to strings in $L(G)$. A
non-terminal is said to contribute when it contains at least one rule in which
every mentioned non-terminal also contributes.

\begin{theorem}
  $X\in C \iff
  \exists~X\rightarrow{}u_0Y_0u_1Y_1\ldots{}u_kY_ku_{k+1}\in\mathcal{R}.~
  \{Y_i\}_i\subseteq C$
  \begin{proof}
    Suppose $X\in C$
    \begin{enumerate*}
      \item[$\iff$] $X\rightarrow\alpha\Rightarrow^*w$ in $G$
        \hfill$\exists\alpha\in(\Sigma\cup{}N)^*, w\in\Sigma^*$\\
        \begingroup\raggedleft
        (defn. \textit{contributing})
        \par\endgroup
      \item[~] Let $\alpha = u_0Y_0u_1Y_1\ldots{}u_kY_Ku_{k+1}$
      \item[$\iff$] $w = u_0y_0\ldots{}u_ky_ku_{k+1}$
        where $Y_i\Rightarrow^*y_i,~0 \leq i \leq k$
      \item[$\iff$] $\{Y_i\}_i\subseteq C$\qedhere
    \end{enumerate*}
  \end{proof}
\end{theorem}

Using this definition of \textit{contribution} we may define a propositional
formula, $\phi$ mentioning a propositional variable $c_X$ for every $X\in N$ in
such a way that for an assignment $\mathcal{A}$, $\mathcal{A}\not{\vdash}\phi$
iff $c_Y\mapsto 0 \in \mathcal{A}$ for some $Y\in C$:

\begin{align*}
  \text{Let}~R_{X,i} & \equiv
    X\rightarrow u_{i,0}Y_{i,0}\ldots{}u_{i,k_i}Y_{i,k_i}u_{i,k_i+1}
  \\\phi & \equiv \bigwedge_{X\in N}
    \left(\bigvee_{R_{X,i}\in\mathcal{R}}
          \bigwedge_{j=0}^{k_i}c_{Y_{i,j}}\right)
    \implies c_X
  \\& \equiv \bigwedge_{X\in N}
    \neg\left(\bigvee_{R_{X,i}\in\mathcal{R}}
              \bigwedge_{j=0}^{k_i}c_{Y_{i,j}}\right)
    \vee c_X
  \\& \equiv \bigwedge_{X\in N}
    \left(\bigwedge_{R_{X,i}\in\mathcal{R}}
          \neg\bigwedge_{j=0}^{k_i}c_{Y_{i,j}}\right)
    \vee c_X
  \\& \equiv \bigwedge_{R_{X,i}\in\mathcal{R}}
          \left(\bigwedge_{j=0}^{k_i}c_{Y_{i,j}}\right) \implies c_X
\end{align*}

\begin{enumerate*}
  \item[~] Suppose we find a minimal satisfying assignment
    $\mathcal{A}\vdash\phi$.
  \item[$\iff$] $\mathcal{A}$ assigns as few variables positively as possible
    whilst still satisfying $\phi$.
  \item[$\implies$] $\mathcal{A}$ assigns only $\{c_Y : Y\in C\}$ positively.
\end{enumerate*}

$\phi$ is in fact a Horn formula (a formula in conjunctive normal form in which
each conjunct contains at most one positive literal). As a result, it is
possible for us to find such a (unique) minimal $\mathcal{A}$, in linear time
using unit propagation: an algorithm referred to as \textsc{HornSAT}. The
implementation of this algorithm is given in Section\ \ref{app:horn-sat} of the
Appendices, for completeness. A proof of correctness may be found
in\ \cite[Theorem~(1.8)~pp67--68]{Huth:2004:LCS:975331}, from which the
minimality and uniqueness of $\mathcal{A}$ follow as corollaries.

\begin{figure}[htbp]
  \caption{\textit{Contribution}. Almost all of the work is performed by the
    \textsc{HornSAT} routine: It performs the reduction from rules in a grammar
    to an instance of Horn SAT, before repeatedly applying unit propagation to
    reach a minimal satisfying assignment, represented as a set of
    non-terminals.\\\\
    As in the reachability algorithm (Figure~\ref{list:reach}), for the sake of
    efficiency, we do not explicitly create the propositional formula we are
    reducing to, but instead produce a graph representation of the grammar,
    elaborated in detail in Section~\ref{app:cfg} of the Appendices.}

  \input{aux/contribution.tex}
\end{figure}

## Parsing CRF Grammars

Parsing is another important subroutine utilised by Angluin's \textit{k-bounded}
algorithm. We can take advantage of the fact that the grammars we learn will
always be in CRF, and use the CYK parsing algorithm, as found
in\ \cite{kasami1965efficient} for this task. It is most popularly depicted as a
dynamic programming algorithm for testing whether a grammar
$G=(N,\Sigma,\mathcal{R},S)$ generates a string $w\in\Sigma^*$ in
$\Theta({\lvert{}w\rvert}^3\lvert G\rvert)$ time, where $G$ is in Chomsky
\textit{normal} form. We instead present a variant for loosened CRF grammars, in
which we treat terminals in branch rules as rules that always yield themselves.

\begin{figure}[htbp]
  \caption{Tabulation scheme for \textsc{CYK}. We take $\llbracket P\rrbracket$
    to denote the truth value of the proposition $P$, similar to an indicator
    function for truth values.}\label{fig:cyk-tab}
  \begin{align*}
    \textsc{CYK}[i;j;X] & \coloneqq\llbracket X\Rightarrow^*w_{j,j+i}\rrbracket
    \tag*{$0 < i\leq\lvert w\rvert, 0\leq j <\lvert w\rvert,X\in N\cup\Sigma$}
    \\ \textsc{CYK}[1;j;X] & \coloneqq
    {\llbracket X\rightarrow w_j\in\mathcal{R}\rrbracket}^{(1)}
    \tag*{$X\in N$}
    \\ \textsc{CYK}[1;j;X] & \coloneqq
    \llbracket X = w_j \rrbracket
    \tag*{$X\in\Sigma$}
    \\ \textsc{CYK}[i;j;X] & \coloneqq
    \bigvee_{\substack{0 < k < i,\\X\rightarrow YZ\in\mathcal{R}}}^{(2)}
    \textsc{CYK}[k;j;Y]\wedge^{(3)}\textsc{CYK}[i-k;j+k;Z]
  \end{align*}
\end{figure}

From the tabulation scheme in Figure\ \ref{fig:cyk-tab} we see that:
\begin{itemize*}
\item Each cell $\textsc{CYK}[i;j;X]$ is \textbf{true} when we can derive the
  substring of $w$ of length $i$ starting at offset $j$ from $X$ in $G$.
\item The value at $\textsc{CYK}[\lvert w \rvert;0;S]$ tells us whether $G$
  generates $w$.
\item We must memoize cells in increasing order of $i$.
\end{itemize*}

\begin{figure}[htbp]
  \caption{\textit{Generalised CYK}.}\label{list:cyk}
  \input{aux/cyk.tex}
\end{figure}

Our implementation of this algorithm (Figure\ \ref{list:cyk}) will be
generalised so that we can determine more than just whether $G$ generates
$w$. This generalisation follows naturally from replacing the operations
annotated numerically in Figure\ \ref{fig:cyk-tab} with higher order functions
in Figure\ \ref{list:cyk} as follows:

\begin{enumerate*}
  \item becomes \texttt{->leaf}
  \item becomes \texttt{merge-fn}
  \item becomes \texttt{->branch}
\end{enumerate*}

Additionally, rather than passing a grammar to the routine, we pass collections
of \texttt{branches} and \texttt{leaves}, as well as a \texttt{rule} function to
extract a rule from an element of either of the aforementioned collections. The
rationale behind this is that it allows specialisations of this algorithm to
annotate rules with extra information which is then accessible by the
\texttt{merge-fn}, but using \texttt{rule}, the algorithm can extract the
structural information it needs to detect whether a particular derivation step
can be taken.

This generalisation is relevant to us because it allows us to define a function
that returns all the parse trees of $G$ that yield $w$, which we can give to
our \textsc{Diagnose} routine in the event of a false-positive conter-example.
The needed specialisation is given in (Figure\ \ref{list:parse-trees}).

\begin{figure}[htbp]
  \caption{ \textsc{ParseTrees} implementation. Returns all parse trees for a
    grammar $G$ yielding a string $w$ encoded as a tree $t$ containing two types
    of node: $[X,x]$ \textit{non-terminal yield} nodes and $[X\rightarrow YZ]$
    \textit{rule} nodes. The root is $[S,w]$, and in any path through the tree,
    node types strictly alternate.\\\\$[X\rightarrow YZ]$ nodes have two
    children: $[Y,y]$ and $[Z,z]$, and yield $yz$.\\ $[X,x]$ nodes have children
    $[X\rightarrow\alpha]$ yielding $x$ \\ $[X,x]$ nodes must have at-least one
    child unless $|x| = 1$.  }\label{list:parse-trees}
  \input{aux/parse_trees.tex}
\end{figure}

## Implementation {#sec:implementation}

The \textit{Clojure} implementation of Angluin's algorithm will be, for the most
part, a faithful translation of the pseudo-code found in
Section\ \ref{sec:k-bounded-algo} although in parts we will modify it to take
advantage of the simplifications previously discussed. We omit the
implementation of \textsc{Learn} here as it will be covered in detail in later
sections, where it is modified for use by a human oracle in different ways.
Instead, in this section, we focus upon the parts of the implementation that
remain the same across all variants of the algorithm.

\begin{figure}[htbp]
  \caption{\textsc{Candidate} implementation.}\label{list:candidate}
  \input{aux/candidate.tex}
\end{figure}

Firstly, as suggested in Section\ \ref{sec:k-bounded-restrict}, this
implementation forgoes the $k$ parameter, and always generates loosened CRF
grammars. We affect this change by ensuring that the \textsc{Candidate} routine
always returns either \textit{leaf} or (loosened)\ \textit{branch} rules
(Figure\ \ref{list:candidate}).

\begin{figure}[htbp]
  \caption{Initialisation of the learning algorithm.}\label{list:init-g}
  \input{aux/init_g.tex}
\end{figure}

We have also made the decision to initialise our candidate grammar with all
possible rules (Figure\ \ref{list:init-g}), instead of no rules at all. This
does not change the behaviour of the algorithm, as given the oracle we will
develop, Angluin's original algorithm would have spent the first few iterations
adding the same rules. And, a benefit of this modification is that we can then
introduce a new invariant: A false-negative counter-example $c_{-}$, from the
oracle implies the oracle made a mistake. This arises because initially, all the
rules were in the grammar, so if $c_{-}$ cannot be generated, it is because the
oracle caused the wrong rule to be removed. We will use this fact later when
improving the algorithm's performance in the face of errors.

\begin{figure}[htbp]
  \caption{\textsc{Diagnose} implementation.}\label{list:diagnose}
  \input{aux/diagnose.tex}
\end{figure}

Another avenue for modification is in ensuring that once the oracle provides a
counter-example, the grammar is modified in such a way that the oracle will not
produce that counter-example again, unless a mistake is subsequently made. The
termination argument in\ \cite{angluin1987learning} shows that the original
algorithm guarantees such a treatment of false-negative counter-examples, but we
can improve the way false-positives are handled w.r.t. minimising future oracle
queries:

When faced with a false-positive counter-example, $c_+$, we do not find just one
parse tree to diagnose for a bad rule. Instead, we maximise the information that
can be gained from $c_+$ by finding \textit{all possible} parse trees, and
diagnosing each one individually, to get a bad rule from each
(Figure\ \ref{list:diagnose}). Parse trees are given to \textsc{Diagnose} in the
format returned by \texttt{parse-trees} (Figure\ \ref{list:parse-trees}).

This technique proves particularly useful as the intermediate grammars produced
by this learning algorithm tend to be highly ambiguous, leading to many possible
parses for any one string.

With the framework of the algorithm implemented, all that remains is to provide
an interface to the user to act as oracle, in the form of implementations of the
$\textsc{counter*}^*$ and $\textsc{member*}^*$ functions, which we will cover in
the coming sections.

# Counter-examples from Samples {#sec:counter-samples}

To be able to reliably answer equivalence and counter-example queries directly,
requires an unreasonable expectation upon the user. To do so, they would have to
analyse the grammar themselves, locate an erroneous rule, and construct a
counter-example highlighting this fact to the algorithm in such a way that the
algorithm removes the offending rule. Even if we prune the grammar of redundant
rules (as we do), this is a time consuming task.

\begin{figure}[htbp]
  \caption{Sample based implementation of $\textsc{Counter}^*$. Note that we
    have separated the concern of getting the user's response from the main
    routine. This will facilitate the use of a test harness.}
  \label{list:counter}
  \input{aux/interactive_counter.tex}
\end{figure}

To mitigate some of the complexity of this task, we will hide the grammar from
the user (Figure\ \ref{list:counter}), and instead rely upon:

\begin{description}
  \item[A Corpus] $C$, of strings from the target language. Provided as a
    parameter at the beginning of the learning routine, and used to detect
    false-negative counter-examples: When a counter-example is requested, if
    some $w\in C$ is not recognised by the grammar, then $w$ is returned.
  \item[Samples] of strings from the language of the grammar a counter-example
    is being requested for. After the corpus has been checked, the sample is
    generated by the counter-example routine and presented to the user. They are
    expected to inspect the sample and indicate which string $w$ (if any) does
    not belong in the target language. $w$ is then provided as a false-positive
    counter-example.
\end{description}

With the introduction of sampling, even if our user provides accurate answers (a
tall order in and of itself), we can no longer guarantee the oracle will always
provide perfect responses to equivalence queries: It is possible that even if
the grammar's language does not match the target, all the strings in the sample
are also in the target language. If this is the case, the algorithm will
terminate and return the wrong grammar. This is a cost we shoulder gladly for
the weight it takes off the user, especially as we can increase our confidence
with larger sample sizes.

All that remains is for us to implement a routine to perform the sampling. This
will take some careful thought: Context-free languages being potentially
infinite, we cannot fall back on sampling uniformly. Indeed it is in our
interests to favour shorter strings, as those will be easier for the user to
check.

## Enumerating a Context-Free Language {#sec:enumerate}

We could produce a sample of $n$ short strings by enumerating the
language in length order, and picking a string at a rate of 1 in $r$ until we
have $n$. We use $r$ to change the number of strings we consider:
\begin{align*}
  \text{Let } S_n & = \text{\#strings in language considered}
  \\ \mathbb{E}[S_0] & = 0
  \\ \mathbb{E}[S_n] & = 1 + {\frac{1}{r}}\mathbb{E}[S_{n-1}]
                           + (1-{\frac{1}{r}})\mathbb{E}[S_n]
  \\ & = r + \mathbb{E}[S_{n-1}]
  \\ & = nr
\end{align*}
This form of sampling is already available to us in the form of \textit{stream
  sampling} in the\ \cite{bigml_sampling} sampling library, but we must devise
an efficient way to enumerate the language of a context-free grammar in length
order.

One method we might try is to enumerate parse trees. Enumerating $L(G)$ where
$G=(N,\Sigma,\mathcal{R},S)$ using this approach is equivalent to traversing the
\textit{derivation graph} of G by breadth-first search, starting at $v_S$
and outputting $w\in\Sigma^*$ when we visit $v_w$.
\begin{definition}[Derivation graph]\label{def:deriv-graph}
  A graph $D$ s.t.
  \begin{align*}
    V(D) & = \{v_\alpha : \alpha\in(\Sigma\cup N)^*\}\\
    E(D) & = \{(v_\alpha,v_\beta) : \alpha \Rightarrow_l \beta\}
  \end{align*}
\end{definition}
If $G$ is in CRF --- as it will be in our case --- this approach will produce a
sequence in length order. However, in cases where each non-terminal has more
than one production, the frontier of the search will grow exponentially with
respect to the depth. Furthermore, in cases where $G$ is ambiguous, this
strategy will return a sequence with repetitions. All in all, this routine is
not ideal for our needs.

Instead we will enumerate $\Sigma^*$ in length order, and for each
$w\in\Sigma^*$, check if $w\in L(G)$: If it is, output it, if not continue. This
simultaneously ensures that the sequence will be in length order, and will
contain each string only once. Having to check each $w\in\Sigma^*$
seems potentially inefficient, however by adapting a parsing algorithm, it is
possible to re-use work from previous strings.

### A Modified Earley Parser

The Earley parser\ \cite{Earley:1983:ECP:357980.358005} is a dynamic programming
algorithm capable of recognising any context-free grammar. In its simplest form,
it is a recogniser, that when given a grammar $G$ and a string $w$, will decide
whether $w\in L(G)$. Like the CYK algorithm we described earlier, it can also be
adapted to return a parse tree, although we are more interested in inverting its
behaviour so that instead of recognising strings in the language, it outputs
them. But first, let us see its inner workings.

\begin{figure}[htbp]
  \caption{Data structure representing an Earley item. \texttt{deriv-len} and
    \texttt{toks} are augmentations to allow for the calculation of the
    derivation length for a word $w$ and the language sequence of a grammar $G$
    respectively.}\label{list:earley-item}
  \input{aux/earley_item.tex}
\end{figure}

An Earley parser keeps track of a state set: $S_k$ for each boundary between
symbols in the input, $0 \leq k \leq \lvert w \rvert$ that it has crossed so
far. Each state set contains \textit{Earley items}
(Figure\ \ref{list:earley-item}) of the form
$(X\rightarrow\alpha\bullet\beta,i)$, for a rule $X\rightarrow\alpha\beta$, a
position in the rule ($\bullet$) splitting the symbols that have already been
matched (to the left of it) and the symbols still expected (to the right of it),
and an origin position $i$ for the boundary at which the rule started being
matched.

\begin{figure}[htbp]
  \caption{Earley States, implemented as queues.}\label{list:earley-states}
  \input{aux/earley_state.tex}
\end{figure}

\begin{figure}[htbp]
  \caption{Constraints satisfied by state sets. $S^\prime$ is a nominal start
    non-terminal that we add so that we can say $w\in L(G)$ iff
    $(S^\prime\rightarrow{}S\bullet,0)\in{}S_{\lvert
      w\rvert}$.}\label{fig:earley-states}
  \begin{align*}
    S_0 & = \{(S^\prime\rightarrow\bullet S,0)\}\\[3mm]
    (X\rightarrow\alpha\bullet y\beta, i)\in S_k,~w_k = y^{(1)}
      & \implies (X\rightarrow\alpha y\bullet\beta, i)\in S_{k+1}
      \tag{Shift}\\[3mm]
    (X\rightarrow\gamma\bullet, i)\in S_k
      & \implies \forall(Y\rightarrow\alpha\bullet X\beta, j)\in S_i
      \tag{Reduce}\\
      & \qquad\qquad (Y\rightarrow\alpha X\bullet\beta, j)\in S_k\\[3mm]
    (X\rightarrow\alpha\bullet Y\beta ,i)\in S_k,~Y\in N
      & \implies \forall Y\rightarrow\gamma\in\mathcal{R}
      \tag{Predict}\\
      & \qquad\qquad (Y\rightarrow\bullet\gamma, k)\in S_k
  \end{align*}
\end{figure}

In our implementation (Figure\ \ref{list:earley-parser}), we will represent the
state sets $S_k$ as queues (Figure\ \ref{list:earley-states}). We will create
them in increasing order of $k$, being careful not to re-add items that we have
already processed (Figure\ \ref{list:earley-parser},\ Lines 8--9), as this will
cause an infinite loop. We will also avoid storing all previous state
sets. Instead it suffices for us to keep track of the state set we are working
on, and all previous \textit{reduction mappings} $R_j$ from non-terminals $X$,
to items $(Y\rightarrow\alpha\bullet X\beta, i)\in S_j$, waiting for reductions
of items with rules from $X$ starting at $k$. Then, when we perform a
\textit{reduction} of an item $(X\rightarrow\gamma\bullet,j)$, we simply take
all the items in $R_j(X)$, advance their rule position, and add them to $S_k$,
this also saves us the trouble of searching $S_j$ for rules of the correct form.

\begin{figure}[htbp]
  \caption{Implementation of language sequence.}\label{list:lang-seq}
  \input{aux/lang_seq.tex}
\end{figure}

From this implementation of the recogniser, we can create a routine that
generates all strings in the language (Figure\ \ref{list:lang-seq}) with the
following modifications:
\begin{itemize*}
  \item Change condition (1) of the \textit shift rule in
    Figure\ \ref{fig:earley-states} to $y\in\Sigma$. In other words, when we
    encounter a terminal symbol, we will shift it indiscriminately to advance
    our traversal.
  \item Augment Earley items with the sequence of terminals they have matched.
    Whenever we shift over a terminal, as well as advancing the position in the
    rule, add the terminal to this sequence.
  \item Keep a mapping $C_k$ for each boundary position $k$ from origin
    positions $i$ and non-terminals $X$ s.t. $C_k(i,X)$ is the set of strings
    yielded by derivations from $X$ starting at boundary $i$ and ending at
    boundary $k$. Whenever we reduce one of our augmented items,
    $(X\rightarrow\gamma\bullet,i,w)$ at step $k$, we ensure $w\in C_k(i,X)$.
  \item We no longer have a parameter $w$ over which we may iterate, so instead
    we will keep generating $S_k$ for larger and larger $k$ until we produce an
    empty state set. When this happens it is safe to terminate as we know that
    we cannot generate any further strings in the language after this. Note that
    for an infinite language this will never happen.
\end{itemize*}
\begin{align*}
  \intertext{Observe that}
  C_k(0,S^\prime) & = \{w\in L(G) : \lvert w \rvert = k\}\\
  \intertext{So we may construct the language as}
  L(G) & = \bigcup_{k \geq 0}C_k(0,S^\prime)
\end{align*}
Furthermore, we may iterate $L(G)$ in length order by iterating through each
$C_k(0,S^\prime)$ in increasing order of k.

\begin{figure}
  \caption{An augmented Earley Parser. Given a state $S_{k-1}$ and an index $k$,
    returns a new state. Here the state is represented by a queue of items to
    process, the reduction mapping, and the completion mapping
    (Figure~\ref{list:earley-states}). The condition that decides whether to
    shift over a terminal is abstracted into the \texttt{shift?} predicate so
    this function can be used in a fold to either recognise a string or
    enumerate the language sequence.}\label{list:earley-parser}

  \input{aux/token_consumer.tex}
\end{figure}

### Nullability and \textsc{HornSAT}

\cite{journals/cj/AycockH02} highlights an issue with Earley's implementation
in \cite{Earley:1983:ECP:357980.358005}, when faced with \textit{nullable}
non-terminals.

\begin{definition}[Nullable]
  Given a grammar $G=(N,\Sigma,\mathcal{R},S)$, a non-terminal $X\in N$ is
  nullable iff $X\Rightarrow^*\varepsilon$, or equivalently, the set of nullable
  terms $N^\varepsilon\subseteq N$ can be defined recursively in terms of
  itself:
  \begin{align*}
    X\rightarrow Y_0\ldots Y_k\in\mathcal{R}
    \wedge \{X\} \nsubseteq \{Y_i\}_i \subseteq N^\varepsilon
    \implies X \in N^\varepsilon
    \tag*{$k\geq 0$}
  \end{align*}
\end{definition}

The solution given is, when predicting a nullable non-terminal, to also move the
rule position over it in the rule which originates it. However, in order to do
this we must be able to compute the set of nullable non-terminals.

Like our strategy in Section\ \ref{sec:contribution}, we turn to propositional
logic to guide us. For each $X\in N$, take $n_X$ to be a propositional variable,
then we may construct a $\phi$ s.t. for an assignment $\mathcal{A}$,
$\mathcal{A}\not{\vdash}\phi$ iff $n_Y \mapsto 0\in\mathcal{A}$ for some $Y\in
N^\varepsilon$:
\begin{align*}
  \text{Let } R_{X,i} & \equiv X \rightarrow Y_{i,0}\ldots Y_{i,k_i}\\
  \phi & \equiv \bigwedge_{X\in N} \left(
  \bigvee_{R_{X,i}\in\mathcal{R}} \bigwedge_{j=0}^{k_i} n_{Y_{i,j}}
  \right) \implies n_X\\
  & \equiv \bigwedge_{R_{X,i}\in\mathcal{R}}
  \left( \bigwedge_{j=0}^{k_i} n_{Y_{i,j}}\right)
  \implies n_X
\end{align*}
$\phi$ is a Horn formula, so once again, a minimal satisfying assignment of
$\phi$ (returned by \textsc{HornSAT}) can be translated naturally into
$N^\varepsilon$.

This is remarkably similar to our approach to calculating the set of
\textit{contributing} non-terminals. In fact, all that we must change is to
remove all rules containing terminals before applying \textsc{HornSAT}, as in
Figure\ \ref{list:null}.

\begin{figure}[htbp]
  \caption{An implementation of nullability using
    \textsc{HornSAT}.}\label{list:null}
  \input{aux/null.tex}
\end{figure}

### Algorithm

We put everything together to get our sampling routine
(Figure\ \ref{list:enum-sampling}).

\begin{figure}[htbp]
  \caption{Sampling in length order.}
  \label{list:enum-sampling}
  \input{aux/enum_sampling.tex}
\end{figure}

We have (arbitrarily) chosen to pick elements from the language sequence at a
rate of $1:n$. Empirically, this seems to provide good results with the expected
number of strings considered being $n^2$. However, this does result in an
$\Omega(n^2)$ worst-case expected time complexity w.r.t. only $n$. This is
particularly a problem with the types of grammars produced by our learning
routine --- highly ambiguous loosened CRF grammars --- which approach the
worst-case, making this routine impractical for use with our algorithm.

## Sampling from an SCFG

Something else we might try is to sample derivations from an SCFG with the same
rules as our candidate grammar (Figure\ \ref{list:scfg-sample}). This is
equivalent to performing a random walk through the derivation graph of the
grammar (Definition\ \ref{def:deriv-graph}), starting at $v_S$ and terminating
at some $v_w$ where $w\in\Sigma^*$. This avoids the earlier problem of
exponential blow-up in the frontier we would have faced when performing a
breadth-first search of the derivation graph by traversing only one path at a
time: If we want $n$ samples we simply perform $n$ such walks. The slow-down
that the previous sampling routine experienced for larger sample sizes is also
avoided, as the order of growth w.r.t only $n$ is $O(n)$.

\begin{figure}[htbp]
  \caption{Sampling from an SCFG.}\label{list:scfg-sample}
  \input{aux/scfg_sample.tex}
\end{figure}

## Strong Consistency

Then the question becomes, which SCFG? Ideally we would pick one which favours
short strings. This is important not only to the user, but also in ensuring that
the sampling routine terminates. In fact, certain grammars (those in which rules
that introduce non-terminals have high probability) will cause the algorithm to
diverge and become stuck following an infinite length derivation.

\begin{figure}[htbp]
  \caption{Sampling a CFG as an SCFG.}\label{list:sc-sample}
  \input{aux/sc_sample.tex}
\end{figure}

\cite{Gecse2010490} offers a solution to this problem in their algorithm which,
given any SCFG, returns a grammar with the same language, but that is strongly
consistent. To use it, we must transform our candidate grammar
$G=(N,\Sigma,\mathcal{R},S)$ into an SCFG $G^\prime=(G,p)$, which we may do by
assigning probabilities uniformly (Figure\ \ref{list:sc-sample}):
\begin{align*}
  p_X(\alpha) & = \frac{1}{Z_X}
  \tag*{$\forall X\rightarrow\alpha\in\mathcal{R}$}
  \\ Z_X & = \abs{\{X\rightarrow\alpha\in\mathcal{R}\}}
\end{align*}

\begin{definition}[Strongly Consistent]
  An SCFG is strongly consistent when its expected string length is finite. In
  other words, sampling a strongly consistent grammar, as in
  Figure\ \ref{list:scfg-sample}, is guaranteed to terminate.
\end{definition}

The grammar is made strongly consistent using gradient descent. First, we check
whether it is strongly consistent already, if not, we pick the \textit{best
  rules} --- Rules that will reduce the expected word length when favoured ---
and increase their probability by a fixed scale factor, and repeat
(Figure\ \ref{list:sc*}).

\begin{figure}[htbp]
  \caption{Making a grammar strongly consistent}\label{list:sc*}
  \input{aux/make_strongly_consistent_star.tex}
\end{figure}

### \textsc{BestRules}

The best rules to promote when trying to reduce the expected word length are the
ones with the lowest \textit{hop count}. We must pick at least one such rule for
each non-terminal.

\begin{definition}[Hop count]
  Given a rule $X\rightarrow\alpha$, its hop count is the length of the shortest
  derivation $\alpha\Rightarrow^*w\in\Sigma$.
\end{definition}

We find these rules by calculating the hop counts for each
\textit{non-terminal}. From these we can calculate the hop counts of every rule
as the sum of the hop counts of the non-terminals they mention plus one. Then we
may pick the rules with the lowest hop count for each non-terminal.

There is an algorithm for this in \cite{Gecse2010490}, however, here I suggest
an improvement based on a generalisation of Dijkstra's algorithm
(Algorithm\ \ref{algo:hop-counts}).

\begin{algorithm}[htbp]
  \caption{Finding the hop counts for non-terminals. See
    Section\ \ref{app:best-rules} for a translation into \textit{Clojure}, along
    with an implementation of \textsc{BestRules}.}\label{algo:hop-counts}
  \begin{algorithmic}
    \Function{HopCounts}{$G=(N,\Sigma,\mathcal{R},S)$}
      \LineComment $C$, the mapping from non-terminals to finalised hop counts.
      \State $C \gets \varnothing$
      \State
      \LineComment $Q$, the priority queue of non-terminals ordered by
        prospective hop counts.
      \State $Q \gets \varnothing$
      \State
      \LineComment Removing self-looping rules (these can never be the best
        rule).
      \State $\mathcal{R} \gets \mathcal{R}\setminus
             \{X\rightarrow\alpha X\beta
             : X\in N, \alpha,\beta\in(\Sigma\cup N)^*\}$
      \State
      \LineComment $V$, the mapping from rules to \#unfinalised non-terminals in
        the rule.
      \State $V \gets \{R\mapsto \abs{\{Y_i\}_i}
             : (X\rightarrow u_0Y_0\ldots u_kY_ku_{k+1}) = R\in \mathcal{R}\}$
      \State
      \ForAll{$X\in N$}
        \If{$X\rightarrow w\in\mathcal{R},w\in\Sigma^*$}
          \State \Call{Insert}{$Q$, $X$, $0$}
        \Else
          \State \Call{Insert}{$Q$, $X$, $\infty$}
        \EndIf
      \EndFor
      \State
      \While{$\lnot\Call{Empty}{Q}$}
        \State $(X,h) \gets \Call{Pop}{Q}$
        \State \algorithmicif $X\in Dom(C)$ \algorithmicthen \textbf{ continue}
        \State $C\gets C\oplus\{X\mapsto h\}$
        \For{$Y\rightarrow\alpha X\beta = R \in \mathcal{R}$}
          \State $V[R] \gets V[R] - 1$
          \If{$V[R] = 0$}
            \State \textbf{let} $c = \sum_{Z\in N\text{ mentioned in }R}C[Z]$
            \If{$c < Q[Y]$}
              \State \Call{Insert}{$Q$, $Y$, $c$}
            \EndIf
          \EndIf
        \EndFor
      \EndWhile
      \State \Return{$C$}
    \EndFunction
  \end{algorithmic}
\end{algorithm}

\begin{remark}\label{rem:relax-hop}
  Observe that, in the running of Algorithm\ \ref{algo:hop-counts}, once all the
  non-terminals mentioned in the best rule of some $X\in N$ have been finalised,
  $X$ will be assigned its true hop count in $Q$, and from then on, will keep
  that value.
\end{remark}

\begin{lemma}\label{lem:hop-count-q-pop}
  When $X\in N$ is popped from $Q$, its prospective hop count, $h_X$ equals its
  true hope count, $\overline{h}_X$. Proved by induction.

  \begin{proof}[Base Case, Terminal Rules]
    Holds trivially.
  \end{proof}

  \begin{proof}[Inductive Step]
    Suppose the previous $k$ pops from $Q$ yield true hop counts (I.H.)
    and we are popping $(X,h_X)$ from $Q$.

    Let $D = X\Rightarrow^*_l w\in\Sigma^*$ be the shortest leftmost derivation
    of this form from X.

    Observe that if all non-terminals mentioned in $D$ are in $C$ then
    $h_X=\overline{h}_X$.

    Suppose for a contradiction that this is not the case, and let $Y\notin C$
    be the first such (working bottom up from terminal rules in $D$), s.t.
    $(Y,h_Y)\in Q$.
    \begin{enumerate*}
      \item[$\implies$] All of the non-terminals in $Y$'s best rule are in $C$
        \hfill($Y$ is the first such)
      \item[$\implies$] $h_Y = \overline{h}_Y$
        \hfill(Remark\ \ref{rem:relax-hop})
      \item[$\implies$]
        $\overline{h}_Y = h_Y < \overline{h}_X \leq h_X$
      \item[$\overset{\text{\textreferencemark}}{\implies}$]
        $Y$ is before $X$ in $Q$.\hfill(X is the first element in Q)
      \item[$\implies$] Y cannot exist.\qedhere
    \end{enumerate*}
  \end{proof}
\end{lemma}

\begin{theorem}[Correctness of \textsc{HopCounts}]
  \textsc{HopCounts} terminates, producing a mapping from non-terminals to their
  hop counts.

  Invariant: Non-terminals in $C$ are mapped to their true hop count.
  \begin{proof}[Initialisation]
    Initially, $C = \varnothing$, so this holds vacuously.
  \end{proof}

  \begin{proof}[Maintenance]
    Follows directly from Lemma\ \ref{lem:hop-count-q-pop}.
  \end{proof}

  \begin{proof}[Termination]
    Each rule is visited precisely once, when all of the non-terminals it
    mentions have been finalised, and every non-terminal is added to $C$ at
    most once.

    \begin{enumerate*}
    \item[$\implies$] \textsc{HopCounts} is guaranteed to terminate with
      $Dom(C)=N$.
    \item[$\implies$] \textsc{HopCounts} returns the required mapping.\qedhere
    \end{enumerate*}
  \end{proof}
\end{theorem}

# Techniques to Reduce Membership Queries {#sec:membership}

\begin{figure}[htbp]
  \caption{An interactive implementation of
    $\textsc{Member}^*$.}\label{list:int-member}
  \input{aux/interactive_member.tex}
\end{figure}

In the case of $\textsc{Member}^*$, it is reasonable (and necessary) to pose the
query directly to the user (Figure\ \ref{list:int-member}). A user who knows the
non-terminals that comprise a grammar should also be able to tell, given a
non-terminal $X$ and a string $w$, whether $X \Rightarrow^* w$ holds in their
target grammar. Apart from the fact that \texttt{:S} represents the start state
(by convention), the semantics of other non-terminals is known only to the
user. It is this semantic information that the answers to non-terminal
membership queries rely upon, which is why the query must be posed directly.

However, we can aim to minimise the number of membership queries we make, by not
asking the same question multiple times.

# Analysis

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

Analysis seems to suggest that our changes yield improvement by a constant scale
factor. This, by definition, does not change the asymptotic complexity, but as
the number of queries the algorithm needs increases exponentially with the error
of the oracle, this represents a real practical benefit. For complex grammars,
and most practical uses, the number of queries is still perhaps too high, but in
this section we discuss some ways we can improve this state of affairs, and some
other avenues worth exploring.

## Ambiguity

Our algorithm only removes rule when it is used in the parse of a false-positive
string. A consequence of this, is that it favours ambiguous grammars: if
multiple rules generate good strings, they are all kept. Unfortunately, most
practical uses of CFGs require them to be unambiguous and disambiguation is
undecidable in general, but this property offers an interesting benefit: Even if
we have a grammar in mind for our language, running this algorithm may highlight
various other rules that we could use to get the same effect. For example, when
given the non-terminals and language of a right-linear grammar, the returned
grammar will also contain the rules for the left-linear version.

## Choosing Non-Terminals {#sec:choosing-nts}

We expect the user to provide the names of all the non-terminals they expect
their target language to have. This requires a fairly intimate knowledge of the
language, which may be the very thing they are trying to discern with the
learning routine and it may be possible to aid the user in this choice, to ease
the burden.

One possible avenue is to take advantage of the regular binary tree structure of
parse trees from CRF grammars. Given a corpus of strings known to be in the
language, we can have the user recursively split the strings in half, to give a
parse tree. From these parse trees, we would not only get the set of
non-terminals, but an indication of which rules to favour, which we can seed our
classifier with, to speed up the learning process.

## Component Analysis

A technique used in\ \cite{Gecse2010490}, to improve the performance of their
algorithm, is to split an SCFG $G=(N,\Sigma,\mathcal{R},S,p)$ into sub-grammars
according to its strongly connected components (SCCs).
\begin{align*}
  \text{Let }\llbracket X\rrbracket & \coloneqq \text{SCC containing X}
  \tag*{$\forall X\in N$}
  \\ Y\in\llbracket X \rrbracket &
  \iff X\Rightarrow^*\alpha Y\beta
  \land Y\Rightarrow^*\gamma X \delta
  \tag*{$\exists.\alpha,\beta,\gamma,\delta\in(\Sigma\cup N)^*$}
\end{align*}
This definition parallels the graph theoretic notion of SCCs as applied to the
inverted graph representation of CFGs elucidated in Section\ \ref{app:cfg}. It
is this graph which we use to find the SCCs for the strong consistency
algorithm, using the procedure found in Section\ \ref{app:scc}.

The advantage in splitting the grammar, when trying to encourage strong
consistency is that if $X$ and $Y$ are in different SCCs $C_X$ and $C_Y$,
inducing sub-grammars $G_X$ and $G_Y$ respectively, and there is a rule
$X\rightarrow\alpha Y\beta\in\mathcal{R}$, then it can be replaced by a new
rule: $X\rightarrow\alpha\tau\beta\in\mathcal{R}_X$ for a fresh terminal
$\tau\notin\Sigma$. This signifies that when we make $G_X$ strongly consistent,
we can assume that the expected length of derivations from $Y$ will be finite,
because we will be making $G_Y$ strongly consistent, and this can be done
without ever considering $G_X$.

We have employed a similar technique in Section\ \ref{sec:loosen} by replacing
non-terminals that produce only one terminal with the terminal itself, but we
could go further.

Consider the grammars of programming languages which can be split up into
distinct components that live in their own strongly connected component. For
example, it is quite common in imperative languages, for statements to contain
expressions, but not vice versa. In cases such as these, we could lessen the
load on the algorithm by learning these two structures separately. When learning
the structure of a statement, we use a terminal symbol to represent where an
expression may appear, and when we join the structures together, this becomes a
non-terminal.

The difficulty in implementing this, is that whilst the strong consistency
algorithm could calculate the SCCs of the grammar it is given, we do not have a
grammar, and while in certain situations, dependancies of this kind may be part
of the specification, for other grammars, we can only guess at what the SCCs
could be. In either case, the job of identifying SCCs lies with the user.

# Acknowledgements

words

# References

\bibliography{references}

# Appendix A <!-- Subsidiary Listings -->

## Representing CFGs {#app:cfg}

<!--
mention inverted representation,
and its uses in HornSAT and Best Rules.
-->

## Representing SCFGs

words
<!--
Mention mutable SCFGs
-->

## \textsc{HornSAT} {#app:horn-sat}

words

## Ancillary Definitions for Earley Parser {#app:ancillary-earley}

<!--
reset-state
classify
shift / perform-shift / enqueue-shift
perform-reduxns / complete-item
reduxn-key / associate-reduxn
processed-key
-->

## Ancillary Definitions for Strong Consistency {#app:ancillary-sc}

### Best Rules {#app:best-rules}

## Strongly Connected Components {#app:scc}

words

# Appendix B <!-- Tests -->

test
