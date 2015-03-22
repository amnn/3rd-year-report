```{.clojure .numberLines}
(defrecord ^:private Item [rule start offset deriv-len toks])
(defn- new-item [r start] (->Item r start 0 1 []))
(defn- init-items [g nt i] (map #(new-item % i) (cfg/rule-seq g nt)))
```
