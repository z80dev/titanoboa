(defproject titanoboa "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :license {:name "EPL-2.0 OR GPL-2.0-or-later WITH Classpath-exception-2.0"
            :url "https://www.eclipse.org/legal/epl-2.0/"}
  :dependencies [[org.clojure/clojure "1.11.1"]
                 [clj-python/libpython-clj "2.018"]]
  :main ^:skip-aot titanoboa.core
  :target-path "target/%s"
  :jvm-opts ["--add-modules" "jdk.incubator.foreign"
                       "--enable-native-access=ALL-UNNAMED"]
  :profiles {:uberjar {:aot :all
                       :jvm-opts ["-Dclojure.compiler.direct-linking=true" "--add-modules" "jdk.incubator.foreign"
                       "--enable-native-access=ALL-UNNAMED"]}})
