#!/bin/bash

if [ $# -ne 2 ] ; then
	echo "Usage $0 [filename_noext] [url]"
	echo Usage $0 xwlb-0726 http://news.cntv.cn/program/xwlb/20100726/103905.shtml
	echo Usage $0 xwlb-0726 http://bugu.cntv.cn/news/china/xinwenlianbo/classpage/video/20100726/100921.shtml
	echo Output is saved in xwlb-0726.mp4
	exit 1
fi

rm -f /tmp/cntv1.txt
if ! wget -q -O /tmp/cntv1.txt "$2" ; then
	echo wget $2 failed
	exit 1
fi

dos2unix </tmp/cntv1.txt | iconv -c -f gbk -t utf8 >/tmp/cntvx.txt
mv /tmp/cntvx.txt /tmp/cntv1.txt

if ! grep -q 'fo.addVariable("videoCenterId","................................");' /tmp/cntv1.txt ; then
	echo $2 invalid. check /tmp/cntv1.txt
	exit 1
fi

vcid=`grep 'fo.addVariable("videoCenterId","................................");' /tmp/cntv1.txt | head -n 1 | sed -e 's/.*videoCenterId","//g' -e 's/".*//g'`

rm -f /tmp/cntv2.txt
if ! wget -q -O /tmp/cntv2.txt "http://vdd.player.cntv.cn/index.php?pid=$vcid" ; then
	echo wget "http://vdd.player.cntv.cn/index.php?pid=$vcid" failed
	exit 1
fi

if ! cat /tmp/cntv2.txt | tr '\"' '\n' | grep -q '^http:.*\.mp4$' ; then
	echo "http://vdd.player.cntv.cn/index.php?pid=$vcid" invalid. check /tmp/cntv2.txt
	echo 1
fi

cat /tmp/cntv2.txt | tr '"' '\n' | grep '^http:.*\.mp4$' | tr -d '\\' | sort -u -V > /tmp/cntv3.txt

rm -f $1.mp4
for i in `cat /tmp/cntv3.txt` ; do
	rm -f $1-curr.mp4
	if ! wget -q -O $1-curr.mp4 "$i" ; then
		echo wget $i failed
		exit 1
	fi

	if [ -f $1.mp4 ] ; then
		MP4Box -cat $1-curr.mp4 $1.mp4
		rm $1-curr.mp4
	else
		mv $1-curr.mp4 $1.mp4
	fi
done
