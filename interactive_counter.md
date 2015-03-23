```{.clojure .numberLines}
(defn sample-counter
  ([n corpus] (sample-counter n corpus present-samples))

  ([n corpus sample-tester]
   (fn [g]
     (let [il? (in-lang g)]
       (if-let [false-neg (->> corpus
                               (filter (complement il?))
                               first)]
         false-neg
         (sample-tester
          (stream-sample g n)))))))

(defn present-samples [samples]
  (println "Are these samples correct?")
  (doseq [[i toks] (map vector (iterate inc 1) samples)]
    (println (format "%-2d. %s" i toks)))
  (print "Blank for yes, index of counter-example for no: ")
  (flush)
  (let [input (read-line)]
    (when (seq input)
      (get samples (dec (read-string input))))))

(defn stream-sample [g n]
  (-> (lang-seq g)
      (stream/sample 1 n :rate true)
      (->> (take n) vec)))
```
