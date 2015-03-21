``` {.clojure .numberLines}
(defn interactive-member
  "A form of the `member*` predicate used by the k-bounded learning algorithm
  that poses the question to the user."
  [nt yield]
  (print (str nt " =>* " (join \space yield) "? Y/N: "))
  (flush)
  (#{\y \Y} (first (read-line))))
```
