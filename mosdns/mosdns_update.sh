#!/bin/bash
cp /var/mosdns/geosite_cn.txt /var/mosdns/geosite_cn.txt.bak
cp /var/mosdns/geoip_cn.txt /var/mosdns/geoip_cn.txt.bak
echo "下载geoip和geosite"
wget -O /tmp/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
wget -O /tmp/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat

geoipflag=true
geositeflag=true

if [ $geoipflag == true ]; then
	if [ -e /tmp/geoip.dat ]; then
		if [ -s /tmp/geoip.dat ]; then
			echo "下载成功"
		else
			echo "下载失败"
			geoipflag=false
		fi
	else
		echo "不存在"
		geoipflag=false
	fi
else
	wget -O /tmp/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
fi

 
if [ $geositeflag == true ]; then
	if [ -e /tmp/geosite.dat ]; then
		if [ -s /tmp/geosite.dat ]; then
			echo "下载成功"
		else
			echo "下载失败"
			geositeflag=false
		fi
	else
		echo "不存在"
		geositeflag=false
	fi
else
	wget -O /tmp/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
fi

if [ $geoipflag == true ] && [ $geositeflag==true ]; then
	systemctl stop mosdns.service
	rm -rf /var/mosdns/geoip.dat
	rm -rf /var/mosdns/geosite.dat
	/opt/v2dat unpack geoip -o /var/mosdns -f cn /tmp/geoip.dat
	/opt/v2dat unpack geosite -o /var/mosdns -f cn /tmp/geosite.dat
	systemctl start mosdns.service
else
	echo "不更新"
fi

sleep 3
if systemctl status mosdns.service |grep -q "running"; then
	echo "更新完成"
	rm -rf /tmp/geoip.dat
	rm -rf /tmp/geosite.dat
	rm -rf /var/mosdns/geosite_cn.txt.bak
	rm -rf /var/mosdns/geoip_cn.txt.bak
else
	echo "似乎哪里暴毙了,开始恢复"
	rm -rf /tmp/geoip.dat
	rm -rf /tmp/geosite.dat
	cp /var/mosdns/geoip_cn.txt.bak /var/mosdns/geoip_cn.txt
	cp /var/mosdns/geosite_cn.txt.bak /var/mosdns/geosite_cn.txt
	rm -rf /var/mosdns/geosite_cn.txt.bak
	rm -rf /var/mosdns/geoip_cn.txt.bak
	systemctl start mosdns.service
fi
