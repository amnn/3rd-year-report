```{.clojure .numberLines}
(defrecord ^:private EarleyState [reduxns items complete])

(defn- initial-state [has-empty?]
  (->EarleyState
    {} (queue item-seed)
    (if has-empty?
      {success-key #{[]}}
      {})))
```
