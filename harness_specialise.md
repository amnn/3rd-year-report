```{.clojure .numberLines}
(defn k-bounded-rig
  [g ts corpus & {:as params}]
  (grammar-rig kb/learn g ts corpus params))

(defn soft-k-bounded-rig
  [g ts corpus & {:as params}]
  (grammar-rig skb/learn g ts corpus params))
```
