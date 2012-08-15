#!/bin/bash

if [ $# -ne 2 ] ; then
	echo gettudou-iid.sh 37789103 outbase
	exit
fi

iid=$1
outbase=$2

rm -f /tmp/downtudou1.xml
if ! wget -q -O /tmp/downtudou1.xml "http://v2.tudou.com/v?it=$iid" ; then
	echo wget "http://v2.tudou.com/v?it=$iid" failed
	exit
fi

if grep -q -i '<meta .*charset *= *"*gb' /tmp/downtudou1.xml ; then
	dos2unix </tmp/downtudou1.xml | iconv -c -f gbk -t utf-8 >/tmp/downtudoux
	mv /tmp/downtudoux /tmp/downtudou1.xml
else
	dos2unix -q /tmp/downtudou1.xml
fi

cat /tmp/downtudou1.xml | \
	binreplace -r '\n' ' ' -r '<f ' '\n<f ' -r '</f>' '</f>\n' | \
	grep size= | \
	grep 'http://.*[fm][l4]v.key=' | \
	sed -e 's/.*size="//g' -e 's/">/\t/g' -e 's/<.*//g' -e 's/&amp;/\&/g' | \
	sort -n -r | \
	cut -f 2 | \
	head -n 1 > /tmp/downtudou2.txt

if ! grep -q '^http://.*[fm][l4]v.key=' /tmp/downtudou2.txt ; then
	echo "unexpected content of http://v2.tudou.com/v?it=$iid"
	exit
fi

url3=`cat /tmp/downtudou2.txt`

if grep -q 'f[l4]v.key=' /tmp/downtudou2.txt ; then
	outfile="$outbase.flv"
else
	outfile="$outbase.mp4"
fi

if ! wget --retry-connrefused -t 0 --progress=dot:mega -O "$outfile" "$url3" ; then
	echo wget "$url3" failed
	exit
fi

rm /tmp/downtudou1.xml /tmp/downtudou2.txt
