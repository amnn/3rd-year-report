```{.clojure .numberLines}
(defn- inject-error [err verbose? pred]
  (letfn [(should-err []
            (first
             (simple/sample
              [true false]
              :weigh {true err,
                      false (- 1 err)})))]
    (fn [& args]
      (let [b (apply pred args)]
        (if (should-err)
          (do (when verbose? (println "*** ERROR ***"))
              (not b))
          b)))))

(defn- inject-counter [ctr f]
  (fn [& args]
    (swap! ctr inc)
    (apply f args)))

(defn- inject-printer [prt-fn f]
  (fn [& args]
    (let [y (apply f args)]
      (prt-fn args y)
      y)))

(defn- member-print [[nt yield] ans]
  (println (str nt " =>* " yield "? " (if ans \y \n))))

(defn- counter-print [[g] ans]
  (println "counter*")
  (pprint g)
  (println (if ans (str "\t=> " ans) "DONE!")))
```
