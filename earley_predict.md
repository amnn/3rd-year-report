```{.clojure .numberLines}
(defn- reduxn-key
  "Gives the start position and the non-terminal symbol of the item.
  This information can be used to find the items that are completed by this
  one."
  [i] ((juxt :start non-terminal) i))

(defn- associate-reduxn
  "Add an `item` as waiting for a reduction (keyed by `r-key`) in the parser
  state `state."
  [state r-key item]
  (let [path [:reduxns r-key]]
    (if (get-in state path)
      (update-in state path conj item)
      (assoc-in  state path #{item}))))
```
