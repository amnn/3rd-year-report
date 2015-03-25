```{.clojure .numberLines}
(defn klr-learn
  [K member* counter* nts ts & {:keys [entropy lr-rate prune-p]}]
  {:pre [(< 0 entropy 1) (< 0 lr-rate) (< 0 prune-p 1/2)]}

  (let [classifier  (mk-classifier K (init-weights nts ts))
        likelihoods (init-likelihoods nts ts)]
    (classifier->likelihood likelihoods classifier)
    (loop []
      (let [sg (snapshot! prune-p likelihoods)]
        (if-let [[type toks] (counter* sg)]
          (do (case type
                :+ (learn lr-rate classifier
                          (diagnose member* (ml-tree sg toks)) 0.0)
                :- (disorder! entropy classifier))
              (recur))
          sg)))))

(defn- snapshot! [p sg] (->> sg freeze! (prune-scfg p) normalize))

(defn- disorder!
  [p classifier]
  (doseq [[_ lh] (:ws classifier)]
    (swap! lh * p)))
```
