#!/bin/bash

if [ $# -ne 2 ] ; then
	echo "Usage $0 url filename_noext"
	echo Usage $0 http://news.cntv.cn/program/xwlb/20100726/103905.shtml xwlb-0726
	echo Usage $0 http://bugu.cntv.cn/news/china/xinwenlianbo/classpage/video/20100726/100921.shtml xwlb-0726
	echo Output is saved in xwlb-0726.mp4
	echo Usage $0 url _prefetch_
	echo Try to download the dirst byte and throw away.
	echo Since CNTV uses akamai cache. This one prefetches the file.
	exit 1
fi

rm -f /tmp/cntv1.txt
if ! wget -q -O /tmp/cntv1.txt "$1" ; then
	echo wget $1 failed
	exit 1
fi

dos2unix </tmp/cntv1.txt | iconv -c -f gbk -t utf8 >/tmp/cntvx.txt
mv /tmp/cntvx.txt /tmp/cntv1.txt

if ! grep -q 'fo.addVariable("videoCenterId","................................");' /tmp/cntv1.txt ; then
	echo $1 invalid. check /tmp/cntv1.txt
	exit 1
fi
#TODO: for xiyou, it's like fo.addVariable("id", "7d5f2c8e-f2bc-11df-9117-001e0bbb2442");
#      the next fetch would be http://vi.xiyou.cntv.cn/api/get-flash-videoinfo.php?videoId=7d5f2c8e-f2bc-11df-9117-001e0bbb2442

vcid=`grep 'fo.addVariable("videoCenterId","................................");' /tmp/cntv1.txt | head -n 1 | sed -e 's/.*videoCenterId","//g' -e 's/".*//g'`

rm -f /tmp/cntv2.txt
if ! wget -q -O /tmp/cntv2.txt "http://vdd.player.cntv.cn/index.php?pid=$vcid" ; then
	echo wget "http://vdd.player.cntv.cn/index.php?pid=$vcid" failed
	exit 1
fi

#cat /tmp/cntv2.txt | tr '"' '\n' | grep '^http:.*\.mp4$' | tr -d '\\' | sort -u -V > /tmp/cntv3.txt
binreplace -r '"chapters' '\n"chapters' -r '],' '],\n' /tmp/cntv2.txt | grep chapters | tail -n 1 | tr '"' '\n' | grep '^http:.*\.mp4$' | tr -d '\\' > /tmp/cntv3.txt

if [ `wc -c < /tmp/cntv3.txt` -lt 10 ] || grep -q ' ' /tmp/cntv3.txt ; then
	echo "http://vdd.player.cntv.cn/index.php?pid=$vcid" invalid. check /tmp/cntv2.txt
	exit 1
fi

if [ "_prefetch_" = "$2" ] ; then
	for i in `cat /tmp/cntv3.txt` ; do
		wget -O - -q "$i" | head -c 1 >/dev/null 2>&1
	done
	exit 0
fi

rm -f $2.mp4
for i in `cat /tmp/cntv3.txt` ; do
	rm -f $2-curr.mp4
	if ! wget --progress=dot:mega -O $2-curr.mp4 "$i" ; then
		echo wget $i failed
		exit 1
	fi

	MP4Box -cat $2-curr.mp4 $2.mp4
	rm $2-curr.mp4
done
