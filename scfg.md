```{.clojure .numberLines}
(defn cfg->scfg
  "Given a CFG `g`, produce an SCFG with the same rules as `g`, and uniform
  probabilities. `g` must be well-formed. i.e. All its non-terminals must
  possess atleast one rule."
  [g]
  (map-v (fn [rs]
           (let [p (->> (count rs) (/ 1) double)]
             (into {} (map #(vector % p) rs))))
         g))

(defn scfg->cfg
  "Given an SCFG `sg`, produce a CFG with the same rules as `g`."
  [sg] (map-v (comp set keys) sg))

(defn rule-p
  "Given an SCFG `sg` and a rule return its associated probability, or `0.0`
  if it doesn't exist."
  [sg [lhs & rhs]] (get-in sg [lhs (vec rhs)] 0.0))

(defn rule-seq
  "Given an `sg`, returns a sequence of [rule probability] pairs in `sg`.
  If an `nt` is also provided, then only rules from that non-terminal will be
  given."
  ([sg]
   (for [[nt rs] sg
         [r p]   rs]
     [(mk-rule nt r) p]))

  ([sg nt]
   (for [rs (get sg nt {})
         [r p] rs]
     [(mk-rule nt r) p])))

(defn add-rule
  "Add rule `nt => r` with probability `p` to SCFG `sg`."
  [sg [nt & r] p] (assoc-in sg [nt (vec r)] p))

(defn slice
  "Given an SCFG `sg` and a CFG `g`, return an SCFG with the rules from `g`
  and the probabilities from `sg`."
  [sg g]
  (->> g cfg/rule-seq
       (map (fn [r] [r (rule-p sg r)]))
       (reduce (partial apply add-rule) {})))

(defn normalize
  "Given an SCFG `sg` return a new SCFG in which all probabilities conditional
  on a particular non-terminal sum to 1."
  [sg]
  (map-v (fn [rules]
           (let [sum (reduce + (vals rules))]
             (map-v #(/ % sum) rules)))
         sg))
```
