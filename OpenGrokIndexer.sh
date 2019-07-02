#!/bin/sh

#realizado por: Adrian Nuñez Sanchez
#http://patorjk.com/software/taag/#p=display&h=0&v=0&c=echo&f=ANSI%20Shadow&t=Atradius%20OpenGrok%20Indexer

echo "                                                                    	  														 "
echo " ██████╗ ██████╗ ███████╗███╗   ██╗ ██████╗ ██████╗  ██████╗ ██╗  ██╗    ██╗███╗   ██╗██████╗ ███████╗██╗  ██╗███████╗██████╗ "
echo "██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔════╝ ██╔══██╗██╔═══██╗██║ ██╔╝    ██║████╗  ██║██╔══██╗██╔════╝╚██╗██╔╝██╔════╝██╔══██╗"
echo "██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║  ███╗██████╔╝██║   ██║█████╔╝     ██║██╔██╗ ██║██║  ██║█████╗   ╚███╔╝ █████╗  ██████╔╝"
echo "██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██║   ██║██╔══██╗██║   ██║██╔═██╗     ██║██║╚██╗██║██║  ██║██╔══╝   ██╔██╗ ██╔══╝  ██╔══██╗"
echo "╚██████╔╝██║     ███████╗██║ ╚████║╚██████╔╝██║  ██║╚██████╔╝██║  ██╗    ██║██║ ╚████║██████╔╝███████╗██╔╝ ██╗███████╗██║  ██║"
echo " ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝    ╚═╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"
echo "                                                                                                                              "
echo "                                                                       														 "



function get_properties {
    grep "${1}" /opengrok/scripts/repositoryIndexer/variables.properties | cut -d'=' -f2
}


function choose_branch {
			export ORACLE_HOME=/jdev/oracle/soabpm/
			branch='false'
			if [ $branch == 'false' ];
            then
                echo 'Introduzca la rama que deseas descargar: (Si presiona enter descargara' $(get_properties 'app.github.defaultBranch') 'por defecto)'
                read branch
				if [[ $branch == "" ]];
				then
					branch=$(get_properties 'app.github.defaultBranch')
				fi
            fi
			echo 'La rama es '$branch
			get_repositories $branch
}

function get_repositories {
			#Realizamos una llamada al GIT para conformar los ficheros
			echo 'Creando el fichero con los repositorios de GIT'
			for i in {1..30};
			do
				#Crear un fichero properties para guardar usuario, token, rutas y variables de entorno
				curl -s -u $(get_properties 'app.github.user')':'$(get_properties 'app.github.token') -X GET $(get_properties 'app.github.api')'='$i | grep -i full_name | grep -i Cibt- | cut -d'/' -f 2 | sed 's/",//' >> $(get_properties 'app.repositories.filename')
			done
			echo 'Comenzamos la descarga de repositorios de GIT'
		
			#Recorremos el fichero de repositorios comprobando el tipo de servicio para poder filtrarlo
			for i in `cat  $(get_properties 'app.repositories.filename')`
				do
					type=$(echo $i | cut -d'-' -f 2)
					if [[ $i = *$type* ]] ;
					then
						download_repositories $type $i $1
					fi
				done
			rm -rf $(get_properties 'app.repositories.filename')
}

function download_repositories {
	# $1 = Tipo de servicio
	# $2 = nombre del servicio
	# $3 = nombre del branch
	if [ -d $(get_properties 'app.data-path')$1 ];
		then
			cd $1/
			if [ -d $(get_properties 'app.data-path')$1/$2 ];
			then
				echo 'Descargando codigo fuente mas reciente'
				cd $2
				git pull
				cd ..
			else
				echo 'Clonando repositorios de la rama '$3
				git clone $(get_properties 'app.github.address')$i.git -b $3
			fi
			echo "Completado"
			cd ..
	else
		mkdir $(get_properties 'app.data-path')$1
		cd $1
		echo 'Clonando repositorios de la rama '$3
		git clone $(get_properties 'app.github.address')$2.git -b $3
		echo "Completado"
		cd ..
	fi
}



function option_menu {
        cd $(get_properties 'app.data-path')
        echo '¿Que accion desea realizar?'
        options=("Descargar los repositorios" "Reindexar repositorio" "Quit")
        git config --global credential.helper store
        select opt in "${options[@]}"
			do
				case $opt in
                    "Descargar los repositorios")
                        echo "Has elegido $opt"
						choose_branch
                        break
                        ;;
					"Reindexar repositorio")
                        echo "Has elegido $opt"
                        opengrok-indexer -a $(get_properties 'app.opengrok.jar') -- -c $(get_properties 'app.opengrok.ctags') -s $(get_properties 'app.opengrok.src') -d $(get_properties 'app.opengrok.data') -H -P -S -G -W $(get_properties 'app.opengrok.configuration') -U $(get_properties 'app.opengrok.address')
						break
                        ;;
                    "Quit")
                        break
                        ;;
                    *)
                        echo "operacion no permitida $REPLY";;
            esac
        done
}


if [ -d $(get_properties 'app.data-path') ];
then
    option_menu
else
    mkdir -p $(get_properties 'app.data-path')
    option_menu
fi


