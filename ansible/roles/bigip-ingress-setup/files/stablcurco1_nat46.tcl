#
# Simple NAT46 iRule rev 0.3 (2020/04/06)
#
#   Written By:  Shunsuke Takahashi (s.takahashi at f5.com)
#
#   Updated By:  Parvel Gu (parvel.gu at f5.com)
#                Add support of hairpin mode - in case of dest IPv6 is a local VS
#                Additional iCall script has to maintain a data group DG_IP_2_VS
#                Example: fd80:192:168:9:a:b:c:99.8080 => b.smf.openshift.f5.lab
#
#   Description: Lookup table to convert DNS46 internal only IPv4 destination
#                address to original IPv6 desitination and SNAT client addr to
#                IPv6 SNAT pool address.
#
#                Example:Translate IPv4 source and IPv4 destination into IPv6
#
#                (s)10.1.1.2->(d)1.1.1.1 T (S)2001:fb46:102->(D)2001::101:101
#
#
#   Information: Currently, no application level gateway is implemented to the
#                NAT46 iRule. Only HTTP like traffic can be passed through and
#                SIP, PPTP or BITTORRENT like protocols will be failed.
#
#
#
#   Requirement: The rule requires following environment to be fullfiled
#                1) VS need to listen on dns46 pool range. (Similar to NAT64)
#
#                2) Address translation must be enabled on the VS for NAT46
#
#                     ltm virtual vs-nat46 {
#                       destination 100.64.0.0:any
#                       ip-protocol any
#                       mask 255.255.0.0
#                       profiles {
#                         fastL4 { }
#                       }
#                       rules {
#                         rule_nat46
#                       }
#                       source 0.0.0.0/0
#                       source-address-translation {
#                         pool snat-pool-nat46
#                         type snat
#                       }
#                       translate-port disabled
#                       vlans-disabled
#                     }
#
#
timing off

when RULE_INIT {

  # Rule Name and Version shown in the log
  set static::RULE_NAME "Simple NAT46 v0.3"

  # 0: No Debug Logging 1: Debug Logging
  set static::DBG 1

  # IP address for Sorry Page (Used when run out pool)
  set static::Sorry_IP 192.168.11.202

  # IPv4 SNAT Pool (For Sorry Page Connection)
  set static::snat_sorry automap

}


when CLIENT_ACCEPTED priority 200 {

  # Using High-Speed Logging in thie rule
  #set hsl [HSL::open -proto UDP -pool pool-hsl-windows]
  set log_head   "\[nat46\]([IP::client_addr])"
  set log_head_d "$log_head\(debug\)"

  if {$static::DBG==1}{log local0.info  "<191> $log_head_d  ***** iRule: $static::RULE_NAME executed *****"}


  # Lookup DNS46 to find original IPv6 destination IP
  set src_v4 [IP::client_addr]
  set dst_v4 [IP::local_addr]
  set dst_port [TCP::local_port]
  set dst_v6 [table lookup -subtable "t_dns46" $dst_v4]

  if {$static::DBG==1}{log local0.info  "<191> $log_head_d Looked up NAT64 table for $dst_v4 matched $dst_v6"}

  if {$dst_v6 != ""} {
    # Check if the dst_v6 is a local VIP
    # The Data Group is updated by periodical iCall script
    set local_vs [class match -value $dst_v6.$dst_port equals DG_IP_2_VS]
    if { $local_vs ne "" } {
        virtual $local_vs
        if {$static::DBG==1}{log local0.info  "<191> $log_head_d Hairpin to \[virtual $local_vs\]"}
    } else {
        node $dst_v6
        if {$static::DBG==1}{log local0.info  "<191> $log_head_d Changed Destination to \[$dst_v6\]"}
    }

  } else {

    # Send to sorry server_addr
    node $static::Sorry_IP
    snat $static::snat_sorry

    log local0.info  "<190> $log_head Send Traffic to Sorry IP\[$static::Sorry_IP\ (snat $snat_v4) ]"
  }

  if {$static::DBG==1}{log local0.info  "<191> $log_head_d  ***** iRule: $static::RULE_NAME completed *****"}
}


when SERVER_CONNECTED {

  if {$static::DBG==1}{log local0.info  "<191> $log_head_d NAT46 Added Src \{$src_v4 => [IP::local_addr]\} \, Dst\{$dst_v4 => [IP::server_addr]\}"}

}
