#!/bin/bash 
set -e
DEST="tags.html"
if [ -f "$1" ] ; then
	echo "Output in $DEST"
else
	echo "The first argument must be the file with the html code"
	echo "From http://theanarchistlibrary.org/admin/content/taxonomy/1"
	echo "and following"
	exit 1 
fi
grep -e ' *<tr class="draggable .*"><td><a href=' $1 | \
  sed -e 's|^ *<tr class="draggable .\{3,4\}"><td>\(<a href=[^<>]*>[^<>]*</a>\).*$|<li>\1</li>|' > tmp.html

echo "<ul>" > $DEST
cat tmp.html >> $DEST
echo "</ul>" >> $DEST
echo "<br />" >> $DEST
echo "<a href=\"#\">[top]</a>" >> $DEST

rm tmp.html

