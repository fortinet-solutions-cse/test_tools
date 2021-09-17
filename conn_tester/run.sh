#!/bin/bash
RED="\e[31m"
GRE="\e[32m"
YEL="\e[33m"
NC="\e[0m"

xml_file="test_results.xml"
user_agent="Mozilla/4.0 (compatible; MSIE 9.0; Windows NT 6.1)"
wget_options=(-qO- -T 30 -t 1 -U "${user_agent}")
curl_options="-s -o /dev/null"

trap finish_log EXIT SIGINT SIGQUIT SIGKILL SIGTERM

while true; do
    case "$1" in
        -nc | --nocolor ) 
            RED=""
            GRE=""
            YEL=""
            NC=""
            shift
            ;;
        -x | --xml )
            XML=true
            shift
            ;;
        -h )
            echo "Use:"
            echo " -nc | --nocolor for single color output (no ascii color codes)"
            echo " -x  | --xml     for writing test results to xml file (junit format)"
            echo " -h              this help"
            shift
            ;;
        * )
            break
            ;;
    esac
done

function start_log() {

    echo -e "${YEL}General connectivity tests${NC}"
    echo "=========================="
    if [ ${XML} ]; then
        echo "<testsuite tests=\"3\">" > ${xml_file}
    fi
}

function finish_log () {

    echo -e "Finished.${NC}"
    if [ ${XML} ]; then
        echo "</testsuite>" >> ${xml_file}
    fi
}

function success_log() { # test name, test variation

    echo -ne "${GRE}Ok:${NC} $1 : $2"
    if [ ${XML} ]; then
        echo "<testcase classname=\"$1\" name=\"$2\"/>" >> ${xml_file}
    fi
}

function fail_log() {  # test name, test variation, details 

    echo -ne ${RED}Error:${NC} $1 : $2 : $3 

    if [ ${XML} ]; then
        echo "<testcase classname=\"$1\" name=\"$2\">"  >> ${xml_file}
        echo "      <failure type=\"Error\"> $3 </failure>"  >> ${xml_file}
        echo "</testcase>"  >> ${xml_file}
    fi
}   



#=============================
# Initial connectivity
#=============================
date
echo
start_log
echo
echo "Checking internet connectivity (2):"
wget "${wget_options[@]}" https://www.google.com > /dev/null

if [ $? -ne 0 ]; then
    fail_log "Checking internet connectivity" "Google" "Cannot get any traffic. Accessing Google.com failed"
    ssl_inspection_hint1=true
else
    success_log "Checking internet connectivity" "Google"
fi
echo "(1/2)."

wget "${wget_options[@]}" https://www.google.com --no-check-certificate> /dev/null

if [ $? -ne 0 ]; then
    fail_log "Checking internet connectivity" "Google (cert check disabled)" "Cannot get any traffic. Accessing Google.com failed"
else
    ssl_inspection_hint2=true
    success_log "Checking internet connectivity" "Google (cert check disabled)"
fi
echo "(2/2)."

if [ $ssl_inspection_hint1 ] && [ $ssl_inspection_hint2 ]; then 
   echo "***** Note: SSL Deep inspection might be enabled *****"
fi

#=============================
# EICAR (AV/IPS)
#=============================
wget_options+=(--no-check-certificate)
echo 
echo "Disabling certificate check in subsequent requests"

rm eicar_signature 2>/dev/null
date
echo
echo "Detect EICAR (3):"
if ! wget "${wget_options[@]}" --output-document eicar_signature http://www.rexswain.com/eicar.com > /dev/null; then
    success_log "Detect EICAR" "http/plain text"
else
    if grep "7CC)7}\$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!" eicar_signature >/dev/null; then 
        fail_log "Detect EICAR" "http/plain text" "EICAR can be downloaded"
    else
        success_log "Detect EICAR" "http/plain text"
    fi
fi
echo "(1/3)."

if ! wget "${wget_options[@]}" --output-document eicar_signature http://www.rexswain.com/eicar.zip > /dev/null; then
    success_log "Detect EICAR" "http/zip"
else
    if unzip eicar_signature 2&>/dev/null; then
        fail_log "Detect EICAR" "http/zip" "EICAR can be downloaded: File is a zip"
    else
        success_log "Detect EICAR" "http/zip"
    fi
fi
echo "(2/3)."

if ! wget "${wget_options[@]}" --output-document eicar_signature http://www.rexswain.com/eicar2.zip > /dev/null; then
    success_log "Detect EICAR" "http/double zip"
else
    if unzip eicar_signature 2&>/dev/null; then
        fail_log "Detect EICAR" "http/double zip" "EICAR can be downloaded: File is a zip"
    else
        success_log "Detect EICAR" "http/double zip"
    fi
fi
echo "(3/3)."

#=============================
# Files (MP3)
#=============================
date
echo
echo "Downloading MP3 files (2):"
timeout 30 wget "${wget_options[@]}" http://www.gurbaniupdesh.org/multimedia/01-Audio%20Books/Baba%20Noadh%20Singh/000%20Introduction%20Bhai%20Sarabjit%20Singh%20Ji%20Gobindpuri.mp3  > /dev/null
if [ $? -ne 0 ]; then
    fail_log "Download MP3 files" "http://www.gurbaniupdesh.org/" "Cannot download mp3"
else
    success_log "Download MP3 files" "http://www.gurbaniupdesh.org/"
fi
echo "(1/2)."

timeout 30 wget "${wget_options[@]}" http://www.theradiodept.com/media/mp3/david.mp3 > /dev/null
if [ $? -ne 0 ]; then
    fail_log "Download MP3 files" "http://www.theradiodept.com/" "Cannot download mp3"
else
    success_log "Download MP3 files" "http://www.theradiodept.com/"
fi
echo "(2/2)."

#=============================
# DLP
#=============================
date
echo
echo "Checking DLP(4)"

echo "  Credit Card (Amex):"
if curl ${curl_options} -X POST  -H "Content-Type:multipart/form-data; boundary=---------------------------52410911313245418552292478843" -F 'item_meta[6]=371193356045439' http://dlptest.com/http-post; then
    fail_log "Check DLP" "Amex" "Data seems to be leaked"
else
    success_log "Check DLP" "Amex"
fi
echo "(1/4)."

echo "  Social security number:"
if curl ${curl_options} -X POST  -H "Content-Type:multipart/form-data; boundary=---------------------------52410911313245418552292478843" -F 'item_meta[6]=123-45-6789' http://dlptest.com/http-post; then
    fail_log "Check DLP" "Social Security Number" "Data seems to be leaked"
else
    success_log "Check DLP" "Social Security Number"
fi
echo "(2/4)."

echo "  Spanish ID number:"
if curl ${curl_options} -X POST  -H "Content-Type:multipart/form-data; boundary=---------------------------52410911313245418552292478843" -F 'item_meta[6]=14332564D' http://dlptest.com/http-post; then
    fail_log "Check DLP" "Spanish ID number" "Data seems to be leaked"
else
    success_log "Check DLP" "Spanish ID number"
fi
echo "(3/4)."

echo "  Simple 3 digit number (should be leaked):"
if curl ${curl_options} -X POST  -H "Content-Type:multipart/form-data; boundary=---------------------------52410911313245418552292478843" -F 'item_meta[6]=123' http://dlptest.com/http-post; then
    success_log "Check DLP" "Plain number - should allow transfers"
else
    fail_log "Check DLP" "Plain number - should allow transfers" "Simple data cannot be sent"
fi
echo "(4/4)."

#=============================
# Viruses
#=============================
date
echo
echo "Downloading Viruses (2):"
rm virus_output 2>/dev/null
wget "${wget_options[@]}" --output-document virus_output http://www.esthetique-realm.net/ > /dev/null
if [ $? -ne 0 ]; then
    echo -ne "${GRE}Ok:${NC} JS/Iframe.BYO!tr cannot be downloaded: Connection blocked"
else
    if grep -i forti virus_output >/dev/null; then 
        echo -ne "${GRE}Ok:${NC} JS/Iframe.BYO!tr cannot be downloaded: Reply page is from Fortinet"
    else
        echo -ne "${RED}Error:${NC} JS/Iframe.BYO!tr can be downloaded: Reply page is not replacement message from Fortinet"
    fi
fi
echo "(1/2)."
wget "${wget_options[@]}" --output-document virus_output http://www.newalliancebank.com/ > /dev/null
if [ $? -ne 0 ]; then
    echo -ne "${GRE}Ok:${NC} HTML/Refresh.250C!tr cannot be downloaded: Connection blocked"
else
    if grep -i forti virus_output >/dev/null; then 
        echo -ne "${GRE}Ok:${NC} HTML/Refresh.250C!tr cannot be downloaded: Reply page is from Fortinet"
    else
        echo -ne "${RED}Error:${NC} HTML/Refresh.250C!tr can be downloaded: Reply page is not replacement message from Fortinet"
    fi
fi
echo "(2/2)."

#=============================
# WebFilter
#=============================
date
sites=(www.magikmobile.com www.cstress.net www.ilovemynanny.com ww1.movie2kproxy.com www.microsofl.bid)
rm webfilter_ouput 2>/dev/null
echo
echo "Checking WebFilter (${#sites[@]}):"
i=0
for site in ${sites[@]}
do
    i=$(($i+1))
    
    if wget "${wget_options[@]}" --output-document webfilter_output ${site} > /dev/null; then
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
date
sites=(www.logmeinrescue.com unblockvideos.com youtube.com)
echo
echo "Checking AppControl (${#sites[@]}):"
i=0
for site in ${sites[@]}
do
    i=$(($i+1))
    wget "${wget_options[@]}" ${site} > /dev/null
    if [ $? -ne 0 ]; then
        echo -ne "${GRE}Ok:${NC} ${site} cannot be accessed"
    else
        echo -ne "${RED}Error:${NC} ${site} can be accessed"
    fi
    echo "(${i}/${#sites[@]})."
done

# wget --no-check-certificate https://secure.eicar.org/eicar.com
