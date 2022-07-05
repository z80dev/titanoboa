(ns titanoboa.core
  (:require
   [libpython-clj2.require :refer [require-python]]
   [libpython-clj2.python :refer [py. py.. py.- $a $c] :as py])
  (:gen-class))


(def boa (py/import-module "boa"))
(def boautil (py/import-module "boautil"))

(defn format_addr [t]
  ($a boautil :format_addr (py/->python t)))

(defn boa-patch [boa field value]
  (let [patch (-> (py.- boa :env)
                  (py.- :vm)
                  (py.- :patch))]
    (py/set-attr! patch field value)))


(def t ($a boa :load "tests/ElectricEel.vy"))

($a t :foo)

(def a (format_addr "z80"))

(def BUNNY (format_addr "bunny"))
(def MILKY (format_addr "milky"))
(def DOGGIE (format_addr "doggie"))
(def POOLPI (format_addr "poolpi"))
(def START_TIME 1641013200)
(def DAY 86400)
(def WEEK (* DAY 7))
(def YEAR (* DAY 365))
(def MAX_LOCK_DURATION (* YEAR 4))

(boa-patch boa :timestamp START_TIME)

(-> boa
    (py.- :env)
    ($a :generate_address))

(let [env (py.- boa :env)]
  (py/set-attr! env :eoa BUNNY))

(def YFI ($a boa :load "tests/ERC20.vy" "yfi token" "YFI" 18 0 :override_address (format_addr "YFI")))
