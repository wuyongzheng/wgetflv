#!/bin/bash

if [ $# -ne 1 ] ; then
	echo bash getxiami-artist-albums.sh 6997
	echo env sleep=2 bash getxiami-artist-albums.sh 6997
	exit
fi

albumids=""
for (( i=1 ; i<=20 ; i++ )) ; do
	thisbatch=`wget -q -O - http://www.xiami.com/artist/album/id/$1/d//p//page/$i | grep 'href="/album/[0-9]' | sed -e 's/.*href=..album.//g' -e 's/".*//g'`
	if [ -n "$sleep" ] ; then sleep $sleep ; fi
	if [ -z "$thisbatch" ] ; then break ; fi
	#echo $thisbatch
	next=`echo $albumids $thisbatch | tr ' ' '\n' | sort -u -n`
	if [ "$albumids" = "$next" ] ; then
		break
	fi
	albumids=$next
done

songids=""
for i in $albumids ; do
	thisbatch=`wget -q -O - http://www.xiami.com/album/$i | grep 'href="/song/[0-9]' | sed -e 's/.*href=..song.//g' -e 's/".*//g'`
	if [ -n "$sleep" ] ; then sleep $sleep ; fi
	songids="$songids $thisbatch"
done
songids=`echo $songids | tr ' ' '\n' | sort -u -n`

for songid in `echo $songids | sort -u -n` ; do
	wget -q -O - "http://www.xiami.com/song/playlist/id/$songid/object_name/default/object_id/0" > /tmp/xiami-song.xml
	if [ -n "$sleep" ] ; then sleep $sleep ; fi
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
