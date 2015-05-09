```{.clojure .numberLines}
(defn- remove-self-loops [g]
  (map-kv* (fn [nt rs]
             (->> rs
                  (remove #(some #{nt} %))
                  (into (empty rs))))
           g))

(defn hop-counts [g]
  (let [hop-graph (->> g remove-self-loops
                       rule-seq invert-graph)
        no-hops   #(vector % 0)]
    (loop [counts (transient {})
           q (->> (hop-graph nil)
                  (map no-hops)
                  (into (priority-map)))]
      (if-let [[nt hops] (peek q)]
        (if (get counts nt)
          (recur counts (pop q))
          (let [new-counts (assoc! counts nt hops)]
            (recur
             new-counts
             (into (pop q)
                   (for [r (hop-graph nt)
                         :let  [old-hops (get q (:nt @r))]
                         :when (or (not old-hops) (> old-hops hops))
                         :let  [{:keys [not-visited nt rule]}
                                (visit-rule r)]
                         :when (zero? not-visited)]
                     [nt (->> (filter non-terminal? rule)
                              (map new-counts)
                              (reduce +) inc)])))))
        (persistent! counts)))))
```
