```{.clojure .numberLines}
(defn best-rules [g]
  (let [counts (hop-counts g)
        rule-hop
        (fn [rule]
          (if-let [nts (seq (filter non-terminal? rule))]
            (->> nts (map counts)
                 (reduce +) inc)
            0))]
    (map-kv*
      (fn [nt rs]
        (let [hops (get counts nt)]
          (->> rs
               (filter #(= hops (rule-hop %)))
               (into #{}))))
      g)))
```
