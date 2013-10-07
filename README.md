Evelyn-Flickr-Downloader
=======================

A Command line script to download the original-size photo from Flickr photo set, promoted by [小敬] (http://www.facebook.com/people/%E8%99%9E%E6%88%90%E6%95%AC/100001603870154)

Usage:
-----------------------

* Download directly with a Flickr photo set URL.

        $ Evelyn.pl 'http://www.flickr.com/photos/piazta/sets/72157630883766410/with/7474160854/'

* Download from a list of Flickr photo set URL.

        $ cat photo.txt
        http://www.flickr.com/photos/piazta/sets/72157630883766410/with/7474160854/
        http://www.flickr.com/photos/jup3nep/sets/72157594560896483/
        http://www.flickr.com/photos/batiks/sets/72157624657197522/
        $ Evelyn.pl photo.txt

Feature:
-----------------------

* Continue to download from last session.
* Each photo set will be stored into a single directory.

Copyright:
----------------------

FreeBSD License
