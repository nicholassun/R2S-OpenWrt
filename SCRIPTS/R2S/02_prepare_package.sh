#!/bin/bash
clear

notExce(){ 
# Blocktrron.git 
patch -p1 < ../PATCH/new/main/exp/uboot-rockchip-update-to-v2020.10.patch
patch -p1 < ../PATCH/new/main/exp/rockchip-fix-NanoPi-R2S-GMAC-clock-name.patch
# Kernel
cp -f ../PATCH/new/main/xanmod_5.4.patch ./target/linux/generic/hack-5.4/000-xanmod_5.4.patch
wget -q https://patch-diff.githubusercontent.com/raw/openwrt/openwrt/pull/3580.patch
patch -p1 < ./3580.patch
# RT Kernel
cp -f ../PATCH/new/main/999-patch-5.4.61-rt37.patch ./target/linux/generic/hack-5.4/999-patch-5.4.61-rt37.patch
sed -i '/PREEMPT/d' ./target/linux/rockchip/armv8/config-5.4
echo '
CONFIG_PREEMPT_RT=y
CONFIG_PREEMPTION=y
' >> ./target/linux/rockchip/armv8/config-5.4
sed -i '/PREEMPT/d' ./target/linux/rockchip/config-default
echo '
CONFIG_PREEMPT_RT=y
CONFIG_PREEMPTION=y
' >> ./target/linux/rockchip/config-default
# HW-RNG
patch -p1 < ../PATCH/new/main/Support-hardware-random-number-generator-for-RK3328.patch
sed -i 's/-f/-f -i/g' feeds/packages/utils/rng-tools/files/rngd.init
echo '
CONFIG_CRYPTO_DRBG=y
CONFIG_CRYPTO_DRBG_HMAC=y
CONFIG_CRYPTO_DRBG_MENU=y
CONFIG_CRYPTO_JITTERENTROPY=y
CONFIG_CRYPTO_RNG=y
CONFIG_CRYPTO_RNG2=y
CONFIG_CRYPTO_RNG_DEFAULT=y
' >> ./target/linux/rockchip/armv8/config-5.4
}

## Prepare
# Use feed sources of Branch 19.07
rm -f ./feeds.conf.default
wget https://github.com/nicholassun/openwrt/raw/openwrt-19.07/feeds.conf.default
wget -P include/ https://github.com/openwrt/openwrt/raw/openwrt-19.07/include/scons.mk
patch -p1 < ../PATCH/new/main/0001-tools-add-upx-ucl-support.patch
# Remove annoying snapshot tag
sed -i 's,SNAPSHOT,,g' include/version.mk
sed -i 's,snapshots,,g' package/base-files/image-config.in
# GCC CFLAGS
sed -i 's/Os/O2/g' include/target.mk
sed -i 's,-mcpu=generic,-march=armv8-a+crypto+crc -mcpu=cortex-a53+crypto+crc -mtune=cortex-a53,g' include/target.mk
sed -i 's/O2/O2/g' ./rules.mk
# Update feeds
./scripts/feeds update -a && ./scripts/feeds install -a

## Custom-made
# 3328 Add idle
wget -P target/linux/rockchip/patches-5.4 https://github.com/project-openwrt/openwrt/raw/master/target/linux/rockchip/patches-5.4/007-arm64-dts-rockchip-Add-RK3328-idle-state.patch
wget -P target/linux/generic/pending-5.4 https://github.com/project-openwrt/openwrt/raw/master/target/linux/generic/pending-5.4/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
# IRQ
sed -i '/set_interface_core 4 "eth1"/a\set_interface_core 8 "ff160000" "ff160000.i2c"' target/linux/rockchip/armv8/base-files/etc/hotplug.d/net/40-net-smp-affinity
sed -i '/set_interface_core 4 "eth1"/a\set_interface_core 1 "ff150000" "ff150000.i2c"' target/linux/rockchip/armv8/base-files/etc/hotplug.d/net/40-net-smp-affinity
# Disabed rk3328 ethernet tcp/udp offloading tx/rx
sed -i '/;;/i\ethtool -K eth0 rx off tx off && logger -t disable-offloading "disabed rk3328 ethernet tcp/udp offloading tx/rx"' target/linux/rockchip/armv8/base-files/etc/hotplug.d/net/40-net-smp-affinity
# Update r8152 driver
#wget -O- https://patch-diff.githubusercontent.com/raw/openwrt/openwrt/pull/3178.patch | patch -p1
#wget -O- https://github.com/project-openwrt/openwrt/commit/d8df86130d172b3ce262d2744e2ddd2a6eed5f50.patch | patch -p1
svn co https://github.com/project-openwrt/openwrt/branches/master/package/ctcgfw/r8152 package/new/r8152
sed -i '/rtl8152/d' ./target/linux/rockchip/image/armv8.mk
# Overclock or not
cp -f ../PATCH/new/main/999-RK3328-enable-1512mhz-opp.patch ./target/linux/rockchip/patches-5.4/999-RK3328-enable-1512mhz-opp.patch
#cp -f ../PATCH/new/main/999-unlock-1608mhz-rk3328.patch ./target/linux/rockchip/patches-5.4/999-unlock-1608mhz-rk3328.patch
# Swap LAN & WAN
#patch -p1 < ../PATCH/new/main/0001-target-rockchip-swap-nanopi-r2s-lan-wan-port.patch

## Important Patches
# Minor Changes
sed -i '/CONFIG_SLUB/d' ./target/linux/rockchip/armv8/config-5.4
sed -i '/CONFIG_PROC_[^V].*/d' ./target/linux/rockchip/armv8/config-5.4
# Patch i2c0
#cp -f ../PATCH/new/main/998-rockchip-enable-i2c0-on-NanoPi-R2S.patch ./target/linux/rockchip/patches-5.4/998-rockchip-enable-i2c0-on-NanoPi-R2S.patch
# LuCI network
#patch -p1 < ../PATCH/new/main/luci_network-add-packet-steering.patch
# Patch jsonc
patch -p1 < ../PATCH/new/package/use_json_object_new_int64.patch
# Patch dnsmasq
patch -p1 < ../PATCH/new/package/dnsmasq-add-filter-aaaa-option.patch
patch -p1 < ../PATCH/new/package/luci-add-filter-aaaa-option.patch
cp -f ../PATCH/new/package/900-add-filter-aaaa-option.patch ./package/network/services/dnsmasq/patches/900-add-filter-aaaa-option.patch
rm -rf ./package/base-files/files/etc/init.d/boot
wget -P package/base-files/files/etc/init.d https://github.com/project-openwrt/openwrt/raw/openwrt-18.06-k5.4/package/base-files/files/etc/init.d/boot

# Revert to FW3
#rm -rf ./package/network/config/firewall
#svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/network/config/firewall package/network/config/firewall
# Patch kernel to fix fullcone conflict
pushd target/linux/generic/hack-5.4
wget https://github.com/coolsnowwolf/lede/raw/master/target/linux/generic/hack-5.4/952-net-conntrack-events-support-multiple-registrant.patch
popd
# Patch firewall to enable fullcone
mkdir package/network/config/firewall/patches
wget -P package/network/config/firewall/patches/ https://github.com/project-openwrt/openwrt/raw/master/package/network/config/firewall/patches/fullconenat.patch
#wget -P package/network/config/firewall/patches/ https://github.com/LGA1150/fullconenat-fw3-patch/raw/master/fullconenat.patch
# Patch LuCI to add fullcone button
patch -p1 < ../PATCH/new/package/luci-app-firewall_add_fullcone.patch
#pushd feeds/luci
#wget -O- https://github.com/LGA1150/fullconenat-fw3-patch/raw/master/luci.patch | git apply
#popd
# FullCone modules
cp -rf ../openwrt-lienol/package/network/fullconenat ./package/network/fullconenat

# SFE core patch
pushd target/linux/generic/hack-5.4
wget https://github.com/coolsnowwolf/lede/raw/master/target/linux/generic/hack-5.4/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
popd
# Patch firewall to enable SFE
patch -p1 < ../PATCH/new/package/luci-app-firewall_add_sfe_switch.patch
# SFE modules
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shortcut-fe package/lean/shortcut-fe
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/fast-classifier package/lean/fast-classifier
cp -f ../PATCH/duplicate/shortcut-fe ./package/base-files/files/etc/init.d

## Extra Packages
# Luci-app-compressed-memory ( Check 01 )
#wget -O- https://patch-diff.githubusercontent.com/raw/openwrt/openwrt/pull/2840.patch | patch -p1
#mkdir ./package/new
#cp -rf ../NoTengoBattery/feeds/luci/applications/luci-app-compressed-memory ./package/new/luci-app-compressed-memory
#sed -i 's,include ../..,include $(TOPDIR)/feeds/luci,g' ./package/new/luci-app-compressed-memory/Makefile
#rm -rf ./package/system/compressed-memory
#cp -rf ../NoTengoBattery/package/system/compressed-memory ./package/system/compressed-memory
# Change Cryptodev-linux
rm -rf ./package/kernel/cryptodev-linux
svn co https://github.com/project-openwrt/openwrt/branches/master/package/kernel/cryptodev-linux package/kernel/cryptodev-linux
# Revert OpenSSL
#rm -rf ./package/libs/openssl
#svn co -r 90110 https://github.com/openwrt/openwrt/trunk/package/libs/openssl package/libs/openssl
# Change Htop
rm -rf ./feeds/packages/admin/htop
svn co https://github.com/openwrt/packages/trunk/admin/htop feeds/packages/admin/htop
# Change Lzo
svn co https://github.com/openwrt/packages/trunk/libs/lzo feeds/packages/libs/lzo
ln -sf ../../../feeds/packages/libs/lzo ./package/feeds/packages/lzo
# Change Curl
rm -rf ./package/network/utils/curl
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/network/utils/curl package/network/utils/curl
# Change Node
rm -rf ./feeds/packages/lang/node
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node feeds/packages/lang/node
rm -rf ./feeds/packages/lang/node-arduino-firmata
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-arduino-firmata feeds/packages/lang/node-arduino-firmata
rm -rf ./feeds/packages/lang/node-cylon
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-cylon feeds/packages/lang/node-cylon
rm -rf ./feeds/packages/lang/node-hid
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-hid feeds/packages/lang/node-hid
rm -rf ./feeds/packages/lang/node-homebridge
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-homebridge feeds/packages/lang/node-homebridge
rm -rf ./feeds/packages/lang/node-serialport
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-serialport feeds/packages/lang/node-serialport
rm -rf ./feeds/packages/lang/node-serialport-bindings
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-serialport-bindings feeds/packages/lang/node-serialport-bindings
# Change libcap
rm -rf ./feeds/packages/libs/libcap/
svn co https://github.com/openwrt/packages/trunk/libs/libcap feeds/packages/libs/libcap
# Change GCC
rm -rf ./feeds/packages/devel/gcc
svn co https://github.com/openwrt/packages/trunk/devel/gcc feeds/packages/devel/gcc
# Change Golang
rm -rf ./feeds/packages/lang/golang
svn co https://github.com/openwrt/packages/trunk/lang/golang feeds/packages/lang/golang
# Python
svn co https://github.com/openwrt/packages/trunk/lang/python/python-cached-property feeds/packages/lang/python/python-cached-property
ln -sf ../../../feeds/packages/lang/python/python-cached-property ./package/feeds/packages/python-cached-property
svn co https://github.com/openwrt/packages/trunk/lang/python/python-distro feeds/packages/lang/python/python-distro
ln -sf ../../../feeds/packages/lang/python/python-distro ./package/feeds/packages/python-distro
svn co https://github.com/openwrt/packages/trunk/lang/python/python-docopt feeds/packages/lang/python/python-docopt
ln -sf ../../../feeds/packages/lang/python/python-docopt ./package/feeds/packages/python-docopt
svn co https://github.com/openwrt/packages/trunk/lang/python/python-docker feeds/packages/lang/python/python-docker
ln -sf ../../../feeds/packages/lang/python/python-docker ./package/feeds/packages/python-docker
svn co https://github.com/openwrt/packages/trunk/lang/python/python-dockerpty feeds/packages/lang/python/python-dockerpty
ln -sf ../../../feeds/packages/lang/python/python-dockerpty ./package/feeds/packages/python-dockerpty
svn co https://github.com/openwrt/packages/trunk/lang/python/python-dotenv feeds/packages/lang/python/python-dotenv
ln -sf ../../../feeds/packages/lang/python/python-dotenv ./package/feeds/packages/python-dotenv
svn co https://github.com/openwrt/packages/trunk/lang/python/python-jsonschema feeds/packages/lang/python/python-jsonschema
ln -sf ../../../feeds/packages/lang/python/python-jsonschema ./package/feeds/packages/python-jsonschema
svn co https://github.com/openwrt/packages/trunk/lang/python/python-texttable feeds/packages/lang/python/python-texttable
ln -sf ../../../feeds/packages/lang/python/python-texttable ./package/feeds/packages/python-texttable
svn co https://github.com/openwrt/packages/trunk/lang/python/python-websocket-client feeds/packages/lang/python/python-websocket-client
ln -sf ../../../feeds/packages/lang/python/python-websocket-client ./package/feeds/packages/python-websocket-client
svn co https://github.com/openwrt/packages/trunk/lang/python/python-paramiko feeds/packages/lang/python/python-paramiko
ln -sf ../../../feeds/packages/lang/python/python-paramiko ./package/feeds/packages/python-paramiko
svn co https://github.com/openwrt/packages/trunk/lang/python/python-pynacl feeds/packages/lang/python/python-pynacl
ln -sf ../../../feeds/packages/lang/python/python-pynacl ./package/feeds/packages/python-pynacl
# Beardropper
#git clone --depth 1 https://github.com/NateLol/luci-app-beardropper.git package/luci-app-beardropper
#sed -i 's/"luci.fs"/"luci.sys".net/g' package/luci-app-beardropper/luasrc/model/cbi/beardropper/setting.lua
#sed -i '/firewall/d' package/luci-app-beardropper/root/etc/uci-defaults/luci-beardropper
# Luci-app-freq
#svn co https://github.com/project-openwrt/openwrt/branches/master/package/lean/luci-app-cpufreq package/lean/luci-app-cpufreq
#patch -p1 < ../PATCH/new/package/luci-app-freq.patch
# JD-DailyBonus
git clone --depth 1 https://github.com/jerrykuku/node-request.git package/new/node-request
git clone --depth 1 https://github.com/jerrykuku/luci-app-jd-dailybonus.git package/new/luci-app-jd-dailybonus
#git clone -b develop --depth 1 https://github.com/Promix953/luci-app-jd-dailybonus.git package/new/luci-app-jd-dailybonus
# Arpbind
svn co https://github.com/nicksun98/OpenWrt_luci-app/trunk/lean/luci-app-arpbind package/lean/luci-app-arpbind
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-arpbind package/lean/luci-app-arpbind
# Adbyby
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-adbyby-plus package/lean/luci-app-adbyby-plus
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/adbyby package/lean/adbyby
# AccessControl
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-accesscontrol package/lean/luci-app-accesscontrol
#cp -rf ../PATCH/duplicate/luci-app-control-weburl ./package/new/luci-app-control-weburl
# AutoCore
svn co https://github.com/project-openwrt/openwrt/branches/master/package/lean/autocore package/lean/autocore
svn co https://github.com/project-openwrt/packages/trunk/utils/coremark feeds/packages/utils/coremark
ln -sf ../../../feeds/packages/utils/coremark ./package/feeds/packages/coremark
sed -i 's,default n,default y,g' feeds/packages/utils/coremark/Makefile
# XLnetacc
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-xlnetacc package/lean/luci-app-xlnetacc
#git clone --depth 1 https://github.com/garypang13/luci-app-xlnetacc.git package/lean/luci-app-xlnetacc
# Add iftop
rm -rf ./package/network/utils/iftop ./feeds/packages/net/iftop
svn co https://github.com/openwrt/packages/trunk/net/iftop feeds/packages/net/iftop
ln -sdf ../../../feeds/packages/net/iftop ./package/feeds/packages/iftop
# Stress-ng
svn co https://github.com/openwrt/packages/trunk/utils/stress-ng feeds/packages/utils/stress-ng
ln -sf ../../../feeds/packages/utils/stress-ng ./package/feeds/packages/stress-ng
# DDNS
#rm -rf ./feeds/packages/net/ddns-scripts
#rm -rf ./feeds/luci/applications/luci-app-ddns
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ddns-scripts_aliyun package/lean/ddns-scripts_aliyun
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ddns-scripts_dnspod package/lean/ddns-scripts_dnspod
#svn co https://github.com/openwrt/packages/branches/openwrt-18.06/net/ddns-scripts feeds/packages/net/ddns-scripts
#svn co https://github.com/openwrt/luci/branches/openwrt-18.06/applications/luci-app-ddns feeds/luci/applications/luci-app-ddns
# DnsPod DDNS
#svn co https://github.com/Tencent-Cloud-Plugins/tencentcloud-openwrt-plugin-ddns/trunk/tencentcloud_ddns package/lean/luci-app-tencentddns
# Ali DDNS
#svn co https://github.com/kenzok8/openwrt-packages/trunk/luci-app-aliddns package/new/luci-app-aliddns
# Pandownload
#svn co https://github.com/project-openwrt/openwrt/branches/master/package/lean/pandownload-fake-server package/lean/pandownload-fake-server
# Oled
#git clone -b master --depth 1 https://github.com/NateLol/luci-app-oled.git package/new/luci-app-oled
# UnblockNeteaseMusic
#git clone --depth 1 https://github.com/project-openwrt/luci-app-unblockneteasemusic.git package/new/UnblockNeteaseMusic
# Autoreboot
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-autoreboot package/lean/luci-app-autoreboot
# Moschinadns
#svn co https://github.com/QiuSimons/openwrt-packages/branches/main/mos-chinadns package/new/mos-chinadns
#svn co https://github.com/QiuSimons/openwrt-packages/branches/main/luci-app-moschinadns package/new/luci-app-moschinadns
# Argon LuCI Theme
#git clone -b master --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/new/luci-theme-argon
#git clone -b master --depth 1 https://github.com/jerrykuku/luci-app-argon-config.git package/new/luci-app-argon-config
# Edge LuCI Theme
#git clone -b master --depth 1 https://github.com/garypang13/luci-theme-edge.git package/new/luci-theme-edge
# AdGuard ( Check 01 )
#cp -rf ../openwrt-lienol/package/diy/luci-app-adguardhome ./package/new/luci-app-adguardhome
#svn co https://github.com/openwrt/packages/trunk/net/adguardhome feeds/packages/net/adguardhome
#ln -sf ../../../feeds/packages/net/adguardhome ./package/feeds/packages/adguardhome
#sed -i '/init/d' feeds/packages/net/adguardhome/Makefile
#svn co https://github.com/openwrt/packages/trunk/devel/packr feeds/packages/devel/packr
#ln -sf ../../../feeds/packages/devel/packr ./package/feeds/packages/packr
#cp -rf ../openwrt-lienol/package/diy/adguardhome ./package/new/adguardhome
#svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ntlf9t/AdGuardHome package/new/AdGuardHome
# ChinaDNS
#git clone -b luci --depth 1 https://github.com/pexcn/openwrt-chinadns-ng.git package/new/luci-app-chinadns-ng
#git clone -b master --depth 1 https://github.com/pexcn/openwrt-chinadns-ng.git package/new/chinadns-ng
# VSSR
#git clone -b master --depth 1 https://github.com/jerrykuku/luci-app-vssr package/lean/luci-app-vssr
#git clone -b master --depth 1 https://github.com/jerrykuku/lua-maxminddb package/lean/lua-maxminddb
#sed -i 's,ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305,ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256,g' package/lean/luci-app-vssr/root/usr/share/vssr/genconfig_trojan.lua
#sed -i 's,TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256,TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256,g' package/lean/luci-app-vssr/root/usr/share/vssr/genconfig_trojan.lua
# SSRP
svn co https://github.com/fw876/helloworld/trunk/luci-app-ssr-plus package/lean/luci-app-ssr-plus
#svn co https://github.com/Mattraks/helloworld/branches/Preview/luci-app-ssr-plus package/lean/luci-app-ssr-plus
rm -rf ./package/lean/luci-app-ssr-plus/po/zh_Hans
#svn co https://github.com/nicksun98/Others/trunk/luci-app-ssr-plus-181 package/lean/luci-app-ssr-plus
#sed -i 's,ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305,ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256,g' package/lean/luci-app-ssr-plus/root/usr/share/shadowsocksr/gentrojanconfig.lua
#sed -i 's,TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256,TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256,g' package/lean/luci-app-ssr-plus/root/usr/share/shadowsocksr/gentrojanconfig.lua
# Add Extra Proxy Ports and Change Lists
pushd package/lean/luci-app-ssr-plus/root/etc/init.d
sed -i 's/143/143,25,5222/' shadowsocksr
sed -i 's,ispip.clang.cn/all_cn,cdn.jsdelivr.net/gh/QiuSimons/Chnroute/dist/chnroute/chnroute,' shadowsocksr
sed -i 's,YW5vbnltb3Vz/domain-list-community@release/gfwlist,Loyalsoldier/v2ray-rules-dat@release/gfw,' shadowsocksr
popd
#rm -rf ./package/lean/luci-app-ssr-plus/root/etc/init.d/shadowsocksr
#wget -P package/lean/luci-app-ssr-plus/root/etc/init.d https://raw.githubusercontent.com/nicksun98/Others/master/luci-app-ssr-plus-177-1/root/etc/init.d/shadowsocksr
# SSRP Dependies
rm -rf ./feeds/packages/net/kcptun
rm -rf ./feeds/packages/net/shadowsocks-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shadowsocksr-libev package/lean/shadowsocksr-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/pdnsd-alt package/lean/pdnsd
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/v2ray package/lean/v2ray
svn co https://github.com/fw876/helloworld/trunk/xray-core package/lean/xray-core
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/kcptun package/lean/kcptun
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/v2ray-plugin package/lean/v2ray-plugin
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/srelay package/lean/srelay
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/microsocks package/lean/microsocks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/dns2socks package/lean/dns2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/redsocks2 package/lean/redsocks2
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/proxychains-ng package/lean/proxychains-ng
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipt2socks package/lean/ipt2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/simple-obfs package/lean/simple-obfs
svn co https://github.com/coolsnowwolf/packages/trunk/net/shadowsocks-libev package/lean/shadowsocks-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/trojan package/lean/trojan
#svn co https://github.com/fw876/helloworld/trunk/trojan-go package/lean/trojan-go
#svn co https://github.com/project-openwrt/openwrt/branches/master/package/lean/tcpping package/lean/tcpping
svn co https://github.com/fw876/helloworld/trunk/tcping package/lean/tcping
svn co https://github.com/fw876/helloworld/trunk/naiveproxy package/lean/naiveproxy
#svn co https://github.com/fw876/helloworld/trunk/ipt2socks-alt package/lean/ipt2socks-alt
# Merge Pull Requests from Mattraks
#pushd package/lean
#wget -qO - https://patch-diff.githubusercontent.com/raw/fw876/helloworld/pull/271.patch | patch -p1
#popd
# Passwall
#svn co https://github.com/xiaorouji/openwrt-passwall/trunk/luci-app-passwall package/new/luci-app-passwall
#cp -f ../PATCH/new/script/move_2_services.sh ./package/new/luci-app-passwall/move_2_services.sh
#pushd package/new/luci-app-passwall
#bash move_2_services.sh
#popd
#sed -i 's,ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305,ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256,g' package/new/luci-app-passwall/luasrc/model/cbi/passwall/server/api/trojan.lua
#sed -i 's,TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256,TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256,g' package/new/luci-app-passwall/luasrc/model/cbi/passwall/server/api/trojan.lua
#rm -rf ./feeds/packages/net/https-dns-proxy
#svn co https://github.com/Lienol/openwrt-packages/trunk/net/https-dns-proxy feeds/packages/net/https-dns-proxy
#svn co https://github.com/xiaorouji/openwrt-package/trunk/package/tcping package/new/tcping
#svn co https://github.com/xiaorouji/openwrt-package/trunk/package/trojan-go package/new/trojan-go
#svn co https://github.com/xiaorouji/openwrt-package/trunk/package/brook package/new/brook
#svn co https://github.com/xiaorouji/openwrt-package/trunk/package/trojan-plus package/new/trojan-plus
#svn co https://github.com/xiaorouji/openwrt-package/trunk/package/ssocks package/new/ssocks
#svn co https://github.com/xiaorouji/openwrt-passwall/trunk/xray package/new/xray
# Luci-app-cpulimit
#cp -rf ../PATCH/duplicate/luci-app-cpulimit ./package/lean/luci-app-cpulimit
#svn co https://github.com/project-openwrt/openwrt/branches/master/package/ntlf9t/cpulimit package/lean/cpulimit
# Subconverter
#svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/subconverter package/new/subconverter
#svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/jpcre2 package/new/jpcre2
#svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/rapidjson package/new/rapidjson
#svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/duktape package/new/duktape
# UU Gamebooster
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-uugamebooster package/lean/luci-app-uugamebooster
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/uugamebooster package/lean/uugamebooster
# Ram-free
svn co https://github.com/nicksun98/OpenWrt_luci-app/trunk/lean/luci-app-ramfree package/lean/luci-app-ramfree
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-ramfree package/lean/luci-app-ramfree
# USB-Printer
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-usb-printer package/lean/luci-app-usb-printer
# Wrtbwmon
#git clone -b master --depth 1 https://github.com/brvphoenix/wrtbwmon.git package/new/wrtbwmon
#git clone -b master --depth 1 https://github.com/brvphoenix/luci-app-wrtbwmon.git package/new/luci-app-wrtbwmon
# Luci-app-netdata
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-netdata package/lean/luci-app-netdata
# OpenClash
#git clone -b master --depth 1 https://github.com/vernesong/OpenClash.git package/new/luci-app-openclash
# SeverChan
#git clone -b master --depth 1 https://github.com/tty228/luci-app-serverchan.git package/new/luci-app-serverchan
#svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/network/utils/iputils package/network/utils/iputils
# SmartDNS ( Check 01 )
#cp -rf ../packages-lienol/net/smartdns ./package/new/smartdns
#mkdir package/new/smartdns
#wget -P package/new/smartdns/ https://github.com/HiGarfield/lede-17.01.4-Mod/raw/master/package/extra/smartdns/Makefile
#sed -i 's,files/etc/config,$(PKG_BUILD_DIR)/package/openwrt/files/etc/config,g' ./package/new/smartdns/Makefile
#cp -rf ../luci-lienol/applications/luci-app-smartdns ./package/new/luci-app-smartdns
#sed -i 's,include ../..,include $(TOPDIR)/feeds/luci,g' ./package/new/luci-app-smartdns/Makefile
# OAF
#git clone -b master --depth 1 https://github.com/destan19/OpenAppFilter.git package/new/OpenAppFilter
# Extra Dependies (May not be used)
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libnetfilter-log package/libs/libnetfilter-log
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libnetfilter-queue package/libs/libnetfilter-queue
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libnetfilter-cttimeout package/libs/libnetfilter-cttimeout
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libnetfilter-cthelper package/libs/libnetfilter-cthelper
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/utils/fuse package/utils/fuse
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/network/services/samba36 package/network/services/samba36
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libconfig package/libs/libconfig
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libusb-compat package/libs/libusb-compat
svn co https://github.com/openwrt/packages/trunk/libs/nghttp2 feeds/packages/libs/nghttp2
ln -sf ../../../feeds/packages/libs/nghttp2 ./package/feeds/packages/nghttp2
svn co https://github.com/openwrt/packages/trunk/libs/libcap-ng feeds/packages/libs/libcap-ng
ln -sf ../../../feeds/packages/libs/libcap-ng ./package/feeds/packages/libcap-ng
rm -rf ./feeds/packages/utils/collectd
svn co https://github.com/openwrt/packages/trunk/utils/collectd feeds/packages/utils/collectd
svn co https://github.com/openwrt/packages/trunk/utils/usbutils feeds/packages/utils/usbutils
ln -sf ../../../feeds/packages/utils/usbutils ./package/feeds/packages/usbutils
svn co https://github.com/openwrt/packages/trunk/utils/hwdata feeds/packages/utils/hwdata
ln -sf ../../../feeds/packages/utils/hwdata ./package/feeds/packages/hwdata
rm -rf ./feeds/packages/net/dnsdist
svn co https://github.com/openwrt/packages/trunk/net/dnsdist feeds/packages/net/dnsdist
svn co https://github.com/openwrt/packages/trunk/libs/h2o feeds/packages/libs/h2o
ln -sf ../../../feeds/packages/libs/h2o ./package/feeds/packages/h2o
svn co https://github.com/openwrt/packages/trunk/libs/libwslay feeds/packages/libs/libwslay
ln -sf ../../../feeds/packages/libs/libwslay ./package/feeds/packages/libwslay
# Addition-Trans-zh-master
cp -rf ../PATCH/duplicate/addition-trans-zh-r2s ./package/lean/lean-translate
# Addition-Trans-zh-master from QiuSimons with individuation changes
notExce(){
MY_Var=package/lean/lean-translate
git clone -b master --single-branch https://github.com/QiuSimons/addition-trans-zh ${MY_Var}
sed -i '/uci .* dhcp/d' ${MY_Var}/files/zzz-default-settings
sed -i '/chinadnslist\|ddns\|upnp\|netease\|argon\|openwrt_luci\|rng\|openclash\|dockerman/d' ${MY_Var}/files/zzz-default-settings
sed -i "4a uci set luci.main.lang='en'" ${MY_Var}/files/zzz-default-settings
sed -i '5a uci commit luci' ${MY_Var}/files/zzz-default-settings
sed -i '/^[[:space:]]*$/d' ${MY_Var}/files/zzz-default-settings
unset MY_Var
}

# IPv6-helper
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipv6-helper package/lean/ipv6-helper
# IPSec
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-ipsec-vpnd package/lean/luci-app-ipsec-vpnd
# Zerotier
#svn co https://github.com/project-openwrt/openwrt/branches/master/package/lean/luci-app-zerotier package/lean/luci-app-zerotier
#cp -f ../PATCH/new/script/move_2_services.sh ./package/lean/luci-app-zerotier/move_2_services.sh
#pushd package/lean/luci-app-zerotier
#bash move_2_services.sh
#popd
#rm -rf ./feeds/packages/net/zerotier/files/etc/init.d/zerotier
# Revert UPNP
#rm -rf ./feeds/packages/net/miniupnpd
#svn co https://github.com/coolsnowwolf/packages/trunk/net/miniupnpd feeds/packages/net/miniupnpd
# KMS(Cannot be used illegally)
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-vlmcsd package/lean/luci-app-vlmcsd
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/vlmcsd package/lean/vlmcsd
# FRP
#rm -f ./feeds/luci/applications/luci-app-frps
#rm -f ./feeds/luci/applications/luci-app-frpc
#rm -rf ./feeds/packages/net/frp
#rm -f ./package/feeds/packages/frp
#git clone --depth 1 https://github.com/lwz322/luci-app-frps.git package/lean/luci-app-frps
#git clone --depth 1 https://github.com/kuoruan/luci-app-frpc.git package/lean/luci-app-frpc
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-frps package/lean/luci-app-frps
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-frpc package/lean/luci-app-frpc
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/frp package/lean/frp
# Oray
#svn co https://github.com/teasiu/dragino2/trunk/package/teasiu/luci-app-phtunnel package/new/luci-app-phtunnel
#svn co https://github.com/teasiu/dragino2/trunk/package/teasiu/luci-app-oray package/new/luci-app-oray
#svn co https://github.com/teasiu/dragino2/trunk/package/teasiu/phtunnel package/new/phtunnel

# Crypto
echo '
CONFIG_ARM64_CRYPTO=y
CONFIG_CRYPTO_AES_ARM64=y
CONFIG_CRYPTO_AES_ARM64_BS=y
CONFIG_CRYPTO_AES_ARM64_CE=y
CONFIG_CRYPTO_AES_ARM64_CE_BLK=y
CONFIG_CRYPTO_AES_ARM64_CE_CCM=y
CONFIG_CRYPTO_AES_ARM64_NEON_BLK=y
CONFIG_CRYPTO_CHACHA20=y
CONFIG_CRYPTO_CHACHA20_NEON=y
CONFIG_CRYPTO_CRYPTD=y
CONFIG_CRYPTO_GF128MUL=y
CONFIG_CRYPTO_GHASH_ARM64_CE=y
CONFIG_CRYPTO_SHA1=y
CONFIG_CRYPTO_SHA1_ARM64_CE=y
CONFIG_CRYPTO_SHA256_ARM64=y
CONFIG_CRYPTO_SHA2_ARM64_CE=y
# CONFIG_CRYPTO_SHA3_ARM64 is not set
CONFIG_CRYPTO_SHA512_ARM64=y
# CONFIG_CRYPTO_SHA512_ARM64_CE is not set
CONFIG_CRYPTO_SIMD=y
# CONFIG_CRYPTO_SM3_ARM64_CE is not set
# CONFIG_CRYPTO_SM4_ARM64_CE is not set
' >> ./target/linux/rockchip/armv8/config-5.4

## Ending
# Lets Fuck
mkdir package/base-files/files/usr/bin
cp -f ../PATCH/new/script/fuck package/base-files/files/usr/bin/fuck
#cp -f ../PATCH/new/script/chinadnslist package/base-files/files/usr/bin/chinadnslist
# Add cputemp.sh
wget https://raw.githubusercontent.com/nicksun98/Others/master/cputemp.sh -O package/base-files/files/bin/cputemp.sh
# Conntrack_Max
sed -i 's/16384/65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# Remove config
rm -rf .config
# Import configs to files
#cp -rf ../PATCH/R2S/files ./files

exit 0
