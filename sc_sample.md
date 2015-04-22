```{.clojure .numberLines}
(defn sample [g n]
  (let [sg (-> g cfg->scfg make-strongly-consistent)]
    (vec (repeatedly n #(scfg-sample sg)))))
```
