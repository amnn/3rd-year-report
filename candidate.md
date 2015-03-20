``` {.clojure .numberLines}
(defn- candidate
  [nts blacklist toks]
  (for [t toks, nt nts,
        :let  [leaf [nt t]]
        :when (not (blacklist leaf))]
    leaf))
```
