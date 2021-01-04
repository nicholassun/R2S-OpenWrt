## Firmware of NanoPi R2S Based on Original OpenWRT

### OpenWrt Mainline supported NanoPi R2S in 28 July 2020

Release in:
https://github.com/nicksun98/R2S-OpenWrt/releases

### Noticed：
Login IP：192.168.1.1 

Password：None

~~Swap the ethernet ports of lan wan~~

The firmwares __DO NOT__ contain argon theme and material theme, JD_DailyBonus may cannot update in Luci.  
To Update JD_DailyBonus:
```
wget --no-check-certificate https://raw.githubusercontent.com/NobyDa/Script/master/JD-DailyBonus/JD_DailyBonus.js -O /usr/share/jd-dailybonus/JD_DailyBonus.js

uci set jd-dailybonus.@global[0].version='version number'

uci commit
```
or running twice
```
/usr/share/jd-dailybonus/newapp.sh -u
```
__Remember to alter the version number__, such as 1.33

To start service:
```
/usr/share/jd-dailybonus/newapp.sh -w
```

### Version Informations:

The Latest Edition of Snapshot （The day of the latest action）

LuCI version：LuCI 19.07 or LuCI master

Doge contains SSRP and JD-DailyBonus

SSRP contains SSRP

### Feature：
1.Stability first

2.Only the most basic softwares

3.SFE supported

4.Fullcone NAT supported

5.Remove IPv6 as default

  * If you do need IPv6

```
uci set dhcp.lan.ra='hybrid'
uci set dhcp.lan.ndp='hybrid'
uci set dhcp.lan.dhcpv6='hybrid'
uci set dhcp.lan.ra_management='1'
uci del dhcp.@dnsmasq[0].rebind_protection='1'
uci commit dhcp
```

![](/Screenshots/newversion.jpeg)

## Thanks to all friends in NanoPi R2S Club
