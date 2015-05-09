```{.clojure .numberLines}
(defn make-mutable!
  "Wrap probabilities in an SCFG `sg` with Atoms, so that they can be
  modified."
  [sg] (map-v (partial map-v atom) sg))

(defn freeze!
  "Freeze a mutable SCFG `sg` to its current probabilities."
  [sg] (map-v (partial map-v deref) sg))

(defn normalize!
  "Ensure that the probabilities of a mutable SCFG `sg` all sum to one
  (conditional on the non-terminal)."
  [sg]
  (doseq [[_ rules] sg
          :let [sum (->> rules
                         (map (fn [[_ p]] @p))
                         (reduce +))]
          [_ p] rules]
    (swap! p / sum))
  sg)
```
