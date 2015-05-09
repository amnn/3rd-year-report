```{.clojure .numberLines}
(defn- processed-key
  "If the rule, starting position, offset and tokens consumed are the same
  between items being processed in a single iteration, then they are the same
  item, and one can be pruned."
  [i] ((juxt :rule :start :offset :toks) i))
```
