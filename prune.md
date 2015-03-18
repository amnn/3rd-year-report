``` {.clojure .numberLines}
(defn prune-cfg
  "Given a grammar `g`, remove all the rules that do not contribute to the
  language, and all the rules that are not reachable from the start symbol."
  [g]
  (let [cnts         (contributing-nts g)        ;; (1)
        contributes? (fn [rule]
                       (and (cnts (non-terminal rule))
                            (every? #(or (terminal? %) (cnts %))
                                    (pattern rule))))
        g*           (filterr contributes? g)    ;; (2)
        rnts         (reachable-nts g*)]
    (filterr (comp rnts non-terminal) g*)))      ;; (3)
```
