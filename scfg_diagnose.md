```{.clojure .numberLines}
(defn- diagnose [member* t]
  (letfn [(children [t]
            (when (and (:lt t) (:rt t))
              ((juxt :lt :rt) t)))]
    (loop [{:keys [rule] :as t} t]
      (if-let [c (some
                  (fn [{:keys [nt yield] :as c}]
                    (when-not (member* nt yield) c))
                  (children t))]
        (recur c)
        rule))))
```
