```{.clojure .numberLines}
(defn- init-weights [nts ts]
  (into {}
        (concat
         (for [a nts, b nts, c nts]
           [[a b c] (atom 0.0)])
         (for [a nts, t ts]
           [[a t]   (atom 0.0)]))))

(defn- init-likelihoods [nts ts]
  (let [rules (concat (map list ts)
                      (for [b nts, c nts]
                        (list b c)))]
    (->> (mapcat (fn [nt] (map #(cons nt %) rules)) nts)
         (reduce (fn [sg r] (scfg/add-rule sg r 0.5)) {})
         make-mutable!)))

(defn- classifier->likelihood [sg {:keys [K ws]}]
  (doseq [[r* atm-a] ws]
    (let [likelihoods
          (for [[r lh] (scfg/rule-seq sg)
                :let [k (K r r*)]
                :when (not (zero? k))]
            [lh k])]
      (add-watch atm-a :likelihood
                 (fn [_ _ old-a new-a]
                   (doseq [[lh* k] likelihoods]
                     (swap! lh* (fn [lh]
                                  (->> (logit lh)
                                       (+ (* (- new-a old-a) k))
                                       sigmoid)))))))))

```
