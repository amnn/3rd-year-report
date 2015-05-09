```{.clojure .numberLines}
(defn e-graph [sg]
  (map-v (partial reduce
          (fn [row [rule p]]
            (reduce (fn [row sym]
                      (let [col (if (terminal? sym) ::T sym)
                            p*  (get row col 0)]
                        (assoc row col (+ p p*))))
                    row rule))
          {})
         sg))

(defn e-system [sg]
  (let [order    (vec (keys sg))
        sparse-m (e-graph sg)]
    {:order order
     :M (array :vectorz
               (for [i order]
                 (for [j order]
                   (get-in sparse-m [i j] 0))))

     :v (array :vectorz
               (for [i order]
                 (get-in sparse-m [i ::T] 0)))}))

(defn strongly-consistent? [sg]
  (let [{:keys [M v order]} (e-system sg)
        n (count order)
        I (identity-matrix :vectorz n)]
    (boolean
      (when-let [inv (inverse (m/- I M))]
        (->> (mmul inv v)
             (every? pos?))))))
```
