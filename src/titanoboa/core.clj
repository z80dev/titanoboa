(ns titanoboa.core
  (:require
   [libpython-clj2.require :refer [require-python]]
   [libpython-clj2.python :refer [py. py.. py.- $a $c] :as py])
  (:gen-class))


(def boa (py/import-module "boa"))

(defn boa-patch [boa field value]
  (let [patch (-> (py.- boa :env)
                  (py.- :vm)
                  (py.- :patch))]
    (py/set-attr! patch field value)))

(boa-patch boa :timestamp START_TIME)

(def t (boa/load "tests/ElectricEel.vy"))

($a t :foo)

(defn format_addr [t]
  (let [t-bytes (.getBytes t "utf-8")
        missing (- 20 (count t-bytes))
        padding (byte-array missing)]
    (concat padding t-bytes)))

(def e (boa/load "tests/ERC20.vy" "yfi token" "YFI" 18 0))

(def BUNNY (format_addr "bunny"))
(def MILKY (format_addr "milky"))
(def DOGGIE (format_addr "doggie"))
(def POOLPI (format_addr "poolpi"))
(def START_TIME 1641013200)
