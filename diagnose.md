``` {.clojure .numberLines}
(defn- diagnose
  [member* t]
  (letfn [(consume-child [state [rule & children]]
            (if-let [bad-child (some (fn [{cnt :nt cy :yield :as child}]
                                       (when-not (member* cnt cy) child))
                                     children)]
              (update-in state [0] conj  bad-child)
              (update-in state [1] conj! rule)))]
    (loop [q         (queue t)
           bad-rules (transient #{})]
      (if (seq q)
        (let [{:keys [children]} (peek q)
              [q* bad-rules*] (reduce consume-child
                                      [(pop q) bad-rules]
                                      children)]
          (recur q* bad-rules*))
        (persistent! bad-rules)))))
```
