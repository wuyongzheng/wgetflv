#!/bin/bash

if [ $# -ne 1 ] ; then
	echo getxiami-artist.sh 1483
	exit
fi

songids=""
for (( i=1 ; i<=5 ; i++ )) ; do
	thisbatch=`wget -q -O - http://www.xiami.com/artist/top/id/$1/page/$i | grep 'href="/song/[0-9]' | sed -e 's/.*href=..song.//g' -e 's/".*//g'`
	if [ -z "$thisbatch" ] ; then
		break;
	fi
	songids="$songids $thisbatch"
done

for songid in `echo $songids | sort -u -n` ; do
	wget -q -O - "http://www.xiami.com/song/playlist/id/$songid/object_name/default/object_id/0" > /tmp/xiami-song.xml
	location=`grep "<location>" /tmp/xiami-song.xml | sed -e 'sx</.*xxg' -e 's/.*>//g'`
	url=`java DeXiami "$location"`
	if [ -z "$url" ] ; then
		url=yyy
	fi
	for f in song_id album_id title album_name artist lyric ; do
		x=`grep "<$f>" /tmp/xiami-song.xml | sed -e 's/<..CDATA.//g' -e 's/\]\]>//g' -e 'sx</.*xxg' -e 's/.*>//g'`
		if [ -z "$x" ] ; then
			x=xxx
		fi
		echo -n "$x"$'\t'
	done
	echo $url
done
