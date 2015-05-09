```{.clojure .numberLines}
(defn- classify
  "Determines what should be done to the given Earley Item."
  [{[_ & rs] :rule offset :offset}]
  {:pre  [(not (neg? offset))]
   :post [(#{::shift ::reduce ::predict} %)] }
  (if-let [el (get (vec rs) offset)]
    (condp apply [el]
      terminal?     ::shift
      non-terminal? ::predict)
    ::reduce))
```
