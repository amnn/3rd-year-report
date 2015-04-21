``` {.clojure .numberLines}
(defn- parse-tree*
  [& {:keys [->branch ->leaf merge-fn rule
             branches leaves root ts]}]
  (let [toks (vec ts)
        n    (count toks)

        t-map (->> leaves
                   (map (fn [l]
                          (let [[nt t] (rule l)]
                            {t {nt l}})))
                   (apply merge-with merge))

        subtok (fn [start len]
                 (subvec toks start
                         (+ start len)))

        partials
        {1 (into {} (for [j (range n)
                          :let [[t :as yield] (subtok j 1)]]
                      [j (into {} (for [[nt l] (get t-map t)]
                                    [nt (->leaf nt l yield)]))]))}
        child
        (fn [p len start sym]
          (if (terminal? sym)
            (when (and (= len 1)
                       (= (get toks start) sym))
              (->Terminal sym))
            (get-in p [len start sym])))

        build-partial
        (fn [p [i j k branch]]
          (let        [[a b c]  (rule branch)]
            (if-let   [bt       (child p k j b)]
              (if-let [ct       (child p (- i k) (+ j k) c)]
                (let  [new-node (->branch a branch (subtok j i) bt ct)]
                  (if-let [node (get-in p [i j a])]
                    (update-in p [i j a] merge-fn new-node)
                    (assoc-in  p [i j a] new-node)))
                p)
              p)))]

    (-> (reduce build-partial partials
                (for [i (range 2 (inc n))  ;; Subsequence length
                      j (range (- n i -1)) ;; Start position
                      k (range 1 i)        ;; Split point
                      b branches]          ;; Rule
                  [i j k b]))
        (get-in [n 0 root]))))
```
