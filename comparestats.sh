#!/bin/bash
IFS=$'\n'

function sortAndPrint() {
    # $1 sort based on which colum
    #(where:1st column = user,
    #       2nd column = nr of sessions,
    #       3rd column = total connection time,
    #       4th column = max duration,
    #       5th column = min duration)
    # $2 order (0 for normal, 1 for reverse)

    if [[ $1 == "1" ]];
    then
        #alfabetico
        sortLine1="-"
    else
        #numerico
        sortLine1="-n"
    fi

    if [[ $2 == "1" ]];
    then
        #sort baseado na coluna $2
        sortLine1+="r"
    fi


    sortLine2="-k$1"

    echo "DEBBUGER: sorting options $sortLine1 $sortLine2"
    for k in "${!compared[@]}"
    do
        echo "$k    ${compared["$k"]}"
    done | sort $sortLine1 $sortLine2
}



function format(){

    local string=""
    
    for i in {1..4}
    do
        local par="-f$i"
        local val1=$(echo $1 | cut -d" " $par)
              string+="$val1    "
    done
        compared[$2]=$string

    

}

function compare() {
    #$1 -> string1
    #$2 -> string2
    #$3 -> user

    local string=""
    for i in {1..4}
    do
        local par="-f$i"
        local val1=$(echo $1 | cut -d" " $par)
        local val2=$(echo $2 | cut -d" " $par)
        local sub=$(( $val1 - $val2 ))
        string+="$sub "
        
    done

    compared[$3]=$string
}

function dic_contain() {
    local key="$1"
    shift 
    local dic=("$@")
    flag=1
    
    
    for element in "${dic[@]}";do 
        if [[ $element == $key ]]
        then 
            flag=0
            break 
        fi 
    done
}


#_________________________VARS___________________________________

order=1;
rev=0;
file1=$1
file2=$2
declare -A userFile1
declare -A userFile2
declare -A compared    

#________________________OPTIONS_________________________________

while getopts "rntai" OPTIONS; do
    case ${OPTIONS} in
        
        r ) # Ordenar pela ordem contrária
            rev=1
            ;;

        n ) # ordenar pelo nr de sessoes
            order=2
            ;;

        t ) # ordenar por tempo total
            order=3
            ;;

        a ) # ordenar por tempo maximo
            order=4
            ;;

        i ) # ordenar por tempo minimo
            order=5
            ;;


        * ) #Linha de comando inválida
            echo "Wrong Usage"
            exit 1
            ;;
    esac
done


#______________________________________________________



#Ler as linhas do file1 e por num dicionario userFile1
while read -r line; do

    Data1=$(echo $line | tr -s ' ' | cut -d" " -f2-5)
    Key1=$(echo $line | tr -s ' ' | cut -d" " -f1)
    userFile1[$Key1]="$Data1"
done <"$file1"


#ler as linhas do file2 e por num dicionario userFile2
while read -r line; do
   
    Data2=$(echo $line | tr -s ' ' | cut -d " " -f2-5)
    Key2=$(echo $line | tr -s ' ' | cut -d " " -f1)
    userFile2[$Key2]="$Data2"
done <"$file2"  


#Comparação entre os diciponários para os váridos ficheiros  
for j in "${!userFile2[@]}"; do 
	for i in "${!userFile1[@]}"; do
		if [[ $j == $i ]]
		then
			compare ${userFile2["$j"]} ${userFile1["$i"]} "$j"

		fi 
 	done
done

for i in "${!userFile1[@]}"; do
    
    dic_contain $i "${!userFile2[@]}" 
        if [[ $flag == 1 ]]
        then
            #echo "debug -->" $i
            compared+=([$i]=${userFile1[$i]})
        fi
done
for j in "${!userFile2[@]}"; do
    
    dic_contain $j "${!userFile1[@]}" 
        if [[ $flag == 1 ]]
        then
            compared+=([$j]=${userFile2[$j]})
        fi
done


#Print ao dicionário 
#for l in ${!compared[@]}; do 
#    format ${compared["$l"]} $l    
#    echo "$l    ${compared["$l"]}" 
#done

sortAndPrint $order $rev
