## Firmware of NanoPi R2S Based on Original OpenWrt

### OpenWrt Mainline supported NanoPi R2S in 28 July 2020

Release in:
https://github.com/nicksun98/R2S-OpenWrt/releases

### Noticed：

Login IP：192.168.1.1 

Password：None

~~Swap the ethernet ports of lan wan~~

### Version Informations:

The Latest Edition of Snapshot OpenWrt（The day of the latest build）

LuCI version：LuCI master

Doge contains JD-DailyBonus

[BingBing](https://weibo.com/u/6512991534) contains nothing

Null means "No Services"

### Feature：

1.Stability first

2.Only the most basic softwares

3.SFE supported

4.Fullcone NAT supported

5.Port some old softwares for the LuCI master by [msylgj](https://github.com/msylgj)

6.Remove IPv6 by default

  * If you do need IPv6

```
uci set dhcp.lan.ra='hybrid'
uci set dhcp.lan.ndp='hybrid'
uci set dhcp.lan.dhcpv6='hybrid'
uci set dhcp.lan.ra_management='1'
uci del dhcp.@dnsmasq[0].rebind_protection='1'
uci commit dhcp
```

![](/Screenshots/main.jpeg)

## Thanks to all friends in NanoPi R2S Club

* Especially Thanks
  * [QiuSimons](https://github.com/QiuSimons)
  * [Project-OpenWrt](https://github.com/project-openwrt)
  * [CN_SZTL](https://github.com/1715173329)
  * [quintus-lab](https://github.com/quintus-lab)
  * [RikudouPatrickstar](https://github.com/RikudouPatrickstar)
  * [KaneGreen](https://github.com/KaneGreen)
  * [msylgj](https://github.com/msylgj)
