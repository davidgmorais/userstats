#!/bin/bash
IFS=$'\n'

######################################################################
#
#   FUNCOES PARA OBTER USERS
#

function getUsers {
    unset users
    i=0
    for line in `who | cut -d " " -f1 | uniq `;
    do 
        u="$line"
        users[$i]=$u
        i=($i+1)
    done
    return 0
}

function getUsersByRegex {
    # $1 -> expressao regex a procurar
    unset users
    i=0
    for line in `who | cut -d " " -f1 | uniq `;
    do 
        u=$(echo $line)
        if [[ $u =~ $1 ]];  #compare com regex passado como parametro em $1
        then
            users[$i]=$u
            i=($i+1)
        else
            return 0    #regex match not foundffff
        fi
        return 1
    done
}

function getUsersByGroup {
    # $1 -> nome do grupo a procurar
    unset users
    i=$(getent group $1 | rev | cut -d":" -f1 | rev)
    if [[ $i ]]
    then
        IFS=',' read -r -a users <<< "$i"
    else
        return 0        #group doest exist or has no users
    fi
    return 1
}

function countSessions() {
    #funcao para contar o nr de sessoes do user $1
    # $1 -> user
    for line in `who | cut -d " " -f1 | uniq -c| sed 's/^\s*//' ` ;
    do
        u=$(echo $line | cut -d" " -f2)
        if [[ $u == $1 ]]
        then
            nrSessions=$(echo $line | cut -d" " -f1)
            return $nrSessions
        fi    
    done
    return 0
}

function formatDate() {
    #$1 -> data
    count=0
    meses=("Jan" "Fev" "Mar" "Abr" "Mai" "Jun" "Jul" "Ago" "Sep" "Out" "Nov" "Dez")
    for mes in ${meses[@]}
    do
        m=$( echo $1 | cut -d" " -f1)
        if [[ $mes == $m ]]
        then
            dia=$( echo $1 | cut -d" " -f2)
            hora=$( echo $1 | cut -d" " -f3)
            data="2019-$(($count+1))-$dia $hora"
            return 1
        fi
        count=$((count+1))
    done
    return 0
    #TODO: exception handeling (invalid time value " Sep 2 20:00")
}

function totalTime() {
    #funcao que computa o tempo total de ligacao, duracao maxima e minima assim como o nr de sessoes e
    #adiciona-os ao array das estatiscas para o usuario $1
    # $1 -> user
    # $2 -> defined starting date
    # $3 -> defined finishing date

    # $4 -> file


    min=1000000000      #large int to simulate infinity
    max=-1000000000
    sum=0
    sumSec=0
    user=$1


    #TODO FIX THIS


    if [[ $4 && $4 != 0 ]]
    then

         if [[ $2 && $2 != 0 ]]
        then
            if [[ $3 && $3 != 0 ]]
            then
                s=("-s $2" "-t $3" "-f $4")   
                
            else
                s=("-s $2" "-f $4") 
            fi
        else 
            if [[ $3 && $3 != 0 ]]
            then
                s=("-t $3" "-f $4")   
            fi
        fi

    else

        if [[ $2 && $2 != 0 ]]
        then
            if [[ $3 && $3 != 0 ]]
            then
                s=("-s $2" "-t $3")   
                
            else
                s=("-s $2") 
            fi
        else 
            if [[ $3 && $3 != 0 ]]
            then
                s=(" -t $3")   
            fi
        fi

    fi


    
    
    for line in ` last $1 ${s[@]} | rev | cut -d" " -f1 | rev | grep -oP "\d{2}:\d{2}" `
    do
        h=$(echo $line | cut -d":" -f1)
        m=$(echo $line | cut -d":" -f2)
        t=$(( ${m#0}+${h#0}*60 ))
        sum=$(( $sum+$t ))
        if [ $t -lt $min ];
        then
            min=$t
        fi
        if [ $t -gt $max ];
        then
            max=$t
        fi
    done
    countSessions "$1"
    sessions=$?

    if [[ $max == -1000000000 ]]
    then
        max=0
    fi
    if [[ $min == 1000000000 ]]
    then
        min=0
    fi
   
    stats[$1]="$sessions    $sum    $max    $min"
    
}

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


    ################################################################
    #
    #   TESTS
    #

    sortLine2="-k$1"
    stats["marcos"]="1    1266    700    0"
    stats["pedro"]="6    90    100    4"
    stats["joao"]="23    3002    609    1"
    stats["andre"]="22    3012    619    1"
    stats["lucas"]="25    3024    609    23"


    echo "DEBBUGER: sorting options $sortLine1 $sortLine2"
    for k in "${!stats[@]}"
    do
        echo "$k    ${stats["$k"]}"
    done | sort $sortLine1 $sortLine2
}



######################################################################
#
#   INICIALIZAR VARS
#

users=()
gflag=0
uflag=0
start=0
end=0
file=0
rev=0
order=1
declare -A stats



######################################################################
#
#   TRATAMENTO DE OPCOES
#

while getopts ":g:u:s:e:f:rntai" OPTIONS; do
	case ${OPTIONS} in
		g ) # Search users by group
			gflag=1
            group=${OPTARG}
			;;

		u ) # Search users by regex
			uflag=1
            r=${OPTARG}
			;;

		s ) # Select period by starting data
            start=${OPTARG}
		    ;;

		e ) # Select period by ending data
            end=${OPTARG}
			;;

        f ) # Select file
            
            file=${OPTARG}			
            ;;

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


		* )	#Linha de comando inválida
			#usage
            echo "wrong usage"
			exit 1
			;;
esac
done

#VALIDACAO DE OPCOES

if (( $gflag && $uflag ))
then
    echo "Cant't use -g and -u at the same time"
    exit 1
fi

formatDate "$start"
start=$data
formatDate "$end"
end=$data



######################################################################
#
#   SEARCH FOR USERS
#

if [[ $gflag == 1 ]]
then
    getUsersByGroup "$group"
    if [[ $? == 0 ]]
    then
    echo "No user(s) found."
        exit 1
    fi
elif [[ $uflag == 1 ]];
then
    getUsersByRegex "$regex"
    if [[ $? == 0 ]]
    then
    echo "No user(s) found."
        exit 1
    fi
else
    getUsers
fi


for u in ${users[@]}
do
    totalTime $u $start $end $file
done

sortAndPrint $order $rev