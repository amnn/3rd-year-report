``` {.clojure .numberLines}
(defn reachable-nts
  "Returns the non-terminals we can reach from a given symbol `nt`. If `nt` is
  not provided, it is assumed to be `:S`."
  ([g] (reachable-nts g :S))

  ([g nt]
   (loop [q   (queue nt)
          nts (transient #{})]
     (if (seq q)
       (let [current-nt (peek q)]
         (if-not (nts current-nt)
           (recur (into (pop q)
                        (->> (get g current-nt)
                             (mapcat #(filter non-terminal? %))))
                  (conj! nts current-nt))
           (recur (pop q) nts)))
       (persistent! nts)))))
```
