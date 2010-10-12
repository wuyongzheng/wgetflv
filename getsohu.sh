#!/bin/bash

if [ $# -ne 2 ] ; then
	echo getsohu.sh http://tv.sohu.com/20100502/n271886821.shtml sanguo-01
	exit
fi

rm -f /tmp/getsohu1.html
if ! wget -q -O /tmp/getsohu1.html "$1" ; then
	echo wget $1 failed
	exit
fi
if grep -q -i '<meta .*charset *= *"*gb' /tmp/getsohu1.html ; then
	iconv -c -f gbk -t utf-8 /tmp/getsohu1.html | dos2unix > /tmp/getsohu1.x
	mv /tmp/getsohu1.x /tmp/getsohu1.html
else
	dos2unix -q /tmp/getsohu1.html
fi

if grep -q 'var vid="[0-9]*";$' /tmp/getsohu1.html ; then
	vid=`grep -m 1 'var vid="[0-9]*";$' /tmp/getsohu1.html | sed -e 's/.*="//g' -e 's/";.*//g'`
else
	echo unexpected content of $1. check /tmp/getsohu1.html
fi

rm -f /tmp/getsohu2.txt
if ! wget -q -O /tmp/getsohu2.txt "http://hot.vrs.sohu.com/vrs_flash.action?vid=$vid" ; then
	echo wget "http://hot.vrs.sohu.com/vrs_flash.action?vid=$vid" failed.
	exit
fi

mp4list=`binreplace -r '"' '\n' /tmp/getsohu2.txt | grep '^http://.*mp4$'`
# it should be a list of mp4 urls. example:
# http://data.vod.itc.cn/tv/20100505/d2f89e5b-e6a4-4ddf-a765-e006028926c0.mp4

if [ "x$mp4list" = x ] ; then
	echo "unexpected content of http://hot.vrs.sohu.com/vrs_flash.action?vid=$vid". check /tmp/getsohu2.txt
	exit
fi

rm -f $2.mp4
for i in $mp4list ; do
	rm -f $2-curr.mp4
	if ! wget -q -U 'Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.2.10) Gecko/20100914 Firefox/3.6.10' -O $2-curr.mp4 "$i" ; then
		echo wget $i failed
		exit
	fi

	if [ -f $2.mp4 ] ; then
		MP4Box -cat $2-curr.mp4 $2.mp4
		rm $2-curr.mp4
	else
		mv $2-curr.mp4 $2.mp4
	fi
done
