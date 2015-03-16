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
the algorithm are reasonably efficient (polynomial time complexity w.r.t size,
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
\subsubsection*{\texttt{clojure.data/priority-map} \\
  \small{\cite{clojure_data_prioritymap}}}

An ordered key-value data structure sorted by its value, with a uniqueness
constraint on keys. Used in situations similar to a heap.

\phantomsection{}
\subsubsection*{\texttt{bigml/sampling} \\
  \small{\cite{bigml_sampling}}}

A library of sampling functions, for picking random elements from both finite
collections and infinite streams.

\phantomsection{}
\subsubsection*{\texttt{net.mikera/core.matrix} \\
  \small{\cite{net_mikera_core_matrix}}}

A language extension to \textit{Clojure} adding generalised N-dimensional array
programming protocols. By default these protocols are only implemented by the
standard library collections which are not well-suited to array programming
operations.

\phantomsection{}
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
      S &\rightarrow C \mid D \\
      C &\rightarrow aB \mid d \\
      D &\rightarrow aB \mid d \\
      B &\rightarrow b
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

## Algorithm

As input, the algorithm takes $N$, the set of non-terminals, $\Sigma$, the
alphabet, and $S \in N$ the starting non-terminal. From these, it attempts to
learn the productions in the target grammar.

The algorithm repeatedly requests counter-examples, and uses them to add or
remove productions from the grammar it is learning, $G^\prime$. The work done in
response to each counter-example brings $G^\prime$ closer to the target grammar,
until there are no counter-examples left, at which point it is equivalent to the
target. Pseudocode is provided in Algorithm\ \ref{algo:kbounded}, with
supporting definitions in
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

## Restriction to Chomsky Reduced Form

It is obvious, but worth mentioning, that neither $k$ nor $N$ are trivial
parameters to the algorithm: When learning some language $L$, if we fix
particular values for $k$ and $N$ we cannot be certain of the existence of a
$k$-bounded grammar that uses at most $\lvert N \rvert$ non-terminals. In fact,
if we fix some $N$ there is no guarantee that we can find a grammar recognising
the language at all, regardless of the value of $k$. Happily however, if
$L\in\mathcal{L}^{\bar \varepsilon}$, the converse does hold: If we fix the
value of $k$, we can guarantee that for some set of non-terminals $N$, there is
a $k$-bounded grammar $G=(N,\Sigma,\mathcal{R},S)$ s.t. $L(G) = L$.

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
doing so would remove the need for the parameter $k$: It would always be 2.

In fact, we can simplify the \textsc{Candidate} subroutine further than just
hard-coding $k = 2$: Because we know that rules must either be in
\textit{branch} or \textit{leaf} form, we will have the \textsc{Candidate}
routine return only such rules.

If we assume (naïvely) that the oracle always gives perfect answers, we can go
further still. A perfect oracle will never, through the answers it provides to
our algorithm's queries, cause a rule in the target grammar to be removed. As
such, we can have our algorithm cache previous responses from the oracle. Using
this technique, we can avoid adding rules we already know are bad back into the
grammar, and we can also reduce the number of queries made to the oracle. These
optimisations will yield significant improvements in our cost model.

Our restriction to CRF appears to have brought with it another restriction: Our
new algorithm only learns languages in $\mathcal{L}^{\bar\varepsilon}$. In fact,
this was added only to remove awkward case analyses, and our algorithm can be
used to learn grammars that recognise any context-free language by a
straightforward transformation.
\begin{theorem}[Completeness]
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

## Implementation

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
