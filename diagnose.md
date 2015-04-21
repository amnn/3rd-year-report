``` {.clojure .numberLines}
(defn diagnose
  [member* t]
  (letfn [(consume-child [yield state [rule & children]]
            (if ((:visited? state) [rule yield])
              state
              (let [state (update-in state [:visited?] conj! [rule yield])]
                (if-let [bad-child
                         (some (fn [{cnt :nt cy :yield :as child}]
                                 (when-not (member* cnt cy) child))
                               (remove terminal-node? children))]
                  (update-in state [:q] conj bad-child)
                  (update-in state [:bad-rules] conj! rule)))))]
    (loop [state {:q         (queue t)
                  :bad-rules (transient #{})
                  :visited?  (transient #{})}]
      (if-let [{:keys [children yield]} (-> state :q peek)]
        (recur (reduce (partial consume-child yield)
                       (update-in state [:q] pop)
                       children))
        (-> state :bad-rules persistent!)))))
```
