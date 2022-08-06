(import boa
        vyper.utils [checksum_encode]
        time [time])

(require
  hyrule [->])

(setv _t (time))

(defn timeit [msg]
  (let [t (time)]
    (global _t)
    (print f"{msg} took {(- t _t)}s")
    (setv _t t)))

(defn format_addr [t]
  (let [t (if (isinstance t str)
              (t.encode "utf-8")
              t)]
    (t.rjust 20 b"\x00")))

(setv BUNNY (format_addr "bunny")
      MILKY (format_addr "milky")
      DOGGIE (format_addr "doggie")
      POOLPI (format_addr "poolpi")
      parties [BUNNY MILKY DOGGIE POOLPI]
      boa.env.eoa BUNNY
      START_TIME 1641013200
      boa.env.vm.patch.timestamp START_TIME
      DAY 86400
      WEEK (* 7 DAY)
      YEAR (* 365 DAY)
      MAX_LOCK_DURATION (* 4 YEAR)
      YFI (boa.load "examples/ERC20.vy"
                    "yfi token"
                    "YFI"
                    18
                    0
                    :override_address (format_addr "YFI")))

(timeit "load YFI")

(setv _rewards_pool_address (format_addr "rewards_pool")
      veYFI (boa.load "tests/veYFI.vy"
                      YFI.address
                      _rewards_pool_address
                      :override_address (format_addr "veYFI")))

(timeit "load veYFI")

(setv rewards_pool (boa.load "tests/RewardPool.vy"
                             veYFI.address
                             START_TIME
                             :override_address _rewards_pool_address))

(timeit "load rewards pool")

(YFI.mint BUNNY (** 10 21))

(YFI.eval f"self.balanceOf[convert(0x{(BUNNY.hex)}, address)] += 1")
(YFI.eval f"self.balanceOf[convert(0x{(BUNNY.hex)}, address)] -= 1")

(YFI.mint MILKY (** 10 21))
(YFI.transfer DOGGIE (** 10 18))
(YFI.transfer MILKY (-> 10
                        (** 18)
                        (* 3)))
(YFI.transfer POOLPI (** 10 18))

(for [t parties]
  (let [addr (checksum_encode f"0x{(t.hex)}")]
    (assert (= (YFI.balanceOf t) (YFI.eval f"self.balanceOf[{addr}]")))))

(timeit "set up balances")

(for [t parties]
  (with [(boa.env.prank t)]
    (print f"approving {(YFI.balanceOf t)} for {t}")
    (YFI.approve veYFI.address (YFI.balanceOf t))))

(timeit "approve YFI")

(let [timestamp boa.env.vm.patch.timestamp
      4y_lock (+ timestamp MAX_LOCK_DURATION)
      6y_lock (-> (/ MAX_LOCK_DURATION 4)
                  (* 6)
                  (+ timestamp)
                  int)
      early_exit (-> (/ MAX_LOCK_DURATION 4)
                     (* 3)
                     (+ timestamp)
                     int)
      2y_lock (-> (// MAX_LOCK_DURATION 2)
                  (+ timestamp))]
  (veYFI.modify_lock (** 10 18) 4y_lock BUNNY)
  (with [(boa.env.prank MILKY)]
    (veYFI.modify_lock (** 10 18) 6y_lock MILKY))
  (with [(boa.env.prank POOLPI)]
    (veYFI.modify_lock (** 10 18) early_exit POOLPI))
  (with [(boa.env.prank DOGGIE)]
    (veYFI.modify_lock (** 10 18) 2y_lock DOGGIE)))

(timeit "lock veYFI")

(defn warp_week [[n 1]]
  (+= boa.env.vm.patch.timestamp (* n WEEK))
  (+= boa.env.vm.patch.block_number  (* n 40_000) ))

(let [END_TIME (-> YEAR
                    (* 1.2)
                    (+ START_TIME)
                    int) ;; 1.2 years in the future
      INTERVAL WEEK] ;; checkin weekly
  (for [i (range START_TIME END_TIME INTERVAL)]
   (warp_week)
   (veYFI.checkpoint)
    (when (and (-> POOLPI
                 (veYFI.locked)
                  (get 1)
                  (!= 0))
              (> i (-> MAX_LOCK_DURATION
                       (// 4)
                       (+ START_TIME)
                       int)))
     (with [(boa.env.prank POOLPI)]
       (veYFI.withdraw)))
    (when (and (-> MILKY
                 (veYFI.locked)
                  (get 0)
                  (= (** 10 18)))
              (> i (-> (* .5 YEAR)
                       (+ START_TIME)
                       int)))
     (with [(boa.env.prank MILKY)]
       (veYFI.modify_lock (** 10 18) (+ START_TIME (* 5 YEAR)))))))

(timeit "simulation")

(setv balances (dfor t parties [t (veYFI.balanceOf t)]))
(print balances)
(assert (= balances {BUNNY 693692922292074000 MILKY 1891495433795992400 DOGGIE 195062785364970000 POOLPI 0}))
