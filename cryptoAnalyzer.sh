#!/bin/bash
# cryptoAnalyzer v1.0, Author @4xeL

# Colours
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
greenColour="\e[0;32m\033[1m"
yellowColour="\e[0;33m\033[1m"
blueColour="\e[0;34m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# variables globales
unconfirmed_transactions="https://www.blockchain.com/es/btc/unconfirmed-transactions"
url_transaction_inspection="https://www.blockchain.com/es/btc/tx/"
inspect_address_url="https://www.blockchain.com/es/btc/address/"

trap ctrl_c INT

# Funciones

# fucion ctrl_c    ///Para rederigir el flugo si quiero  cerrar el programa.
function ctrl_c (){
  echo -e "\n${redColour}[!]exit to program....!!!!!\n${endColour}"
  rm ut.t* money* total_entrada_salida.tmp entradas.tmp salidas.tmp bitcoin_to_dollars 2>/dev/null
  tput cnorm; exit 1
}
sleep 1

# help panel
function help_panel(){
  echo -e "\n${redColour}[!]ejecutar: ./cryptoanalyzer\n${endColour}"
  for i in $(seq 1 80); do echo -ne "${redColour}-"; done; echo -ne "${endColour}"
  echo -e "\n\n\t${grayColour}[-e] ${endColour}${yellowColour}Mode explorator${endColour}"
  echo -e "\t\t${purpleColour}unconfirmed_transaction${endColour}${turquoiseColour}:\t Unconfirmed transaction${endColour}"
  echo -e "\t\t${purpleColour}inspect${endColour}${turquoiseColour}:\t\t\t Transaction inspection${endColour}"
  echo -e "\t\t${purpleColour}address${endColour}${turquoiseColour}:\t\t\t Address url${endColour}"
  echo -e "\n\t${grayColour}[-n] ${endColour}${yellowColour}Number of results${endColour}${blueColour}\t\t\t Example: -n 10 ${endColour}"
  echo -e "\n\t${grayColour}[-i]${endColour}${yellowColour} Provides the transaction hash${endColour}${blueColour} (Example: -i 000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f)${endColour}"
	echo -e "\n\t${grayColour}[-a]${endColour}${yellowColour} Provides the transaction address${endColour}${blueColour} (Example: -a 1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa)${endColour}"
  echo -e "\n\t${grayColour}[-h] ${endColour}${yellowColour}Help\n${endColour}"

  tput cnorm; exit 1
}

function printTable(){

    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines(){

    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString(){

    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString(){

    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString(){

    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}


function dependencies(){

	tput civis; counter=0
	dependencies_array=(html2text bc)

	echo; for program in "${dependencies_array[@]}"; do
		if [ ! "$(command -v $program)" ]; then
			echo -e "${redColour}[X]${endColour}${grayColour} $program${endColour}${yellowColour} no está instalado${endColour}"; sleep 1
			echo -e "\n${yellowColour}[i]${endColour}${grayColour} Instalando...${endColour}"; sleep 1
			apt install $program -y > /dev/null 2>&1
			echo -e "\n${greenColour}[V]${endColour}${grayColour} $program${endColour}${yellowColour} instalado${endColour}\n"; sleep 2
			let counter+=1
		fi
	done
}

function unconfirmedTransaction(){
  
  number_output=$1
  echo '' > ut.tmp
  while [ "$(cat ut.tmp | wc -l)" == "1" ]; do
  curl -s "$unconfirmed_transactions" | html2text > ut.tmp
  done

  hashes=$(cat ut.tmp | grep "Hash" -A 1 | grep -v -E "Hash|\--|Tiempo" | head -n $number_output)    
  echo "Hash_Tiempo_Bitcoin_Cantidad" > ut.table
  for hash in $hashes; do
  echo "${hash}_$(cat ut.tmp | grep "$hash" -A 2 | tail -n 1)_$(cat ut.tmp | grep "$hash" -A 4 | tail -n 1)_$(cat ut.tmp | grep "$hash" -A 6 | tail -n 1 | tr -d 'Â')" >> ut.table
  done

  cat ut.table | tr '_' ' ' | awk '{print $5}' | grep -v 'Cantidad' | tr -d 'US$' | tr -d ',' | sed 's/\..*//g' > money

  cat money | while read num_in_line; do
    let num+=$num_in_line
    echo $num > money.tmp
    done;

  echo -n "Cantidad total_" > amount.table
  echo "\$$(printf "%\'.d\n" $(cat money.tmp))" >> amount.table
      if [ "$(cat ut.table | wc -l)" != "1" ]; then
        echo -ne "${yellowColour}"
        printTable '_' "$(cat ut.table)"
        echo -ne "${endColour}"
        echo -ne "${redColour}"
        printTable '_' "$(cat amount.table)"
        echo -ne "${endColour}"
        rm ut.* money* amount.table 2>/dev/null
        tput cnorm; exit 0
        else
          rm ut.t* 2>/dev/null
      fi

    rm ut.* money* amount.table
    tput cnorm
}   

function inspectTransaction(){
  inspect_transaction_hash=$1

	echo "Entrada Total_Salida Total" > total_entrada_salida.tmp

	while [ "$(cat total_entrada_salida.tmp | wc -l)" == "1" ]; do
		curl -s "${url_transaction_inspection}${inspect_transaction_hash}" | html2text | grep -E "Entradas totales|Gastos totales" -A 1  | grep -v -E "Entradas totales|Gastos totales" | xargs | tr ' ' '_' | sed 's/_BTC/ BTC/g' >> total_entrada_salida.tmp
	done

	echo -ne "${grayColour}"
	printTable '_' "$(cat total_entrada_salida.tmp)"
	echo -ne "${endColour}"
	rm total_entrada_salida.tmp 2>/dev/null

	echo "Dirección (Entradas)_Valor" > entradas.tmp

	while [ "$(cat entradas.tmp | wc -l)" == "1" ]; do
		curl -s "${url_transaction_inspection}${inspect_transaction_hash}" | html2text | grep "Entradas$" -A 500 | grep "Gastos" -B 500 | grep "DirecciÃ³n"  -A 3 | grep -v -E "DirecciÃ³n|Valor|\--" | awk 'NR%2{printf "%s ",$0;next;}1' | awk '{print $1 "_" $2 " " $3}' >> entradas.tmp 
  done

	echo -ne "${greenColour}"
	printTable '_' "$(cat entradas.tmp)"
	echo -ne "${endColour}"
	rm entradas.tmp 2>/dev/null

	echo "Dirección (Salidas)_Valor" > salidas.tmp

	while [ "$(cat salidas.tmp | wc -l)" == "1" ]; do
		curl -s "${url_transaction_inspection}${inspect_transaction_hash}" | html2text | grep "Gasto" -A 500 | grep "***** Ya lo has pensado, es hora de actuar. *****" -B 500 | grep "DirecciÃ³n"  -A 3 | grep -v -E "DirecciÃ³n|Valor|\--" | awk 'NR%2{printf "%s ",$0;next;}1' | awk '{print $1 "_" $2 " " $3}' >> salidas.tmp
	done

	echo -ne "${greenColour}"
	printTable '_' "$(cat salidas.tmp)"
	echo -ne "${endColour}"
	rm salidas.tmp 2>/dev/null
	tput cnorm
}

function inspectAddress(){

	address_hash=$1
	echo "Transacciones realizadas_Cantidad total recibida (BTC)_Cantidad total enviada (BTC)_Saldo total en la cuenta (BTC)" > address.information
	curl -s "${inspect_address_url}${address_hash}" | html2text | grep -E "Transacciones|Total recibido|Total enviado|Saldo final|--" -A 1 | head -n -2 | grep -v -E "Transacciones|Total recibido|Total enviado|Saldo final|--" | xargs | tr ' ' '_' | sed 's/_BTC/ BTC/g' >> address.information

	echo -ne "${grayColour}"
	printTable '_' "$(cat address.information)"
	echo -ne "${endColour}"
	rm address.information 2>/dev/null

	bitcoin_value=$(curl -s "https://www.binance.com/es/price/bitcoin" | html2text | grep "Actualmente" | awk 'NF{print $12}' | tr -d ',' | sed 's/\.*//g')

	curl -s "${inspect_address_url}${address_hash}" | html2text | grep "Transacciones" -A 1 | head -n -2 | grep -v -E "Transacciones|\--" > address.information
	curl -s "${inspect_address_url}${address_hash}" | html2text | grep -E "Total recibido|Total enviado|Saldo final" -A 1 | grep -v -E "Total recibido|Total enviado|Saldo final|\--" > bitcoin_to_dollars

	cat bitcoin_to_dollars | while read value; do
		echo "\$$(printf "'%'.d\n" $(echo "$(echo $value | awk '{print $1}')*$bitcoin_value" | bc) 2>/dev/null)" >> address.information
	done

	line_null=$(cat address.information | grep -n "^\$$" | awk '{print $1}' FS=":")

	if [ "$(echo $line_null | grep -oP '\w')" ]; then
		echo $line_null | tr ' ' '\n' | while read line; do
			sed "${line}s/\$/0.00/" -i address.information
		done
	fi

	cat address.information | xargs | tr ' ' '_' >> address.information2
	rm address.information 2>/dev/null && mv address.information2 address.information
	sed '1iTransacciones realizadas_Cantidad total recibida (USD)_Cantidad total enviada (USD)_ Saldo actual en la cuenta (USD)' -i address.information

	echo -ne "${grayColour}"
	printTable '_' "$(cat address.information)"
	echo -ne "${endColour}"

	rm address.information bitcoin_to_dollars 2>/dev/null
	tput cnorm
}

# Main

dependencies; parameter_counter=0 
while getopts "e:n:i:a:h:" opt; do
  case "$opt" in
    e) unconfirmed_t=$OPTARG; let parameter_counter+=1;;
    n) number_output=$OPTARG; let parameter_counter+=1;;
    i) inspection_t=$OPTARG; let parameter_counter+=1;;
    a) address_url=$OPTARG; let parameter_counter+=1;;
    h) help_panel=$OPTARG;;
   esac
done

tput civis

if [ $parameter_counter -eq 0 ]; then
  help_panel
else
  if [ "$(echo $unconfirmed_t)" ==  "unconfirmed_transaction" ]; then
	  if [ ! "$number_output" ]; then
      number_output=50
      unconfirmedTransaction $number_output
    else
		  unconfirmedTransaction $number_output
	  fi
	elif [ "$(echo $unconfirmed_t)" == "inspect" ]; then
		inspectTransaction $inspection_t
	elif [ "$(echo $unconfirmed_t)" == "address" ]; then
		inspectAddress $address_url
	fi
fi





















