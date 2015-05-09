```{.clojure .numberLines}
(defn- shift
  "Move the item's cursor forward over a given token or sequence of tokens."
  [item toks]
  (-> item
      (update-in [:offset] inc)
      (update-in [:toks]
                 #(if (coll? %2)
                    (reduce conj %1 %2)
                    (conj %1 %2))
                 toks)))

(defn- perform-shift
  "Shifts an item over tokens and adds it to the end of a queue"
  [q i toks] (conj q (shift i toks)))

(defn- enqueue-shift
  "Takes an `item`, shifts it over some tokens, `toks`, and adds it to the end
  of the item queue in the `state`."
  [state item toks]
  (update-in state [:items]
             perform-shift item toks))
```
