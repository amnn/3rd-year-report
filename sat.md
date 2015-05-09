```{.clojure .numberLines}
(defn horn-sat
  "Takes a sequence of rules `rs` and returns the set of satisfying non-terminals
  for the underlying HORN-SAT formula."
  [rs]
  (let [sat-graph (invert-graph rs)]
    (loop [q   (apply queue (get sat-graph nil))
           nts (transient #{})]
      (if-let [nt (peek q)]
        (if-not (nts nt)
          (recur
           (into (pop q)
                 (->> (sat-graph nt)
                      (keep #(let [{:keys [not-visited nt]}
                                   (visit-rule %)]
                               (when (zero? not-visited) nt)))))
           (conj! nts nt))
          (recur (pop q) nts))
        (persistent! nts)))))
```
