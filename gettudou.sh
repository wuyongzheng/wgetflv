#!/bin/bash

if [ $# -ne 1 -a $# -ne 2 ] ; then
	echo downtudou.sh http://www.tudou.com/programs/view/vHHKAcffJok/
	echo downtudou.sh http://hd.tudou.com/program/25105/
	echo downtudou.sh http://www.tudou.com/playlist/p/a61420.html?iid=37789103
	echo downtudou.sh http://www.tudou.com/playlist/p/a61420.html?iid=37789103 shisansheng14
	exit
fi

url1="$1";
if [ $# -eq 2 ] ; then
	title="$2";
fi

rm -f /tmp/downtudou1.html
if ! wget -q -O /tmp/downtudou1.html "$url1" ; then
	echo wget "$url1" failed
	exit
fi

if grep -q -i '<meta .*charset *= *"*gb' /tmp/downtudou1.html ; then
	dos2unix </tmp/downtudou1.html | iconv -c -f gbk -t utf-8 >/tmp/downtudoux
	mv /tmp/downtudoux /tmp/downtudou1.html
else
	dos2unix -q /tmp/downtudou1.html
fi

if echo "$url1" | grep -q 'iid=[0-9]' ; then #TODO no need to download url1
	iid=`echo "$url1" | sed -e 's/.*iid=\([0-9]*\).*/\1/g'`
elif grep -q 'var iid = ' /tmp/downtudou1.html ; then
	iid=`grep -m 1 'var iid = ' /tmp/downtudou1.html | sed 's/.* //g'`
elif grep -q 'iid: "[1-9][0-9]*",$' /tmp/downtudou1.html ; then
	iid=`grep -m 1 'iid: "[1-9][0-9]*",$' /tmp/downtudou1.html | sed -e 's/",//g' -e 's/.*"//g'`
else
	echo unexpected content of "$url1"
	exit
fi

if [ "x$title" = x ] ; then
	if grep -q 'title: ".*",$' /tmp/downtudou1.html ; then
		title=`grep 'title: ".*",$' /tmp/downtudou1.html | sed -e 's/.*title: "//g' -e 's/".*//g'`
	elif grep -q ',kw = ".*"' /tmp/downtudou1.html ; then
		title=`grep ',kw = ".*"' /tmp/downtudou1.html | sed -e 's/.*,kw = "//g' -e 's/".*//g'`
	else
		title=$iid
	fi
	title=`echo $title | sed -e 'sx/x.xg'`
fi

#url2="http://v2.tudou.com/v2/cdn?id=$iid&noCatch=123&safekey=IAlsoNeverKnow"
url2="http://v2.tudou.com/v?it=$iid"

rm -f /tmp/downtudou2.html
if ! wget -q -O /tmp/downtudou2.xml "$url2" ; then
	echo wget "$url2" failed
	exit
fi
if grep -q -i '<meta .*charset *= *"*gb' /tmp/downtudou2.xml ; then
	dos2unix </tmp/downtudou2.xml | iconv -c -f gbk -t utf-8 >/tmp/downtudoux
	mv /tmp/downtudoux /tmp/downtudou2.xml
else
	dos2unix -q /tmp/downtudou2.xml
fi

cat /tmp/downtudou2.xml | \
	binreplace -r '\n' ' ' -r '<f ' '\n<f ' -r '</f>' '</f>\n' | \
	grep size= | \
	grep 'http://.*[fm][l4]v.key=' | \
	sed -e 's/.*size="//g' -e 's/">/\t/g' -e 's/<.*//g' -e 's/&amp;/\&/g' | \
	sort -n -r | \
	cut -f 2 | \
	head -n 1 > /tmp/downtudou3.txt

if ! grep -q '^http://.*[fm][l4]v.key=' /tmp/downtudou3.txt ; then
	echo "unexpected content of $url2"
	exit
fi

url3=`cat /tmp/downtudou3.txt`

if grep -q 'f[l4]v.key=' /tmp/downtudou3.txt ; then
	ext=flv
else
	ext=mp4
fi

if [ -e "$title.$ext" ] ; then
	i=1
	while [ -e "$title.$i.$ext" ] ; do
		i=`expr $i + 1`
	done
	outfile="$title.$i.$ext"
else
	outfile="$title.$ext"
fi

if ! wget --retry-connrefused -t 0 --progress=dot:mega -O "$outfile" "$url3" ; then
	echo wget "$url3" failed
	exit
fi

rm /tmp/downtudou1.html /tmp/downtudou2.xml /tmp/downtudou3.txt
