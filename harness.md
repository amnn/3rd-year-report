```{.clojure .numberLines}
(defn sample-test-rig
  ([learn member* counter* n corpus
    & {:keys [verbose? error]
       :or   {verbose? false
              error 0.0}}]

   (let [counter-calls (atom 0)
         member-calls  (atom 0)

         result
         (learn
          (cond->> member*
            :always  (inject-error error verbose?)
            :always  (inject-counter member-calls)
            verbose? (inject-printer member-print))

          (cond->> (counter* n corpus
                             (fn [samples]
                               (some #(when-not (member* :S %) %)
                                     (sort-by count samples))))
            :always  (inject-counter counter-calls)
            verbose? (inject-printer counter-print)))]
     {:grammar       result
      :member-calls  @member-calls
      :counter-calls @counter-calls})))

(defn grammar-rig
  [learn g ts corpus {:keys [verbose? error samples]
                      :or   {verbose? false
                             error    0.0}}]
  (let [member*
        (fn [nt yield]
          (boolean
           (yields? g nt yield)))

        nts (keys g)]
    (sample-test-rig
     #(learn %1 %2 nts ts)
     member* sample-counter
     samples corpus
     :verbose? verbose?
     :error    error)))
```
