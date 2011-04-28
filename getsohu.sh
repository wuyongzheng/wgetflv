#!/bin/bash

if [ $# -ne 2 ] ; then
	echo getsohu.sh http://tv.sohu.com/20100502/n271886821.shtml sanguo-01
	echo getsohu.sh http://tv.sohu.com/20100502/n271886821.shtml sanguo-01.mp4
	echo getsohu.sh http://tv.sohu.com/20100502/n271886821.shtml sanguo-01.mkv
	exit
fi

if [ $2 != `basename $2 .mp4` ] ; then
	base=`basename $2 .mp4`
	ext=mp4
elif [ $2 != `basename $2 .mkv` ] ; then
	base=`basename $2 .mkv`
	ext=mkv
else
	base=$2
	ext=mp4
fi

if [ $ext = mp4 ] ; then
	if ! type -P MP4Box >/dev/null 2>&1 ; then echo MP4Box not found ; exit ; fi
else
	if ! type -P mkvmerge >/dev/null 2>&1 ; then echo mkvmerge not found ; exit ; fi
fi
if ! type -P json-liner >/dev/null 2>&1 ; then echo json-liner not found ; exit ; fi

if [ "x$getsohusid" = x ] ; then
	tmpre=/tmp/getsohu
else
	tmpre=/tmp/getsohu-$getsohusid
fi

vid=`wget -q -O - "$1" | iconv -f gbk -t utf8 | dos2unix | grep -m 1 'var vid="[1-9][0-9]*";$' | sed -e 's/.*="//g' -e 's/";.*//g'`
if [ -z "$vid" ] ; then
	echo unexpected content of $1.
	exit 1
fi

rm -f $tmpre.json
if ! wget -q -O $tmpre.json "http://hot.vrs.sohu.com/vrs_flash.action?vid=$vid" ; then
	echo wget "http://hot.vrs.sohu.com/vrs_flash.action?vid=$vid" failed.
	exit 1
fi

# It should be a json file. The array pointed by "clipsURL" is what I want.
# Example:
# {"prot":2,"allot":"220.181.61.229","tn":5,"sp":1024,"status":1,"play":1,"pL":30,
# "url":"http://tv.sohu.com/20090701/n264901824.shtml","uS":-1,"fms":0,
# "data":{"tvName":"刀锋1937第5集","ch":"tv","fps":25,"ipLimit":0,"width":0,
# "clipsURL":["http://data.vod.itc.cn/tv/20090701/ea8269a6-1c3e-4a71-af49-50f4bf351ead.mp4",
# "http://data.vod.itc.cn/tv/20090701/46c03c38-7cc7-40d6-a0bb-78c0bb93236b.mp4",
# ...

allot=`json-liner -0 10 -i $tmpre.json | grep /%allot | cut -f 2`
prot=`json-liner -0 10 -i $tmpre.json | grep /%prot | cut -f 2`

for (( i=10 ; ; i++ )) ; do
	clipsURL=`json-liner -0 10 -i $tmpre.json | grep /%data/%clipsURL/@$i | head -n 1 | cut -f 2`
	new=`json-liner -0 10 -i $tmpre.json | grep /%data/%su/@$i | head -n 1 | cut -f 2`
	if [ -z "$clipsURL" -o -z "$new" ] ; then
		break
	fi

	file=`echo $clipsURL | sed -e 's/^http:..[a-z.]*//g'`

	bars=`wget -O - -q "http://$allot/?prot=$prot&file=$file&new=$new"`
	if ! echo "$bars" | grep -q '^http://' ; then
		echo unknown bars: $bars
		exit 1
	fi

	mp4url1=`echo $bars | cut -d \| -f 1`
	mp4url2=`echo $bars | cut -d \| -f 4`
	mp4url="$mp4url1/$new?key=$mp4url2"
	if ! wget -O "$base-$i.mp4" -U 'Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.2.16) Gecko/20110319 Firefox/3.6.16' "$mp4url" ; then
		echo wget "$base-$i.mp4" failed
		exit 1
	fi
	mp4list="$mp4list -cat $base-$i.mp4"
	mkvlist="$mkvlist + $base-$i.mp4"
done

if [ $ext = mp4 ] ; then
	cmd=`echo "$mp4list" | sed -e "s/^ -cat /MP4Box -new $base.$ext -add /"`
else
	cmd=`echo "$mkvlist" | sed -e "s/^ + /mkvmerge -o $base.$ext --append-mode file /"`
fi
echo $cmd
$cmd

rm -f $base-??.mp4
