``` {.clojure .numberLines}
(defn candidates
  [nts ts]
  (let [children (concat nts ts)]
    (concat
     (for [a nts, t ts] [a t])
     (for [a nts, b children, c children]
       [a b c]))))
```
