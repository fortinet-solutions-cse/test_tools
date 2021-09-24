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
    echo "Please note this script assumes some security settings in your connection:"
    echo "Video/Audio/Proxy should be blocked and AV/WF/FF/IPS/Deep Inspection should enabled"
    echo ""
    if [ ${XML} ]; then
        echo "<testsuite>" > ${xml_file}
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
wget "${wget_options[@]}" https://www.google.com >/dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Checking internet connectivity: Google: Accessing Google.com failed. This error will not be included in report"
    ssl_inspection_hint1=true
else
    echo "Checking internet connectivity: Google can be accessed"
fi
echo "(1/2)."

wget "${wget_options[@]}" https://www.google.com --no-check-certificate >/dev/null 2>&1
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
# EICAR (AV/IPS) - HTTP
#=============================
wget_options+=(--no-check-certificate)
echo 
echo "Disabling certificate check in subsequent requests"

rm eicar_signature >/dev/null 2>&1
date
echo
echo "Detect EICAR-http (3):"
wget "${wget_options[@]}" --output-document eicar_signature http://www.rexswain.com/eicar.com >/dev/null 2>&1
if [ $? -ne 0 ]; then
    success_log "Detect EICAR" "http/plain text"
else
    grep "7CC)7}\$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!" eicar_signature >/dev/null 2>&1 
    if [ $? -ne 0 ]; then
        success_log "Detect EICAR" "http/plain text"
    else
        fail_log "Detect EICAR" "http/plain text" "EICAR can be downloaded"
    fi
fi
echo "(1/3)."
wget "${wget_options[@]}" --output-document eicar_signature http://www.rexswain.com/eicar.zip >/dev/null 2>&1
if [ $? -ne 0 ]; then
    success_log "Detect EICAR" "http/zip"
else
    unzip -l eicar_signature >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        success_log "Detect EICAR" "http/zip"
    else
        fail_log "Detect EICAR" "http/zip" "EICAR can be downloaded: File is a zip"
    fi
fi
echo "(2/3)."
wget "${wget_options[@]}" --output-document eicar_signature http://www.rexswain.com/eicar2.zip >/dev/null 2>&1
if [ $? -ne 0 ]; then
    success_log "Detect EICAR" "http/double zip"
else
    unzip -l eicar_signature >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        success_log "Detect EICAR" "http/double zip"
    else
        fail_log "Detect EICAR" "http/double zip" "EICAR can be downloaded: File is a zip"
    fi
fi
echo "(3/3)."

#=============================
# EICAR (AV/IPS) - HTTPS
#=============================

rm eicar_signature >/dev/null 2>&1
date
echo
echo "Detect EICAR-https (3):"
wget "${wget_options[@]}" --output-document eicar_signature https://secure.eicar.org/eicar.com >/dev/null 2>&1
if [ $? -ne 0 ]; then
    success_log "Detect EICAR" "https/plain text"
else
    grep "7CC)7}\$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!" eicar_signature >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        success_log "Detect EICAR" "https/plain text"
    else
        fail_log "Detect EICAR" "https/plain text" "EICAR can be downloaded"
    fi
fi
echo "(1/3)."
wget "${wget_options[@]}" --output-document eicar_signature https://secure.eicar.org/eicar_com.zip >/dev/null 2>&1
if [ $? -ne 0 ]; then
    success_log "Detect EICAR" "https/zip"
else
    unzip -l eicar_signature >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        success_log "Detect EICAR" "https/zip"
    else
        fail_log "Detect EICAR" "https/zip" "EICAR can be downloaded: File is a zip"
    fi
fi
echo "(2/3)."
wget "${wget_options[@]}" --output-document eicar_signature https://secure.eicar.org/eicarcom2.zip >/dev/null 2>&1
if [ $? -ne 0 ]; then
    success_log "Detect EICAR" "https/double zip"
else
    unzip -l eicar_signature >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        success_log "Detect EICAR" "https/double zip"
    else
        fail_log "Detect EICAR" "https/double zip" "EICAR can be downloaded: File is a zip"
    fi
fi
echo "(3/3)."

#=============================
# Files
#=============================
date
echo
echo "Downloading MP3 files (3):"
timeout 30 wget "${wget_options[@]}" http://www.gurbaniupdesh.org/multimedia/01-Audio%20Books/Baba%20Noadh%20Singh/000%20Introduction%20Bhai%20Sarabjit%20Singh%20Ji%20Gobindpuri.mp3 >/dev/null 2>&1
if [ $? -ne 0 ]; then
    success_log "Download files" "http://www.gurbaniupdesh.org/" 
else
    fail_log "Download files" "http://www.gurbaniupdesh.org/" "MP3 can be downloaded"
fi
echo "(1/2)."

timeout 30 wget "${wget_options[@]}" http://www.theradiodept.com/media/mp3/david.mp3 >/dev/null 2>&1
if [ $? -ne 0 ]; then
    success_log "Download files" "http://www.theradiodept.com/" 
else
    fail_log "Download files" "http://www.theradiodept.com/" "MP3 can be downloaded"
fi
echo "(2/3)."

timeout 30 wget "${wget_options[@]}" https://faro.fortinet-emea.com:5000/static/file.base64 >/dev/null 2>&1
if [ $? -ne 0 ]; then
    success_log "Download files" "https://faro.fortinet-emea.com:5000/static/file.base64" 
else
    fail_log "Download files" "https://faro.fortinet-emea.com:5000/static/file.base64" "Base64 file can be downloaded"
fi
echo "(3/3)."


#=============================
# DLP
#=============================
date
echo
echo "Checking DLP(4)"

echo "  Credit Card (Amex):"
curl ${curl_options} -X POST  -H "Content-Type:multipart/form-data; boundary=---------------------------52410911313245418552292478843" -F 'item_meta[6]=371193356045439' http://dlptest.com/http-post;
if [ $? -ne 0 ]; then
    success_log "Check DLP" "Amex"
else
    fail_log "Check DLP" "Amex" "Data seems to be leaked"
fi
echo "(1/4)."

echo "  Social security number:"
curl ${curl_options} -X POST  -H "Content-Type:multipart/form-data; boundary=---------------------------52410911313245418552292478843" -F 'item_meta[6]=123-45-6789' http://dlptest.com/http-post
if [ $? -ne 0 ]; then
    success_log "Check DLP" "Social Security Number"
else
    fail_log "Check DLP" "Social Security Number" "Data seems to be leaked"
fi
echo "(2/4)."

echo "  Spanish ID number:"
curl ${curl_options} -X POST  -H "Content-Type:multipart/form-data; boundary=---------------------------52410911313245418552292478843" -F 'item_meta[6]=_4332564D_' http://dlptest.com/http-post
if [ $? -ne 0 ]; then
    success_log "Check DLP" "Spanish ID number"
else
    fail_log "Check DLP" "Spanish ID number" "Data seems to be leaked"
fi
echo "(3/4)."

echo "  Simple 3 digit number (should be leaked):"
curl ${curl_options} -X POST  -H "Content-Type:multipart/form-data; boundary=---------------------------52410911313245418552292478843" -F 'item_meta[6]=123' http://dlptest.com/http-post
if [ $? -ne 0 ]; then
    fail_log "Check DLP" "Plain number - should allow transfers" "Simple data cannot be sent"
else
    success_log "Check DLP" "Plain number - should allow transfers"
fi
echo "(4/4)."

#=============================
# Viruses
#=============================
date
echo
echo "Downloading Viruses (2):"
rm virus_output >/dev/null 2>&1
# Repeat 5 times to ensure virus is sent, detected by the AV engine and then blocked
echo -ne "  Iteration: "
for i in {1..5}
do
    echo -ne "\n     ${i} "
    wget "${wget_options[@]}" --output-document virus_output http://www.esthetique-realm.net/ > /dev/null

    if [ $? -ne 0 ]; then
        success_log "AV" "JS/Iframe.BYO!tr ${i}"
    else
        if grep -i forti virus_output >/dev/null; then 
            success_log "AV" "JS/Iframe.BYO!tr ${i}"
        else
            fail_log "AV" "JS/Iframe.BYO!tr ${i}" "Virus can be downloaded: Reply page is not replacement message from Fortinet"
        fi
    fi
done
echo -ne "\n(1/2)."
# Repeat 5 times to ensure virus is sent, detected by the AV engine and then blocked
echo -ne "\n  Iteration: "
for i in {1..5}
do
    echo -ne "\n     ${i} "
    wget "${wget_options[@]}" --output-document virus_output http://www.newalliancebank.com/ > /dev/null

    if [ $? -ne 0 ]; then
        success_log "AV" "HTML/Refresh.250C!tr ${i}"
    else
        if grep -i forti virus_output >/dev/null; then 
            success_log "AV" "HTML/Refresh.250C!tr ${i}"
        else
            fail_log "AV" "HTML/Refresh.250C!tr ${i}" "Virus can be downloaded: Reply page is not replacement message from Fortinet"
        fi
    fi
done
echo -ne "\n(2/2).\n"

#=============================
# WebFilter
#=============================
date
sites=(www.magikmobile.com www.cstress.net www.ilovemynanny.com ww1.movie2kproxy.com www.microsofl.bid)
rm webfilter_ouput >/dev/null 2>&1
echo
echo "Checking WebFilter (${#sites[@]}):"
i=0
for site in ${sites[@]}
do
    i=$(($i+1))
    
    wget "${wget_options[@]}" --output-document webfilter_output ${site} >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        success_log "WebFilter" ${site}
    else
        grep -i forti webfilter_output >/dev/null 2>&1 
        if [ $? -eq 0 ]; then
            success_log "WebFilter" ${site}
        else
            fail_log "WebFilter" ${site} "Site can be accessed: Reply page is not replacement message from Fortinet"
        fi

    fi
    echo "(${i}/${#sites[@]})."
done


#=============================
# AppControl
#=============================
date
rm appcontrol_output >/dev/null 2>&1
sites=(unblockvideos.com youtube.com)
echo
echo "Checking AppControl (${#sites[@]}):"
i=0
for site in ${sites[@]}
do
    i=$(($i+1))
    wget "${wget_options[@]}" --output-document appcontrol_output ${site} >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        success_log "AppControl" ${site}
    else
        grep -i forti appcontrol_output  >/dev/null 2>&1 
        if [ $? -eq 0 ]; then
            success_log "AppControl" ${site}
        else
            fail_log "AppControl" ${site} "Site can be accessed"
        fi
    fi
    echo "(${i}/${#sites[@]})."
done