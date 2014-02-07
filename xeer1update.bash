#!/bin/bash
#Automatically Update script for Xen Servers. Supports only 6.2 at the moment.
#Start by downloading the xml file
#bash xeer1
echo "Downloading updates.xml"
curl -# -L -R -o updates.xml http://updates.xensource.com/XenServer/updates.xml

#Grep the patches for version number XS62E, parse the data, and form the table
#Columns are 1-patch name 2 - url 3- timestamp and 4- uuid
#Each column is one variable and sorted by date and then by name

grep 'name-label="XS62E' updates.xml | cut -d "\"" -f 6,8,12,16 --output-delimiter=" "|sort -k3,3 -k1|while read line1 line2 line3 line4
        do
        #Save some typing
        export  ShortUrl=`basename $line2`
                # Check to see if the patch has been installed already
                if [[ -n $(xe patch-list name-label=$line1 2> /dev/null) ]]
                then
                        echo $line1 "has aleady been installed"
                else
                        #Patch download portion
                        echo -e $line1  "Patch was not found.\nRetrieving URL for download " $line2 " \nURL Fetched Starting Download"
                                #check to see if the file already exists
                                if [ -f $ShortUrl ]
                                then
                                        #skips the file
                                        echo $ShortUrl " already exists skipping download\n"
                                else
                                        #Downloads the file     and unzip it
                                        echo "Downloading $ShortUrl"
                                        curl -# -o $ShortUrl -L -R $line2
                                        echo -e "Download Completed\n"

                                fi
                        #Unzip
                        echo -e "Unziping " $ShortUrl "\n"
                        unzip -o -q $ShortUrl
                        #upload to Xen Server
                        echo "Uploading to Xen Server"
                        xe patch-upload file-name=$line1.xsupdate
                        echo "Applying Patch"
                        xe patch-pool-apply uuid=$line4
                        echo "Verifying Installation"
                                if [[ -n $(xe patch-list name-label=$line1 2> /dev/null) ]]
                                        then
                                                echo $line1 "has been installed successfully"
                                                echo "Removing installation files"
                                                rm -f $line1-src-pkgs.tar.bz2
                                                rm -f $line1.xsupdate
                                        else
                                                echo $line1 "Failed to Install please check it manually. Please fix the issue and run this program again"
                                                #Remove patch
                                                rm -rf /opt/xensource/patch-backup/$line3
                                                exit 0
                                fi
                fi
        done
