#!/bin/bash
function requirement_checker () {
    echo -e "\nChecking requirements..."
    PROGRAMLIST=(aquatone crobat nmap)
    COUNTER=0
    for PROGRAM in ${PROGRAMLIST[*]}; do
        if ! [ -x "$(command -v $PROGRAM)" ]; then
            echo -e '\e[31m[-]' ${PROGRAMLIST[COUNTER]}  'is not installed or not in path' >&2; ((COUNTER=COUNTER + 1))
        else
            echo -e '\e[32m[+]' ${PROGRAMLIST[COUNTER]} 'is installed'; ((COUNTER=COUNTER + 1))
        fi
        if ! [ -x "$(command -v crobat)" ]; then
            echo -e '\e[31m[-]Crobat is not installed or not in path'
        fi
    done

    wget -q --spider http://google.com
    if [ $? -eq 0 ]; then
        echo -e "\e[32m[+] Internet connection up\e[0m"
    else
        echo -e "\e[31mYour internet connection seems down, please check before continuing"; exit 1
    fi
    echo -e "\e[0m"
    create_workingdir
}

function create_workingdir () {
    echo -e "\nFolder recon-folder will be created, this will contain results"
    mkdir recon-folder 2>/dev/null || { echo -e "\e[31mFolder recon-folder could not be created\e[0m\n"; EXISTS=1; }
    if [[ $EXISTS = '1' ]]; then
        read -p "Do you want to remove the existing recon-folder? y/n: " ANSWER
        if [[ $ANSWER =~ ^[Yy]$ ]]; then
            rm -rf recon-folder; echo -e "\e[32mDone, proceeding...\n\e[0m"; mkdir recon-folder
        else
            echo -e "\nCannot proceed, try again\e[0m\n"; main
        fi
    fi
    get_domain
}

function get_domain () {
    read -p "Please enter a domain to harvest (e.g. example.com): " DOMAIN
    get_subdomains
}

function get_subdomains () {
    echo "1. SonarSearch Crobat"
    echo "2. SecurityTrails.com (APIKEY required)"
    echo "3. You own file containing subdomains"
    read -p "What source should be used for subdomains: " ANSWER
    if [[ $ANSWER = '1' ]]; then
        crobat -s $DOMAIN | tee recon-folder/$DOMAIN.subdomains.log &>/dev/null
        echo "Total subdomains found by crobat:" $(cat recon-folder/$DOMAIN.subdomains.log | wc -l)
    elif [[ $ANSWER = '2' ]]; then
        read -p "Please enter APIKEY: " APIKEY_IN
        APIKEY="APIKEY: $APIKEY_IN"
        curl -s -X GET --header 'Accept: application/json' --header "$APIKEY" https://api.securitytrails.com/v1/domain/"$DOMAIN"/subdomains?children_only=false > recon-folder/tmp_apioutput && jq -r '.subdomains' recon-folder/tmp_apioutput | tr -d '",[] ' | tee recon-folder/tmp_subdomains &>/dev/null
        sed '/^$/d' recon-folder/tmp_subdomains | tee recon-folder/tmp_parsing &>/dev/null
        sed -e "s/$/.$DOMAIN/g" recon-folder/tmp_parsing | tee recon-folder/$DOMAIN.subdomains.log &>/dev/null
        rm recon-folder/tmp_*
        echo "Total subdomains found by SecurityTrails:" $(cat recon-folder/$DOMAIN.subdomains.log | wc -l)
    elif [[ $ANSWER = '3' ]]; then
        read -e -p "Enter file containing line seperated subdomains: " SUBDOMAINS
        cat $SUBDOMAINS > recon-folder/$DOMAIN.subdomains.log
    else
        echo "Please enter a valid option"; get_subdomains
    fi
    run_nmap
}

function run_nmap () {
    echo -e "\nRunning nmap agains found subdomains"
    nmap -iL recon-folder/$DOMAIN.subdomains.log -Pn -T4 -oA recon-folder/$DOMAIN.nmap.log || { echo -e "\e[31mError occured, please restart."; exit 1; }
    run_aquatone
}

function run_aquatone () {
    echo -e "\naquatone will now process the results for subdomains from $DOMAIN"
    read -p "Do you want to use a proxy (e.g. Burp Suite)? y/n: " ANSWER
    if [[ $ANSWER =~ ^[Yy]$ ]]; then
        echo "Make sure your proxy is running and make sure requests can come through"
        read -p "Give proxy IP and port (e.g. http://127.0.0.1:8080): " PROXY
        echo "aquatone will now start..."
        cat recon-folder/$DOMAIN.nmap.log.xml | aquatone -nmap -proxy $PROXY -out recon-folder || { echo -e "\e[31mError occured, please restart."; exit 1; }
    fi
    if [[ $ANSWER =~ ^[Nn]$ ]]; then
        echo "aquatone will now start..."
        cat recon-folder/$DOMAIN.nmap.log.xml | aquatone -nmap -out recon-folder || { echo -e "\e[31mError occured, please restart."; exit 1; }
    fi
    run_reporting
}

function run_reporting () {
    read -p "Do you want to open the aquatone report now? y/n: " ANSWER
    if [[ $ANSWER =~ ^[Yy]$ ]]; then
        PROGRAMLIST=(chromium google-chrome firefox)
        COUNTER=0
        for PROGRAM in ${PROGRAMLIST[*]}; do
            if ! [ -x "$(command -v $PROGRAM)" ]; then
                echo -e '\e[31m[-]' $COUNTER ${PROGRAMLIST[COUNTER]}  'is not installed or not in path' >&2; ((COUNTER=COUNTER + 1))
            else
                echo -e '\e[32m[+]' $COUNTER ${PROGRAMLIST[COUNTER]} 'is installed'; ((COUNTER=COUNTER + 1))
            fi
        done
        echo -e "\e[0m "
        read -p "Which browser should be used to open report? (0/1/2): " ANSWER
        if [[ "$ANSWER" =~ ^[0-2]$ ]]; then
            BROWSER=echo ${PROGRAMLIST[ANSWER]} recon-folder/aquatone_report.html || { echo -e "\e[31mError occured, please restart."; exit 1; }
        else
            run_reporting
        fi
    fi
}

function main () {
    echo -e "Subdomain-visualizer v0.3 by crypt0rr\n"
    echo -e "\e[31mFor educational purposes only! Do not use against domains you don't own / allowed to scan.\e[0m"; sleep 5
    requirement_checker
}

main