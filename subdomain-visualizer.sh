#!/bin/bash
function requirement_checker () {
    echo -e "\nChecking requirements..."
    PROGRAMLIST=(aquatone crobat nmap)
    COUNTER=0
    ALLPASS=TRUE
    for PROGRAM in ${PROGRAMLIST[*]}; do
        if ! [ -x "$(command -v $PROGRAM)" ]; then
            echo -e '\e[31m[-]' ${PROGRAMLIST[COUNTER]}  'is not installed or not in path' >&2; ((COUNTER=COUNTER + 1)); ALLPASS=FALSE
        else
            echo -e '\e[32m[+]' ${PROGRAMLIST[COUNTER]} 'is installed'; ((COUNTER=COUNTER + 1))
        fi
    done

    wget -q --spider http://google.com
    if [ $? -eq 0 ]; then
        echo -e "\e[32m[+] Internet connection up\e[0m"
    else
        echo -e "\e[31mYour internet connection seems down, please check before continuing"; exit 1
    fi

    if [ "$ALLPASS" == FALSE ]; then
        echo -e "\n\e[31mNot all requirements met please fix and try again"; exit 1
    fi
    echo -e "\e[0m"
}

function create_workingdir () {
    echo -e "\nFolder recon-folder will be created, this will contain results"
    mkdir recon-folder || { echo -e "\n\e[31mFolder recon-folder could not be created\e[0m"; EXISTS=1; }
    if [[ $EXISTS = '1' ]]; then
        read -p "Do you want to remove the existing recon-folder? y/n: " ANSWER
        if [[ $ANSWER =~ ^[Yy]$ ]]; then
            rm -rf recon-folder; echo -e "\e[32mDone, proceeding...\n\e[0m"; mkdir recon-folder
        else
            echo -e "\nCannot proceed, try again\e[0m\n"; main
        fi
    fi
}

function get_domain () {
    read -p "Please enter a domain to harvest (e.g. example.com): " DOMAIN
}

function run_crobat () {
    crobat -s $DOMAIN | tee recon-folder/$DOMAIN.crobat.log &>/dev/null
    echo "Total subdomains found by crobat:" $(cat recon-folder/$DOMAIN.crobat.log | wc -l)
}

function run_nmap () {
    echo -e "\nRunning nmap agains found subdomains"
    nmap -iL recon-folder/$DOMAIN.crobat.log -Pn -T4 -oA recon-folder/$DOMAIN.log || { echo -e "\e[31mError occured, please restart."; exit 1; }
}

function run_aquatone () {
    echo -e "\naquatone will now process the results for subdomains from $DOMAIN"
    read -p "Do you want to use a proxy (e.g. Burp Suite)? y/n: " ANSWER
    if [[ $ANSWER =~ ^[Yy]$ ]]; then
        echo "Make sure your proxy is running and make sure requests can come through"
        read -p "Give proxy IP and port (e.g. http://127.0.0.1:8080): " PROXY
        echo "aquatone will now start..."
        cat recon-folder/$DOMAIN.log.xml | aquatone -nmap -proxy $PROXY -out recon-folder || { echo -e "\e[31mError occured, please restart."; exit 1; }
    fi
    if [[ $ANSWER =~ ^[Nn]$ ]]; then
        echo "aquatone will now start..."
        cat recon-folder/$DOMAIN.log.xml | aquatone -nmap -out recon-folder || { echo -e "\e[31mError occured, please restart."; exit 1; }
    fi
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
    echo -e "Subdomain-visualizer v0.1 by crypt0rr\n"
    echo -e "\e[31mFor educational purposes only! Do not use against domains you don't own / allowed to scan.\e[0m"; sleep 5
    requirement_checker; create_workingdir; get_domain; run_crobat; run_nmap; run_aquatone; run_reporting
}

main