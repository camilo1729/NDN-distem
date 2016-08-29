def confGen(node,neighbor)
%Q(
    ; the general section contains all the general settings for router

general
{
  ; mandatory configuration command section network, site and router

  network /ndn/        ; name of the network the router belongs to in ndn URI format
  site /#{node[:site]}    ; name of the site the router belongs to in ndn URI format
  router /#{node[:router]}    ; name of the router in ndn URI format

  ; lsa-refresh-time is the time in seconds, after which router will refresh its LSAs
  lsa-refresh-time 1800      ; default value 1800. Valid values 240-7200

  ; router-dead-interval is the time in seconds after which an inactive router's
  ; LSAs are removed
  ;router-dead-interval 3600 ; default value: 2*lsa-refresh-time. Value must be larger
                             ; than lsa-refresh-time

  ; InterestLifetime (in seconds) for LSA fetching
  lsa-interest-lifetime 4    ; default value 4. Valid values 1-60

  ; log-level is used to set the logging level for NLSR.
  ; All debugging levels listed above the selected value are enabled.
  ;
  ; Valid values:
  ;
  ;  NONE ; no messages
  ;  ERROR ; error messages
  ;  WARN ; warning messages
  ;  INFO ; informational messages (default)
  ;  DEBUG ; debugging messages
  ;  TRACE ; trace messages (most verbose)
  ;  ALL ; all messages

  log-level  INFO

  log-dir       /var/log/nlsr/         ; path for log directory (Absolute path)
  seq-dir       /var/lib/nlsr/         ; path for sequence directory (Absolute path)
  ;log4cxx-conf /path/to/log4cxx-conf  ; path for log4cxx configuration file (Absolute path)
}

; the neighbors section contains the configuration for router's neighbors and hello's behavior

neighbors
{
  ; in case hello interest timed out, router will try 'hello-retries' times at 'hello-timeout'
  ; seconds interval before giving up for any neighbors (deciding link is down)

   hello-retries 3                     ; interest retries number in integer. Default value 3
                                       ; valid values 1-10

   hello-timeout 1                    ; interest time out value in integer. Default value 1
                                       ; Valid values 1-15

   hello-interval  60                  ; interest sending interval in seconds. Default value 60
                                       ; valid values 30-90

  ; adj-lsa-build-interval is the time to wait in seconds after an Adjacency LSA build is scheduled
  ; before actually building the Adjacency LSA

  adj-lsa-build-interval 5   ; default value 5. Valid values 0-5. It is recommended that
                             ; adj-lsa-build-interval have a lower value than routing-calc-interval

  ; first-hello-interval is the time to wait in seconds before sending the first Hello Interest

  first-hello-interval  10   ; Default value 10. Valid values 0-10

  ; neighbor command is used to configure router's neighbor. Each neighbor will need
  ; one block of neighbor command

  neighbor
  {
    name /ndn/#{neighbor[:site]}/#{neighbor[:router]}
    face-uri udp://#{neighbor[:ip]}
    link-cost 25
  }


}

; the hyperbolic section contains the configuration settings of enabling a router to calculate
; routing table using [hyperbolic routing table calculation](http://arxiv.org/abs/0805.1266) method

hyperbolic
{
  ; commands in this section follows a strict order
  ; the switch is used to set hyperbolic routing calculation in NLSR

  state off             ; default value 'off', set value 'on' to enable hyperbolic routing table
                        ; calculation which turns link state routing 'off'. set value to 'dry-run'
                        ; to test hyperbolic routing and compare with link state routing.


  radius   123.456      ; radius of the router in hyperbolic coordinate system
  angle    1.45         ; angle of the router in hyperbolic coordinate system
}


; the fib section is used to configure fib entry's type to ndn FIB updated by NLSR

fib
{
  ; the max-faces-per-prefix is used to limit the number of faces for each name prefixes
  ; by NLSR in ndn FIB

  max-faces-per-prefix 3   ; default value 0. Valid value 0-60. By default (value 0) NLSR adds
                           ; all available faces for each reachable name prefixes in NDN FIB

  ; routing-calc-interval is the time to wait in seconds after a routing table calculation is
  ; scheduled before actually performing the routing table calculation

  routing-calc-interval 15   ; default value 15. Valid values 0-15. It is recommended that
                             ; routing-calc-interval have a higher value than adj-lsa-build-interval
}

; the advertising section contains the configuration settings of the name prefixes
; hosted by this router

advertising
{
  ; the ndnname is used to advertised name from the router. To advertise each name prefix
  ; configure one block of ndnname configuration command for every name prefix.

  prefix /ndn/#{node[:name]}
}

security
{
  validator
  {
  trust-anchor
    {
      type any
    }
  }
  prefix-update-validator
  {
  trust-anchor
    {
      type any
    }
  }
}
)
end
