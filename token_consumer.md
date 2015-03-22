```{.clojure .numberLines}
(defn- token-consumer [g nullable? shift?]
  (fn [{:keys [items] :as state} index]
    (loop [processed? #{}, items items
           state (reset-state state)]
      (if (seq items)
        (let [item (peek items)
              p-key (processed-key item)]
          (if (processed? p-key)
            (recur processed? (pop items) state)
            (case (classify item)

              ::shift
              (recur (conj processed? p-key)
                     (pop items)
                     (let [tok (next-sym item)]
                       (if (shift? index tok)
                         (enqueue-shift state item tok)
                         state)))

              ::reduce
              (recur (conj processed? p-key)
                     (into (pop items)
                           (perform-reduxns state item))
                     (complete-item state item))

              ::predict
              (let [nt         (next-sym item), r-key [index nt]
                    predicted? (contains? (:reduxns state) r-key)
                    items      (pop (if (nullable? nt)
                                      (let [item* (inc-deriv-len item 1)]
                                        (perform-shift items item* []))
                                      items))]
                (recur
                  (conj processed? p-key)
                  (if predicted?
                    items
                    (into items (init-items g nt index)))
                  (associate-reduxn state r-key item))))))
        state))))

(defn- reset-state [state]
  (-> state
      (assoc :items (queue)
             :complete {})))
```
