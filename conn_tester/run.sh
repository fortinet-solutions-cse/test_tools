#!/bin/bash

if [ "$1" != "--nocolor" ]; then
    RED="\e[31m"
    GRE="\e[32m"
    YEL="\e[33m"
    NC="\e[0m"
fi

wget_options='-qO- -T 30 -t 1'
curl_options='-s -o /dev/null'

#=============================
# Initial connectivity
#=============================
echo
echo -e "${YEL}General connectivity tests${NC}"
echo "=========================="
echo
echo "Checking internet connectivity (1):"
wget ${wget_options} https://www.google.com > /dev/null

if [ $? -ne 0 ]; then
    echo -ne "${RED}Error:${NC} Cannot get any traffic. Accessing Google.com failed"
    ssl_inspection_hint1=true
else
    echo -ne "${GRE}Ok:${NC} Google.com can be accessed. Internet connectivity seems to be ok"
fi
echo "(1/2)."

wget ${wget_options} https://www.google.com --no-check-certificate> /dev/null

if [ $? -ne 0 ]; then
    echo -ne "${RED}Error:${NC} Cannot get any traffic (certificate check disabled). Accessing Google.com failed"
else
    ssl_inspection_hint2=true
    echo -ne "${GRE}Ok:${NC} Google.com can be accessed (certificate check disabled). Internet connectivity seems to be ok"
fi
echo "(2/2)."

if [ $ssl_inspection_hint1 ] && [ $ssl_inspection_hint2 ]; then 
   echo "***** Note: SSL Deep inspection might be enabled *****"
fi

#=============================
# EICAR (AV/IPS)
#=============================
wget_options="${wget_options} --no-check-certificate"
echo "Disabling certificate check in subsequent requests"

rm eicar_signature
echo
echo "Downloading EICAR (3):"
if wget ${wget_options} --output-file eicar_signature http://www.rexswain.com/eicar.com > /dev/null; then
    echo -ne "${GRE}Ok:${NC} EICAR cannot be downloaded: Connection is blocked"
else
    if grep "7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!" eicar_signature >/dev/null; then 
        echo -ne "${GRE}Ok:${NC} EICAR cannot be downloaded: Signature is not found on content returned"
    else
        echo -ne "${RED}Error:${NC} EICAR can be downloaded"
    fi
fi
echo "(1/3)."

if wget ${wget_options} --output-file eicar_signature http://www.rexswain.com/eicar.zip > /dev/null; then
    echo -ne "${GRE}Ok:${NC} EICAR cannot be downloaded: Connection is blocked"
else
    if unzip eicar_signature; then
        echo -ne "${GRE}Ok:${NC} EICAR cannot be downloaded: Returned file does not seem to be a zip"
    else
        echo -ne "${RED}Error:${NC} EICAR can be downloaded"
    fi
fi
echo "(2/3)."

if wget ${wget_options} --output-file eicar_signature http://www.rexswain.com/eicar2.zip > /dev/null; then
    echo -ne "${GRE}Ok:${NC} EICAR cannot be downloaded: Connection is blocked"
else
    if unzip eicar_signature; then
        echo -ne "${GRE}Ok:${NC} EICAR cannot be downloaded: Returned file does not seem to be a zi"
    else
        echo -ne "${RED}Error:${NC} EICAR can be downloaded"
    fi
fi
echo "(3/3)."

#=============================
# Files (MP3)
#=============================
echo
echo "Downloading MP3 files (2):"
timeout 30 wget ${wget_options} http://www.gurbaniupdesh.org/multimedia/01-Audio%20Books/Baba%20Noadh%20Singh/000%20Introduction%20Bhai%20Sarabjit%20Singh%20Ji%20Gobindpuri.mp3  > /dev/null
if [ $? -ne 0 ]; then
    echo -ne "${RED}Error:${NC} Cannot download MP3 files"
else
    echo -ne "${GRE}Ok:${NC} MP3 file can be downloaded normally"
fi
echo "(1/2)."

timeout 30 wget ${wget_options} http://www.theradiodept.com/media/mp3/david.mp3 > /dev/null
if [ $? -ne 0 ]; then
    echo -ne "${RED}Error:${NC} Cannot download MP3 files"
else
    echo -ne "${GRE}Ok:${NC} MP3 file can be downloaded normally"
fi
echo "(2/2)."

#=============================
# DLP
#=============================
echo
echo "Checking DLP(4)"
echo "  Credit Card (Amex):"
if curl ${curl_options} -X POST  -H "Content-Type:multipart/form-data; boundary=---------------------------52410911313245418552292478843" -F 'item_meta[6]=371193356045439' http://dlptest.com/http-post; then
    echo -ne "   ${GRE}Ok:${NC} Cannot leak data"
else
    echo -ne "   ${RED}Error:${NC} Data seems to be leaked"
fi
echo "(1/4)."

echo "  Social security number:"
curl ${curl_options} -X POST  -H "Content-Type:multipart/form-data; boundary=---------------------------52410911313245418552292478843" -F 'item_meta[6]=123-45-6789' http://dlptest.com/http-post
if [ $? -ne 0 ]; then
    echo -ne "   ${GRE}Ok:${NC} Cannot leak data"
else
    echo -ne "   ${RED}Error:${NC} Data seems to be leaked"
fi
echo "(2/4)."

echo "  Spanish ID number:"
curl ${curl_options} -X POST  -H "Content-Type:multipart/form-data; boundary=---------------------------52410911313245418552292478843" -F 'item_meta[6]=14332564D' http://dlptest.com/http-post
if [ $? -ne 0 ]; then
    echo -ne "   ${GRE}Ok:${NC} Cannot leak data"
else
    echo -ne "   ${RED}Error:${NC} Data seems to be leaked"
fi
echo "(3/4)."

echo "  Simple 3 digit number (should be leaked):"
curl ${curl_options} -X POST  -H "Content-Type:multipart/form-data; boundary=---------------------------52410911313245418552292478843" -F 'item_meta[6]=123' http://dlptest.com/http-post
if [ $? -ne 0 ]; then
    echo -ne "   ${RED}Error:${NC} Cannot leak/send non sensitive data"
else
    echo -ne "   ${GRE}Ok:${NC} Non sensitive data can be sent"
fi
echo "(4/4)."

#=============================
# Viruses
#=============================
echo
echo "Downloading Viruses (2):"
wget ${wget_options} http://www.esthetique-realm.net/ > /dev/null
if [ $? -ne 0 ]; then
    echo -ne "${GRE}Ok:${NC} JS/Iframe.BYO!tr cannot be downloaded"
else
    echo -ne "${RED}Error:${NC} JS/Iframe.BYO!tr can be downloaded"
fi
echo "(1/2)."
wget ${wget_options} http://www.newalliancebank.com/ > /dev/null
if [ $? -ne 0 ]; then
    echo -ne "${GRE}Ok:${NC} HTML/Refresh.250C!tr cannot be downloaded"
else
    echo -ne "${RED}Error:${NC} HTML/Refresh.250C!tr can be downloaded"
fi
echo "(2/2)."

#=============================
# WebFilter
#=============================
sites=(www.magikmobile.com www.cstress.net www.ilovemynanny.com ww1.movie2kproxy.com www.microsofl.bid)
rm webfilter_ouput
echo
echo "Checking WebFilter (${#sites[@]}):"
i=0
for site in ${sites[@]}
do
    i=$(($i+1))
    
    if wget ${wget_options} --output-file webfilter_output ${site} > /dev/null; then
        echo -ne "${GRE}Ok:${NC} ${site} cannot be accessed: Connection blocked"
    else
        if grep -i forti webfilter_output >/dev/null; then 
            echo -ne "${GRE}Ok:${NC} ${site} cannot cannot be accessed: Reply page is from Fortinet"
        else
            echo -ne "${RED}Error:${NC} ${site} can be accessed: Reply page is not replacement message from Fortinet"
        fi

    fi
    echo "(${i}/${#sites[@]})."
done


#=============================
# AppControl
#=============================
sites=(www.logmeinrescue.com unblockvideos.com)
echo
echo "Checking AppControl (${#sites[@]}):"
i=0
for site in ${sites[@]}
do
    i=$(($i+1))
    wget ${wget_options} ${site} > /dev/null
    if [ $? -ne 0 ]; then
        echo -ne "${GRE}Ok:${NC} ${site} cannot be accessed"
    else
        echo -ne "${RED}Error:${NC} ${site} can be accessed"
    fi
    echo "(${i}/${#sites[@]})."
done


# wget --no-check-certificate https://secure.eicar.org/eicar.com
