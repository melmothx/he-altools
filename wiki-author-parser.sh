#!/bin/bash
# This file is missing a lot of fucking comments. Who wrote it?

set -e
# if [ -f "$1" ] ; then
# 	echo "Output in authors.html"
# else
# 	echo "The first argument must be the file with the wiki code"
# 	echo "http://wiki.theanarchistlibrary.org/index.php/Uploads_sorted_by_Authors"
# 	exit 1 
# fi
echo -n "Username (^C to quit): " && read USERNAME
echo -n "Password (^C to quit): " && read PASSWORD

DUMPFILE=authors.wiki

# download the page and filter it, replacing authors.wiki, so we have it in the
# git and can check if we screwed up


wget -O- "http://$USERNAME:$PASSWORD@wiki.theanarchistlibrary.org/index.php?title=Uploads_sorted_by_Authors&action=edit" | \
  sed -e "1,/<textarea/d" | \
  sed -e '/<\/textarea/,$d' | \
  sed -e "1s/.*>==/==/"  | \
  sed -e 's/&quot;/"/g' -e 's/&amp;/\&/g' \
  -e  's/&gt;/>/g' -e 's/&lt;/</g' > $DUMPFILE 



echo "Output in authors.html"

# create the url list

cat $DUMPFILE | \
  tr "\n" " " | \
  sed -e 's/|-/\n\n/g' | \
  sed -e '/==.*==/s/^.*== *\(.*\) *==.*$/<a name="\1"><h3>\1<\/h3><\/a>/' | \
  sed -e 's/^ *! *\(.\+\) *| *\(.\+\) || *\(http[^ ]\+\) *\(||.*\)\+/<a href="\3">\2<\/a>/' | \
  sed -e '/^ *\(|}\)* *$/d' | \
  sed -e 's/$/\n/' > author-index.html

# count them
num_node=$(grep http author-index.html | wc -l)
echo "There are $num_node on the archive"

echo "<ul>" > authors.html

## what a fucking hack
# build the list of the authors + the anchors
grep "<h3>" author-index.html | \
  sed -e 's|^ *<a name="\(.*\)"><h3>\(.*\)</h3></a> *$|<li><a href="#\1">\2</a></li>|'  | \
  sed -e 's|<li><a href="[^>]*>|&\n|g'  | \
  sed -e '/^<li><a href=/s|[^a-zA-Z0-9/="<>#]||g' | \
  sed -e 's/<ahref/<a href/g' | \
  tr "\n" " " | \
  sed -e 's|</li>|&\n|g' >> authors.html

echo "</ul>">> authors.html 


cat author-index.html | sed -e 's|<h3>|\n<h3>|g' | \
  sed -e '/^<a name=/s|[^a-zA-Z0-9/="<>]||g' | \
  sed -e '/^<li><a href=/s|[^a-zA-Z0-9/="<>#]||g' | \
  sed -e 's/<ahref/<a href/g' | \
  sed -e 's/<aname/<a name/g' | tr "\n" " " | \
  sed -e 's|</a>|&\n|g' | \
  sed -e '/<h3>/s|^.*$|<table width="100%"><tr><td width="80%">&</td><td align="center" width="8%"><a href="#">[top]</a></td></tr></table>|' | \
  sed -e 's|<a name="\([a-zA-Z0-9]*\)"> *<h3>\(.*\)</h3> *</a>|<h3><a name="\1">\2</a></h3>|' | \
  sed -e '/h3/s|^\(.*<a name="[^>]*">\) *\([^<,]*\)\(.*\) *\(</a>.*\)</tr></table>$|\1\2\3\4<td align="center" width="10%"><a href="http://beta.theanarchistlibrary.org/search/node/\2"> [Search] </a></td></tr></table>|' >> authors.html
    
rm author-index.html

echo "Output in text-index.html"
cat $DUMPFILE | \
  tr "\n" " " | \
  sed -e 's/|-/\n\n/g' | \
  sed -e '/==.*==/d' | \
  sed -e 's/^ *! *\(.\+\) *| *\(.\+\) || *\(http[^ ]\+\) *\(||.*\)\+/<a href="\3">\2 by \1<\/a>/' | \
  sed -e '/^ *\(|}\)* *$/d' | \
  sed -e 's,\(<a href="[^ ]*">\) *\(The\>\|An*\>\)\? *\(.*\)</a>,\3\1[\2],' | \
  sort | \
  sed -e 's|\([^<]*\)\(<a href=".*\)\[\(.*\)\]|\2\<em>(\3)</em> \1</a>|' | \
  sed -e 's| by  *\(.*\),\(.*\)</a>| by \2 \1 </a>|' | \
  sed -e 's|$|\n|' | \
  sed -e 's|   *| |g' | sed -e 's|<em>( *)</em>||' >  text-index.html
 
cat << eof >> text-index.html

<a href="#">[top]</a>
eof

num_node=$(grep http text-index.html | wc -l)
echo "There are $num_node on the archive"

for i in text-index.html  authors.html; do
	sed -i "s|http://beta.theanarchistlibrary.org/|internal:|g" $i 
	sed -i "s|http://theanarchistlibrary.org/|internal:|g" $i 
done

exit 0
