```{.clojure .numberLines}
(defn- make-strongly-consistent* [rate sg]
  (let [best-ps
        (->> sg scfg->cfg
             best-rules
             (slice-ps sg)
             delay)]
    (while (not (strongly-consistent? (freeze! sg)))
      (doseq [p (force best-ps)]
        (swap! p * rate))
      (normalize! sg))))
```
