#!/bin/bash


function menu
{
    echo "M) MODIFICAR CONFIGURACION"
    echo "J) JUGAR"
    echo "F) CLASIFICACION"
    echo "E) ESTADISTICAS"
    echo "S) SALIR"

    echo "Domino. Elija una opcion >>"
    read OPCION
}

function checkParameters
{
    if test $# -eq 1
    then
        if test $1 = "-g"
        then
            echo "Oscar Hernández Hernández"
            echo "Rubén Herrero Pérez"
        else
            echo "domino: invalid option -$*"
            echo "Usage: domino [option]"
            echo -e "\nOption:\n   -g       displayed group member data"
        fi
        exit 0

    elif test $# -gt 1
    then
        echo "domino: invalid option -$*"
        echo "Usage: domino [option]"
        echo -e "\nOption:\n   -g       displayed group member data"
        exit 0
    fi
}

function checkConfig 
{
	#Comprobar que existe .cfg
	FILE="config.cfg"
	if test ! -f "$FILE"
	then
		echo -e "ERROR. El archivo $FILE no existe.\n"
		exit
	fi
	#Comprobar si tenemos permisos de escritura y lectura sobre este
	checkReadWrite $FILE
	#Comprobar que el formato es el correcto
	checkFormatConfig $FILE
}

function checkReadWrite 
{
	if test ! -r "$*" -o ! -w "$*"
	then
		if test ! -r "$*" -a ! -w "$*"
		then
			echo -e "ERROR. El usuario no tiene permisos de lectura ni de escritura sobre el archivo $*\n"
			exit
		fi
		if test ! -r "$*"
		then
			echo -e "ERROR. El usuario no tiene permisos de lectura sobre el archivo $*\n"
			exit
		fi
		if test ! -w "$*"
		then
			echo -e "ERROR. El usuario no tiene permisos de escritura sobre el archivo $*\n"
			exit
		fi
		exit
	fi
}

function checkFormatConfig 
{
	#Comprobar que no esté vacio
	if test ! -s "$*"
	then
		echo -e "ERROR. El archivo $* está vacio\n"
		exit
	fi

	#Comprobar formato
	while IFS== read OPC DATA
	do
		if test $OPC = "JUGADORES"
		then
			if test $DATA -gt 4 -o $DATA -lt 2
			then
				echo -e "Error en los Jugadores.\nEl valor $DATA no es un valor valido.\nValores validos: 2,3,4\n"
				exit
			fi
			JUGADORES=$DATA
		elif test $OPC = "PUNTOSGANADOR"
		then
			if test $DATA -gt 100 -o $DATA -lt 50
			then
				echo -e "Error en Puntuación Ganadora.\nEl valor $DATA no es un valor valido.\nValores validos: Entre 50 y 100 incluidos\n"
				exit
			fi
			PUNTOSGANADOR=$DATA
		elif test $OPC = "INTELIGENCIA"
		then
			if test $DATA -lt 0 -o $DATA -gt 1
			then
				echo -e "Error en Inteligencia.\nEl valor $DATA no es un valor valido.\nValores validos: 0,1\n"
				exit
			fi
            INTELIGENCIA=$DATA
		elif test $OPC = "LOG"
		then
			#El fichero tiene que ser .log
			if [[ $DATA != *.log ]]
			then
				echo -e "Error en LOG.\nEl valor $DATA no es un valor valido.\n"
				exit 
			fi
			LOG=$DATA

		else
			echo -e "ERROR. El archivo $* tiene errores de formato en las opciones."
			exit
		fi
	done < config.cfg
}

function pedirJugadores
{
    OPVALIDA=1
    while test $OPVALIDA -eq 1
    do
        read -p "JUGADORES=" JUGADORES

        if ! [[ $JUGADORES =~ ^[0-9] ]]
        then
            echo "ERROR: No es un numero"

        elif test $JUGADORES -lt 2 -o $JUGADORES -gt 4
        then
            echo "ERROR: Jugadores no validos(>=2 y <=4)"
        else
            OPVALIDA=0
        fi
    done
}

function pedirPuntosGanador
{
    OPVALIDA=1
    while test $OPVALIDA -eq 1
    do
        read -p "PUNTOSGANADOR=" PUNTOSGANADOR

        if [[ $PUNTOSGANADOR =~ ^[0-9] ]]
        then
            if test $PUNTOSGANADOR -lt 50 -o $PUNTOSGANADOR -gt 100
            then
                echo "ERROR: Puntos ganador no validos(>=50 y <=100)"
            else
                OPVALIDA=0
            fi
        else
            echo "ERROR: No es un numero"
        fi
    done
}

function pedirInteligencia
{
    OPVALIDA=1
    while test $OPVALIDA -eq 1
    do
        read -p "INTELIGENCIA=" INTELIGENCIA

        if [[ $INTELIGENCIA =~ ^[0-9] ]]
        then
            if test $INTELIGENCIA -lt 0 -o $INTELIGENCIA -gt 1
            then
                echo "ERROR: Inteligencia no valida(0 o 1)"
            else
                OPVALIDA=0
            fi
        else
            echo "ERROR: No es un numero"
        fi
    done
}

function pedirLog
{
	echo -e "LOG actualmente es $LOG\n"

    read -p "NUEVA RUTA DEL LOG=" LOG
    LOG="${LOG%.*}.log" #Añade .log o cambia la extension
}

function modificarConfiguracion
{
    MODSALIR=1
    while test $MODSALIR -eq 1
    do
        echo "1) JUGADORES"
        echo "2) PUNTOSGANADOR"
        echo "3) INTELIGENCIA"
        echo "4) LOG"
        echo "5) TODOS"

        read -p "Datos a modificar(1,2,3,4,5): " MODOP

        MODSALIR=0
        case $MODOP in
            1) pedirJugadores;;
            2) pedirPuntosGanador;;
            3) pedirInteligencia;;
            4) pedirLog;;
            5)
                pedirJugadores
                pedirPuntosGanador
                pedirInteligencia
                pedirLog
                ;;
            *)
                echo "ERROR: Opcion no valida"
                MODSALIR=1
                ;;
        esac

        echo "JUGADORES=$JUGADORES" > config.cfg
        echo "PUNTOSGANADOR=$PUNTOSGANADOR" >> config.cfg
        echo "INTELIGENCIA=$INTELIGENCIA" >> config.cfg
        echo "LOG=$LOG" >> config.cfg
        
    done
}

function estadisticas
{
    if ! test -f $LOG #Si no se ha jugado ninguna partida (no existe log)
    then
        echo "Error: $LOG no existe"
        return
    fi

    NUMPARTIDAS=0
    MEDIAPUNTOSGANADOR=0
    MEDIARONDAS=0
    #MEDIATIEMPO=0 usar TIEMPOTOTAL/NUMPARTIDAS
    TIEMPOTOTAL=0
    PORCENTAJEINTEL=0 #Valor sobre 100
    MEDIASUMAPUNTOS=0


    while IFS='|' read FECHA HORA JUG TIEMPO RONDAS INTEL PUNGANADOR JUGANADOR PUNTOS
    do
        NUMPARTIDAS=$(($NUMPARTIDAS+1))
        MEDIAPUNTOSGANADOR=$(($MEDIAPUNTOSGANADOR + $PUNGANADOR))
        MEDIARONDAS=$(($MEDIARONDAS + $RONDAS))
        TIEMPOTOTAL=$(($TIEMPOTOTAL + $TIEMPO))
        
        if test $INTEL -eq 1
        then
            PORCENTAJEINTEL=$(($PORCENTAJEINTEL+1))
        fi

        IFS=-
        for J in $PUNTOS
        do
            if [[ $J =~ ^[0-9] ]] #Si el primer caracter es un numero del 0 al 9
            then
                MEDIASUMAPUNTOS=$(($MEDIASUMAPUNTOS + $J))
            fi
        done
    done < $LOG

    echo "Numero total de partidas jugadas: $NUMPARTIDAS"
    echo "Media de los puntos ganadores: $(($MEDIAPUNTOSGANADOR/$NUMPARTIDAS))"
    echo "Media de rondas de las partidas jugadas: $(($MEDIARONDAS/$NUMPARTIDAS))"
    echo "Media de los tiempos de todas las partidas jugadas: $(($TIEMPOTOTAL/$NUMPARTIDAS))"
    echo "Tiempo total invertido en todas las partidas: $TIEMPOTOTAL"
    echo "Porcentaje de partidas jugadas con inteligencia activada: $(($PORCENTAJEINTEL*100/$NUMPARTIDAS))%"
    echo "Media de la suma de los puntos obtenidos por todos los jugadores en las partidas jugadas: $(($MEDIASUMAPUNTOS/$NUMPARTIDAS))"
}

function clasificacion 
{
    if ! test -f $LOG #Si no se ha jugado ninguna partida (no existe log)
    then
        echo "Error: $LOG no existe"
        return
    fi

	IFS='|' read FECHA HORA JUG TIEMPO RONDAS INTEL PUNGANADOR JUGANADOR PUNTOS < $LOG
	TIMEMIN=$TIEMPO
	TIMEMAX=$TIEMPO
	ROUNDSMIN=$RONDAS
	ROUNDSMAX=$RONDAS
	POINTSWIN=$PUNGANADOR
	POINTS=0

	IFS=-
	for J in $PUNTOS
	do
		if [[ $J =~ ^[0-9] ]]
		then
			POINTS=$(($POINTS + $J))
		fi
	done
	POINTSTOTAL=$POINTS

	while IFS='|' read FECHA HORA JUG TIEMPO RONDAS INTEL PUNGANADOR JUGANADOR PUNTOS
	do
		#buscamos el tiempo minimo
		if test $TIEMPO -le $TIMEMIN
		then
			TIMEMIN=$TIEMPO
			TIEMPOMINDATOS="\nDatos de la partida mas corta:
			Fecha: $FECHA
			Hora: $HORA
			Jugadores: $JUG
			Tiempo: $TIEMPO
			Rondas: $RONDAS
			Inteligencia: $INTEL
			Puntos ganador: $PUNGANADOR
			Jugador ganador: $JUGANADOR
			Puntos totales: $POINTSTOTAL"
		fi
		
		#buscamos el tiempo maximo
		if test $TIEMPO -ge $TIMEMAX
		then
			TIMEMAX=$TIEMPO
			TIEMPOMAXDATOS="\nDatos de la partida mas larga:
			Fecha: $FECHA
			Hora: $HORA
			Jugadores: $JUG
			Tiempo: $TIEMPO
			Rondas: $RONDAS
			Inteligencia: $INTEL
			Puntos ganador: $PUNGANADOR
			Jugador ganador: $JUGANADOR
			Puntos totales: $POINTSTOTAL"
		fi

		#buscamos las maximas rondas
		if test $RONDAS -ge $ROUNDSMAX
		then
			ROUNDSMAX=$RONDAS
			RONDASMAXDATOS="\nDatos de la partida con mas rondas:
			Fecha: $FECHA
			Hora: $HORA
			Jugadores: $JUG
			Tiempo: $TIEMPO
			Rondas: $RONDAS
			Inteligencia: $INTEL
			Puntos ganador: $PUNGANADOR
			Jugador ganador: $JUGANADOR
			Puntos totales: $POINTSTOTAL"
		fi

		#buscamos las minimas rondas
		if test $RONDAS -le $ROUNDSMIN
		then
			ROUNDSMIN=$RONDAS
			RONDASMINDATOS="\nDatos de la partida con menos rondas:
			Fecha: $FECHA
			Hora: $HORA
			Jugadores: $JUG
			Tiempo: $TIEMPO
			Rondas: $RONDAS
			Inteligencia: $INTEL
			Puntos ganador: $PUNGANADOR
			Jugador ganador: $JUGANADOR
			Puntos totales: $POINTSTOTAL"
		fi

		if test $PUNGANADOR -ge $POINTSWIN
		then
			POINTSWIN=$PUNGANADOR
			PUNTOSGANADORMAXDATOS="\nDatos de la partida con maximo PuntosGanador:
			Fecha: $FECHA
			Hora: $HORA
			Jugadores: $JUG
			Tiempo: $TIEMPO
			Rondas: $RONDAS
			Inteligencia: $INTEL
			Puntos ganador: $PUNGANADOR
			Jugador ganador: $JUGANADOR
			Puntos totales: $POINTSTOTAL"
		fi

		#Datos de la partida con más puntos obtenidos por todos los jugadores
		POINTS=0
		IFS=-
		for J in $PUNTOS
		do
			if [[ $J =~ ^[0-9] ]]
			then
				POINTS=$(($POINTS + $J))
			fi
		done

		if test $POINTS -ge $POINTSTOTAL
		then
			POINTSTOTAL=$POINTS
			PUNTOSMAXDATOS="\nDatos de la partida con mas puntos obtenidos por todos los jugadores:
			Fecha: $FECHA
			Hora: $HORA
			Jugadores: $JUG
			Tiempo: $TIEMPO
			Rondas: $RONDAS
			Inteligencia: $INTEL
			Puntos ganador: $PUNGANADOR
			Jugador ganador: $JUGANADOR
			Puntos totales: $POINTSTOTAL"
		fi
	done < $LOG

	echo -e $TIEMPOMINDATOS
	echo -e $TIEMPOMAXDATOS
	echo -e $RONDASMAXDATOS
	echo -e $RONDASMINDATOS
	echo -e $PUNTOSGANADORMAXDATOS
	echo -e $PUNTOSMAXDATOS
}

function crearPozo
{
    echo "CREANDO POZO..."
    INDEX=0
    I=0
    while test $I -le 6
    do
        J=$I
        while test $J -le 6
        do
            POZO[$INDEX]="$I|$J"
            #echo -ne "${POZO[$INDEX]}\t"
            J=$(($J+1))
            INDEX=$(($INDEX+1))
        done
        #echo 
        I=$(($I+1))
    done
}

function obtenerFichaPozo #Usar FICHA par obtener la ficha devuelta
{
    POS=$(($RANDOM%$FICHASPOZO))
    FICHA=${POZO[$POS]}

    #Mover las fichas a una posicion anterior en el vector
    POS=$(($POS+1))
    while test $POS -lt $FICHASPOZO
    do
        POZO[$(($POS-1))]=${POZO[$POS]}
        POS=$(($POS+1))
    done

    FICHASPOZO=$(($FICHASPOZO-1))
}

function repartirFichasJugadores
{
    echo "REPARTIENDO FICHAS JUGADORES..." 

    JUG=0
    while test $JUG -lt $JUGADORES
    do
        NUMEROFICHAS[$JUG]=7

        I=0
        while test $I -lt ${NUMEROFICHAS[$JUG]}
        do
            obtenerFichaPozo

			#Cada jugador puede tener hasta 28 fichas, por si roba en el pozo
            FICHASJUGADORES[$(($JUG*28+$I))]=$FICHA #Equivalente a FICHASJUGADORES[$I][$J] ($JUGADORES * 28)

            I=$(($I+1))
        done

        JUG=$(($JUG+1))
    done
}

function mostrarPozo
{
    echo
    echo "MOSTRANDO POZO..."
    INDEX=0
    while test $INDEX -lt $FICHASPOZO
    do
        echo "${POZO[$INDEX]}"
        INDEX=$(($INDEX+1))
    done
}

function mostrarFichasJugadores
{
    echo
    JUG=0
    while test $JUG -lt $JUGADORES
    do  
        mostrarFichasJugador $JUG
        JUG=$(($JUG+1))
    done
}

function mostrarFichasJugador
{
    if test $1 -eq 0
    then
        echo "FICHAS USUARIO:"
    else
        echo "FICHAS BOT $(($1-1)):"
    fi
    
    I=0
    while test $I -lt ${NUMEROFICHAS[$1]}
    do
        echo -ne "$I=${FICHASJUGADORES[$(($1*28+$I))]}\t"
        I=$(($I+1))
    done
    echo
}

function colocarFichaUsuario
{
    FICHAVALIDA=1
    while test $FICHAVALIDA -eq 1
    do
        FICHAVALIDA=0

        #mostrarInfoPartida
        mostrarFichasJugador 0
        read -p "Selecciona una ficha: " POSFICHA

        while [[ ! $POSFICHA =~ ^[0-9] || $POSFICHA -lt 0 || $POSFICHA -ge ${NUMEROFICHAS[0]} ]]
        do
            echo "Ficha no valida"
            read -p "Selecciona una ficha: " POSFICHA
        done

        FICHA=${FICHASJUGADORES[$((0*28+$POSFICHA))]}

        comprobarFicha 0 $FICHA
    done

    #Mover las fichas a una posicion anterior en el vector
    POSFICHA=$(($POSFICHA+1))
    while test $POSFICHA -lt ${NUMEROFICHAS[0]}
    do
        FICHASJUGADORES[$((0*28+$(($POSFICHA-1))))]=${FICHASJUGADORES[$((0*28+$POSFICHA))]}
        POSFICHA=$(($POSFICHA+1))
    done
    NUMEROFICHAS[0]=$((${NUMEROFICHAS[0]}-1))
}

function comprobarRobo
{
    if test -z $CADENAFICHAS
    then
        echo "No hay fichas colocadas"
        return 1 #Si no hay fichas colocadas no hay que robar
    fi

    CADINICIO=${CADENAFICHAS:0:1}
    CADFIN=${CADENAFICHAS:$((${#CADENAFICHAS}-1))}

    INDEX=0
    while test $INDEX -lt ${NUMEROFICHAS[$1]}
    do
        FICHA=${FICHASJUGADORES[$(($1*28+$INDEX))]}
        FICHAINICIO=${FICHA:0:1}
        FICHAFIN=${FICHA: $((${#FICHA}-1))}

        #Comprueba si el numero inicial de cada ficha coincide con los extremos
        if test $FICHAINICIO -eq $CADINICIO -o $FICHAINICIO -eq $CADFIN
        then
            #echo "No hay que robar"
            return 1 #Existe una ficha que se puede colocar
        fi

        #Comprueba si el numero final de cada ficha coincide con los extremos
        if test $FICHAFIN -eq $CADINICIO -o $FICHAFIN -eq $CADFIN
        then
            #echo "No hay que robar"
            return 1 #Existe una ficha que se puede colocar
        fi
        
        INDEX=$(($INDEX+1))
    done

    echo "Hay que robar"
    return 0 #Es necesario robar
}

function robarFicha
{
    obtenerFichaPozo
    FICHASJUGADORES[$(($1*28+${NUMEROFICHAS[$1]}))]=$FICHA
    NUMEROFICHAS[$1]=$((${NUMEROFICHAS[$1]}+1))
}

#Comprueba todo lo relacionado con la colocacion de la ficha, el robo y su colocacion
function comprobarFicha #$1->jugador (FICHA se obtiene antes de llamar a la funcion)
{
    if test ! -z $CADENAFICHAS #Comprueba si la cadena no esta vacia
    then
        #Comprobar si se puede colocar la ficha al final (normal o girada)
        if test ${FICHA:0:1} = ${CADENAFICHAS: $((${#CADENAFICHAS}-1))}
        then
            #echo "Se puede poner al final normal"
            CADENAFICHAS="$CADENAFICHAS$FICHA"
        else
            #echo "No se puede poner al final normal"

            #Gira la ficha
            FICHA="${FICHA: $((${#FICHA}-1))}|${FICHA:0:1}"
            if test ${FICHA:0:1} = ${CADENAFICHAS: $((${#CADENAFICHAS}-1))}
            then
                #echo "Se puede poner al final girado"
                CADENAFICHAS="$CADENAFICHAS$FICHA"
            else
                #echo "No se puede poner al final girado"
                FICHAVALIDA=1 #La ficha no se puede colocar
            fi
        fi

        #Comprobar si se puede colocar la ficha al inicio (normal o girada) y no se ha colocado
        if test $FICHAVALIDA -eq 1
        then
            FICHAVALIDA=0
            if test ${FICHA: $((${#FICHA}-1))} = ${CADENAFICHAS:0:1}
            then
                #echo "Se puede poner al inicio girado"
                CADENAFICHAS="$FICHA$CADENAFICHAS"
            else
                #echo "No se puede poner al inicio girado"

                #Gira la ficha
                FICHA="${FICHA: $((${#FICHA}-1))}|${FICHA:0:1}"
                if test ${FICHA: $((${#FICHA}-1))} = ${CADENAFICHAS:0:1}
                then
                    #echo "Se puede poner al inicio normal"
                    CADENAFICHAS="$FICHA$CADENAFICHAS"
                else
                    #echo "No se puede poner al inicio normal"
                    echo "Ficha no valida"
                    FICHAVALIDA=1 #La ficha no se puede colocar
                fi
            fi
        fi
    else
        CADENAFICHAS="$CADENAFICHAS$FICHA" #Si la cadena esta vacia se pone la ficha sin mas
    fi

    #Si no se puede colocar esa ficha, se comprueba si hace falta robar o no
    if test $FICHAVALIDA -eq 1
    then
        comprobarRobo $1
        if test $? -eq 0 #Si hay que robar
        then
            if test $FICHASPOZO -eq 0
            then
                echo "Pozo vacio, no se puede robar"
            else
                robarFicha $1
                return 0
            fi    
        fi
    fi

    return 1 #Se devuelve se ha hecho falta robar 0->si 1->no
}

#Ordena descendentemente las fichas de la mano del bot $1 para elegir la ficha con más valor
function ordenarFichasBot #1->jugador
{
    I=0
    while test $I -lt ${NUMEROFICHAS[$1]}
    do
        J=1
        while test $J -lt $((${NUMEROFICHAS[$1]}-$I))
        do
            FICHA1=${FICHASJUGADORES[$(($1*28+$(($J-1))))]}
            VALORFICHA1=$((${FICHA1:0:1} + ${FICHA1:$((${#FICHA1}-1))}))
            FICHA2=${FICHASJUGADORES[$(($1*28+$J))]}
            VALORFICHA2=$((${FICHA2:0:1} + ${FICHA2:$((${#FICHA2}-1))}))

            if test $VALORFICHA1 -lt $VALORFICHA2
            then
                FICHASJUGADORES[$(($1*28+$(($J-1))))]=$FICHA2
                FICHASJUGADORES[$(($1*28+$J))]=$FICHA1
            fi 
            J=$(($J+1))
        done
        I=$(($I+1))
    done
}

function colocarFichaBot
{
    if test $INTELIGENCIA -eq 1
    then
        ordenarFichasBot $1
        POSFICHA=-1
    fi
    mostrarFichasJugador $1

	FICHAVALIDA=1
	while test $FICHAVALIDA -eq 1
	do
		FICHAVALIDA=0
        POSFICHA=$(($POSFICHA+1))

        if test $INTELIGENCIA -eq 0
        then
            POSFICHA=$(($RANDOM % ${NUMEROFICHAS[$1]})) #Pos entre 0 y NUMEROFICHAS[$1] -1
        fi

        FICHA=${FICHASJUGADORES[$(($1*28+$POSFICHA))]}

        comprobarFicha $1

        if test $INTELIGENCIA -eq 1 -a $? -eq 0 #Se ha robado ficha
        then
            ordenarFichasBot $1
            POSFICHA=0      
        fi
	done

    #Mover las fichas a una posicion anterior en el vector
    POSFICHA=$(($POSFICHA+1))
    while test $POSFICHA -lt ${NUMEROFICHAS[$1]}
    do
        FICHASJUGADORES[$(($1*28+$(($POSFICHA-1))))]=${FICHASJUGADORES[$(($1*28+$POSFICHA))]}
        POSFICHA=$(($POSFICHA+1))
    done
    NUMEROFICHAS[$1]=$((${NUMEROFICHAS[$1]}-1))
}

#Ordena el vector con la puntuacion de los jugadores en orden descendente (ordenacion por burbuja)
function ordenarPuntosJugadores
{
    I=0
    while test $I -lt $JUGADORES
    do
        J=1
        while test $J -lt $(($JUGADORES-$I))
        do
            if test ${PUNTOSJUGADORES[$(($J-1))]} -lt ${PUNTOSJUGADORES[$J]}
            then
                AUX=${PUNTOSJUGADORES[$(($J-1))]}
                PUNTOSJUGADORES[$(($J-1))]=${PUNTOSJUGADORES[$J]}
                PUNTOSJUGADORES[$J]=$AUX
            fi 
            J=$(($J+1))
        done
        I=$(($I+1))
    done
}

function mostrarInfoPartida
{
	echo
	echo "-------------------------------------"
    echo "RONDA: $RONDAS"
    echo "TURNO: $TURNO"
    echo "FICHAS EN MESA: $CADENAFICHAS"
    echo "FICHAS EN POZO: "$FICHASPOZO
    echo "PUNTOS JUGADORES: ${PUNTOSJUGADORES[*]}"
	echo "-------------------------------------"
}

function iniciarDatosRonda
{
    CADENAFICHAS=""
    FICHASPOZO=28

    crearPozo
    repartirFichasJugadores

    mostrarFichasJugadores
    #mostrarPozo
}

#Calcula que jugador debe empezar
function primerJugador
{
    MEJORJUG=0
    MEJORVALOR=0
    DOBLE=1

    I=0
    while test $I -lt $JUGADORES
    do
        J=0
        while test $J -lt ${NUMEROFICHAS[$I]}
        do
            FICHA=${FICHASJUGADORES[$I*28+$J]}
            
            #Si es una ficha doble
            if test ${FICHA:0:1} -eq ${FICHA:$((${#FICHA}-1))} #ge por si la unica ficha doble es 0|0
            then
                VALORACT=$((${FICHA:0:1} + ${FICHA:$((${#FICHA}-1))}))

                if test $VALORACT -ge $MEJORVALOR
                then
                    MEJORVALOR=$VALORACT
                    MEJORJUG=$I
                    DOBLE=0 #Ha encontrado una ficha doble
                fi
            fi
            J=$(($J+1))
        done
        I=$(($I+1))
    done


    #Si no ha encontrado una ficha doble, hay que buscar la ficha con valor max
    if test $DOBLE -eq 1 
    then
        MEJORJUG=0
        MEJORVALOR=0

        I=0
        while test $I -lt $JUGADORES
        do
            J=0
            while test $J -lt ${NUMEROFICHAS[$I]}
            do
                FICHA=${FICHASJUGADORES[$I*28+$J]}
                VALORACT=$((${FICHA:0:1} + ${FICHA:$((${#FICHA}-1))}))

                if test $VALORACT -gt $MEJORVALOR
                then
                    MEJORVALOR=$VALORACT
                    MEJORJUG=$I
                fi

                J=$(($J+1))
            done
            I=$(($I+1))
        done
    fi

    return $MEJORJUG #Devuelve el numero del jugador que debe empezar
}

#Suma los puntos de las manos de los jugadores (excepto $1) y se suma a PUNTOSJUGADORES[$1]
function sumarPuntos
{
	I=0
	while test $I -lt $JUGADORES
	do

		J=0
		while test $J -lt ${NUMEROFICHAS[$I]} #El jugador ganador tiene 0 en NUMEROFICHAS
		do
			FICHA=${FICHASJUGADORES[$(($I*28+$J))]}

            PUNTOSJUGADORES[$1]=$((${PUNTOSJUGADORES[$1]}+$((${FICHA:0:1} + ${FICHA:$((${#FICHA}-1))}))))
            J=$(($J+1))
		done
        I=$(($I+1))
	done
}

function jugar
{
	MEJORPUNTOS=0
    TIEMPOINICIO=$SECONDS

    #Iniciar vector PUNTOSJUGADORES
    I=0
    while test $I -lt 4
    do
        if test $I -lt $JUGADORES
        then
            PUNTOSJUGADORES[$I]=0
        else
            PUNTOSJUGADORES[$I]="*"
        fi
        I=$(($I+1))
    done
	
	RONDAS=0
    FINPARTIDA=1
	while test $FINPARTIDA -eq 1 #Mientras no se alcance los puntos para ganar
	do
		iniciarDatosRonda #Se crean los vectores con las fichas en el pozo, las manos, tiempo...

		FINRONDA=1

		primerJugador

		TURNO=$?
		while test $FINRONDA -eq 1 #Mientras no haya terminado la ronda
		do
			mostrarInfoPartida

			if test $TURNO -eq 0 #Turno del usuario
			then
                echo
				echo "--------------TURNO DEL USUARIO--------------"
				colocarFichaUsuario
			else
                echo
				echo "--------------TURNO DEL BOT $(($TURNO-1)) (INTELIGENCIA=$INTELIGENCIA)--------------"
				colocarFichaBot $TURNO
			fi

			if test ${NUMEROFICHAS[$TURNO]} -eq 0
			then
				sumarPuntos $TURNO
				FINRONDA=0

                if test ${PUNTOSJUGADORES[$TURNO]} -ge $PUNTOSGANADOR
                then
                    if test $TURNO -eq 0
                    then
                        JUGADORGANADOR="Usuario"
                    else
                        JUGADORGANADOR="BOT $(($TURNO-1))"
                    fi
                    FINPARTIDA=0
                fi

            else
                TURNO=$(($(($TURNO+1))%$JUGADORES))
			fi

		done
        RONDAS=$(($RONDAS+1))
	done

	TIEMPO=$(($SECONDS - $TIEMPOINICIO))

    #mostrar datos ganador
    echo "JUGADOR GANADOR: $JUGADORGANADOR"
    echo "PUNTOS GANADOR: ${PUNTOSJUGADORES[$TURNO]}"

    ordenarPuntosJugadores

	CADENAPUNTOS="${PUNTOSJUGADORES[0]}-${PUNTOSJUGADORES[1]}-${PUNTOSJUGADORES[2]}-${PUNTOSJUGADORES[3]}"
	echo "`date +%d%m%y`|`date +%H:%M`|$JUGADORES|$TIEMPO|$RONDAS|$INTELIGENCIA|$PUNTOSGANADOR|$JUGADORGANADOR|$CADENAPUNTOS" >> $LOG
}

checkParameters $*
checkConfig

SALIR=1
while test $SALIR -eq 1
do
    menu
    
    case $OPCION in
    "m"| "M")
        echo "MODIFICAR CONFIGURACION"
		modificarConfiguracion
        ;;

    "j" | "J")
        echo "JUGAR"
		jugar
        ;;

    "f" | "F")
        echo "CLASIFICACION"
        clasificacion
        ;;

    "e" | "E")
        echo "ESTADISTICAS"
        estadisticas
        ;;

    "s" | "S")
        echo "SALIR"
        SALIR=0
        ;;
    *)
        echo "Opcion no valida"
        ;;
    esac

    echo "pulse INTRO para continuar"
    read
done

exit 0
