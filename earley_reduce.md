```{.clojure .numberLines}
(defn- perform-reduxns
  "Creates a sequence of all the waiting reductions after they have been
  reduced. by the given finished `item`."
  [state item]
  (let [path [:reduxns (reduxn-key item)]
        {:keys [toks deriv-len]} item]
    (map #(-> % (shift toks)
              (inc-deriv-len deriv-len))
         (get-in state path))))

(defn- complete-item
  "Mark an item as completed in the given `state`."
  [state item]
  (let [path [:complete (reduxn-key item)]
        {:keys [toks deriv-len]} item]
    (if (get-in state path)
      (update-in state path conj [toks deriv-len])
      (assoc-in  state path {toks deriv-len}))))
```
