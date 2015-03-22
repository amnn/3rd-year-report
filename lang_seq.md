```{.clojure .numberLines}
(defn lang-seq [g]
  (let [nullable?     (nullable g)
        g             (null-free g)
        consume-token (token-consumer g nullable? (constantly true))
        init-state    (initial-state (nullable? :S))

        [active-states idle-states]
        (->> (reductions consume-token init-state (range))
             rest (split-with (comp not empty? :items)))]
    (->> (concat active-states (take 1 idle-states))
         (mapcat #(get-in % [:complete success-key]))
         (map first))))
```
