```{.clojure .numberLines}
(defn sample [g n]
  (-> (lang-seq g)
      (stream/sample 1 n :rate true)
      (->> (take n) vec)))
```
