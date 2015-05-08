```{.clojure .numberLines}
;;;;;;;;;; Grammar Creation ;;;;;;;;;;

(defn mk-rule
  "Make a rule with LHS `nt` and RHS `rs`."
  [nt rs] (vec (list* nt rs)))

(defn- arrow? [x] (= '=> x))

(defn- last-i [coll]
  (dec (count coll)))

(defn- split-rules [bodies]
  (letfn [(add-tok [rules tok]
            (if (= '| tok)
              (conj rules [])
              (update-in
                rules [(last-i rules)]
                conj tok)))]
    (reduce add-tok [[]] bodies)))

(defn- rule->map
  "Converts individual rules as described in the docstring of `cfg` into a
  singleton map for consumption by the `cfg` macro."
  [[s => & bodies]]
  {:pre [(arrow? =>)
         (non-terminal? s)]}
  {s (into #{} (split-rules bodies))})

(defmacro cfg
  "Combines the rules given as parameters together to form a context free
  grammar. Rules are lists with the following format:

    (:S => A B :C D | E F :G H)

  This defines two rules, for the non-terminal `:S`. The first being
  `:S => A B :C D` and the second being `:S => E F :G H`. Rules may be
  empty, i.e. `(:S => )`. The `:S` non-terminal is implicitly the starting
  non-terminal."
  [& rules]
  `'~(->> rules
          (map rule->map)
          (apply merge-with union)))

(defn clean-cfg
  "Ensure there are no empty non-terminals."
  [g] (into {} (r/remove (comp empty? #(nth % 1)) g)))

(defn add-rule
  "Add a singleton rule `s => rs` to the grammar represented by `g`."
  [g [s & rs]]
  (update-in g [s] union #{(vec rs)}))

(defn remove-rule
  "Removes rule `s => rs` from `g` if it exists."
  [g [s & rs]]
  (clean-cfg (update-in g [s] disj (vec rs))))

;;;;;;;;;; Rule Traversal ;;;;;;;;;;

(defn- non-term-rules [[s rss]]
  (map (partial mk-rule s) rss))

(defn rule-seq
  "Produces a lazy sequences of rules in `g`, each of the form `[~s, ~@rs] for
  every rule `s => rs` in `g`. Or, if a non-terminal `nt` is also provided,
  creates a lazy sequence of the rules in `g` with `nt` as their LHS."
  ([g] (mapcat non-term-rules g))
  ([g nt] (non-term-rules (find g nt))))
```
