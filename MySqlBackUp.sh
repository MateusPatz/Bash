#!/bin/bash

funLogin () {
	char=1
	while [ "$char" = "1" ]
	do
		#informe usuario e senha
		myUser=$( dialog --stdout --title 'User' --inputbox 'Informe o usuario do MySql:' 0 0 )
		#myKey=$( dialog --title "Senha" --stdout --cr-wrap --passwordbox "Digite a senha: " 0 0 ) #SEGURO
		myKey=$( dialog --title "Senha" --stdout --insecure --passwordbox "Digite a senha: " 0 0 ) #inseguro+bonito
		char=$( mysql -u $myUser -p$(echo $myKey) -e "show databases")
		if [[ $char =~ [a-z] ]] ; then
			#echo $char
			#return 0
			char=0
		else
			#echo  $char
			#return 1
			char=1
			dialog --title 'MySQL' --msgbox 'LOGIN INCORRETO!!!' 0 0
		fi
		#mysql -u $myUser -p$(echo $myKey) -e "show databases;"
	done
}

#funLogin
backupFull () {
	dialog --stdout --yesno 'Fazer backup COMPLETO do MySQL??' 0 0
	var=$?
	if [[ "$var" = "0" ]] ; then
		FILE=$(dialog --title "Salvar arquivo:" --stdout --title "Escolha como deseja salvar o arquivo:" --fselect $HOME 14 48)


		mysqldump -u $myUser -p$(echo "$myKey") --all-databases --routines --triggers > $FILE
		#FAZER BACKUP COMPLETO
		dialog --msgbox 'Parabens o backup foi finalizado!' 5 40
#	else
#		dialog --title "MySQL" --msgbox "Obrigado por utilizar o MySQL" 0 0 
		
		fi		
}



backupBase () {
	bancos=$( mysql -u $myUser -p"$( echo $myKey )" -e 'SELECT table_schema "DBName", ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) "DBSizeinMB" FROM information_schema.tables GROUP BY table_schema;' )


	bancos=( $( echo $bancos ) )
	echo ${bancos[@]}

	unset bancos[0]
	unset bancos[1]
	bancos=( $( echo ${bancos[@]} ) )
	i=0
	cont=0
	for h in $( seq $(( ${#bancos[@]}/2 )) ) 
		do
			selectBanco[$cont]="${bancos[$i]}"
			i=$(( $i+1 ))
			selectBanco[$(( $cont+1 ))]="${bancos[$i]}MB"
			i=$(( $i+1 ))
			selectBanco[$(( $cont+2 ))]=$( echo "off" )

			cont=$(( $cont+3 ))
			#echo $cont
		done	
	#echo "---------------"
	#echo "${selectTab[@]}"
	#mostra o visual

	setBancos=$( dialog --stdout --title 'Bancos contidos no MySql:' --checklist 'Selecione bancos de dados que deseja fazer o BackUp:' 0 0 0  $(echo "${selectBanco[@]}" ) )
	FILE=$(dialog --title "Salvar arquivo:" --stdout --title "Escolha como deseja salvar o arquivo de backup:" --fselect $HOME 14 48)

	dialog --stdout --yesno 'Fazer backup com "routines" do MySQL??' 0 0
	var=$?
	if [[ "$var" = "0" ]] ; then
		mysqldump -u $myUser -p$(echo $myKey) --databases ${setBancos[@]} -f -v --add-drop-database --routines  > $FILE 
		dialog --msgbox 'Parabens o backup foi finalizado!' 5 40
	else
		mysqldump -u $myUser -p$(echo $myKey) --databases ${setBancos[@]} -f -v --add-drop-database  > $FILE
		dialog --msgbox 'Parabens o backup foi finalizado!' 5 40
	fi


}

backupTabela () {
	bancos=$( mysql -u $myUser -p"$( echo $myKey )" -e 'SELECT table_schema "DBName", ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) "DBSizeinMB" FROM information_schema.tables GROUP BY table_schema;' )

	bancos=( $( echo $bancos ) )
	echo ${bancos[@]}
	
	unset bancos[0]
	unset bancos[1]
	bancos=( $( echo ${bancos[@]} ) )
	cont=0
	i=0
	for h in $( seq $(( ${#bancos[@]}/2 )) ) 
		do
			selectBanco[$cont]="${bancos[$i]}"
			i=$(( $i+1 ))
			selectBanco[$(( $cont+1 ))]="${bancos[$i]}MB"
			i=$(( $i+1 ))
			#selectBanco[$(( $cont+2 ))]=$( echo "off" )

			cont=$(( $cont+2 ))
			echo $cont
		done	
	echo "---------------"
	echo "${selectTab[@]}"
	#mostra o visual
		setBanco=$( dialog --stdout --title 'Bancos de Dados disponiveis' --menu 'Selecione o banco para ver as tabelas:' 0 0 0 $( echo "${selectBanco[@]}" ) )
	myTabelas=$(mysql -u $myUser -p$( echo $myKey ) -e "SELECT TABLE_NAME, ROUND(((DATA_LENGTH+INDEX_LENGTH)/1024/1024),  1) AS TABLE_SIZE_in_MB FROM information_schema.TABLES WHERE table_schema = '$setBanco';")

	myTabelas=( $( echo $myTabelas ) )
	cont=0
	i=0	
	unset myTabelas[0]
	unset myTabelas[1]
	myTabelas=( $( echo ${myTabelas[@]} ) )
	for x in $( seq $(( ${#myTabelas[@]}/2 )) )
		do
			selectTab[$cont]="${myTabelas[$i]}"
			i=$(( $i+1 ))
			selectTab[$(( $cont+1 ))]="${myTabelas[$i]}MB"
			i=$(( $i+1 ))
			selectTab[$(( $cont+2 ))]=$( echo "off" )
			cont=$(( $cont+3 ))
		done

	setTabelas=$( dialog --stdout --title 'Tabelas contidas no banco $setBanco:' --checklist 'Selecione as tabelas que deseja fazer o BackUp:' 0 0 0 $( echo "${selectTab[@]}" ) )
	echo "${setTabelas[@]}"

	FILE=$(dialog --title "Salvar arquivo:" --stdout --title "Escolha como deseja salvar o arquivo de backup:" --fselect $HOME 14 48)

	dialog --stdout --yesno 'Fazer backup com "routines" do MySQL??' 0 0
	var=$?
	if [[ "$var" = "0" ]] ; then
		mysqldump -u $myUser -p$(echo $myKey)  -f -v --add-drop-table --routines  $setBanco ${setTabelas[@]} > $FILE
		dialog --msgbox 'Parabens o backup foi finalizado!' 5 40
	else
		mysqldump -u $myUser -p$(echo $myKey)  -f -v --add-drop-table $setBanco ${setTabelas[@]} > $FILE
		dialog --msgbox 'Parabens o backup foi finalizado!' 5 40
	fi


}

restoreFull () {
	dialog --stdout --yesno 'Fazer restore COMPLETO do MySQL??' 0 0
	var=$?
	if [[ "$var" = "0" ]] ; then
		FILE=$(dialog --title "Selecione o arquivo:" --stdout --title "escolha o arquivo de backup:" --fselect $HOME 14 48)
		echo "$FILE"

		mysql -u $myUser -p$(echo "$myKey") -f < $FILE

		dialog --msgbox 'Parabens o restore foi finalizado!' 5 40

		fi		
}


restoreBase () {

	FILE=$(dialog --title "Selecione o arquivo de backup:" --stdout --title "Escolha o arquivo de backup:" --fselect $HOME 14 48)
	dialog --stdout --yesno 'Fazer o restore forçado do MySQL??' 0 0
	var=$?
	if [[ "$var" = "0" ]] ; then
		mysql -u $myUser -p$(echo $myKey) -f --databases ${setBancos[@]} < $FILE
		dialog --msgbox 'Parabens o restore foi finalizado!' 5 40
	else
		mysql -u $myUser -p$(echo $myKey) --databases ${setBancos[@]} < $FILE
		dialog --msgbox 'Parabens o restore foi finalizado!' 5 40
	fi


}


restoreTabelas() {

################
bancos=$( mysql -u $myUser -p"$( echo $myKey )" -e 'SELECT table_schema "DBName", ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) "DBSizeinMB" FROM information_schema.tables GROUP BY table_schema;' )
	#transforma saida em array

	bancos=( $( echo $bancos ) )
	echo ${bancos[@]}
	
	unset bancos[0]
	unset bancos[1]
	bancos=( $( echo ${bancos[@]} ) )
	#echo ${bancos[@]}
	#echo ${#bancos[@]}
	#echo "#########"

	#for para organizar os dados 
	cont=0
	i=0
	for h in $( seq $(( ${#bancos[@]}/2 )) ) 
		do
			selectBanco[$cont]="${bancos[$i]}"
			i=$(( $i+1 ))
			selectBanco[$(( $cont+1 ))]="${bancos[$i]}MB"
			i=$(( $i+1 ))
			#selectBanco[$(( $cont+2 ))]=$( echo "off" )

			cont=$(( $cont+2 ))
			echo $cont
		done	
	echo "---------------"
	echo "${selectTab[@]}"
	#mostra o visual
		setBanco=$( dialog --stdout --title 'Bancos de Dados disponiveis' --menu 'Selecione o banco para restaurar as tabelas:' 0 0 0 $( echo "${selectBanco[@]}" ) )

#############
	FILE=$(dialog --title "Selecione o arquivo de backup:" --stdout --title "Escolha o arquivo de backup:" --fselect $HOME 14 48)

	dialog --stdout --yesno 'Fazer o restore forçado do MySQL??' 0 0
	var=$?
	if [[ "$var" = "0" ]] ; then
		mysql -u $myUser -p$(echo $myKey) -f $setBanco < $FILE
		dialog --msgbox 'Parabens o restore foi finalizado!' 5 40
	else
		mysql -u $myUser -p$(echo $myKey) $setBanco < $FILE
		dialog --msgbox 'Parabens o restore foi finalizado!' 5 40
	fi

}





#ADICIONAR CODIGO DE FUNÇOES
#source funcao

#menu
	menuOpc=$( dialog --stdout --title 'MySQL - Gerenciador de BackUp' --menu 'Selecione uma opcao:' 0 0 0 1 'Gerar BackUp' 2 'Restaurar BackUp' )


	case $menuOpc in
		1)
			subMenu=$( dialog --stdout --title 'MySQL - Gerenciador de BackUp' --menu 'selecione uma opcao:' 0 0 0 1 'Gerar BackUp completo do MySQL' 2 'Gerar BackUp completo de bancos' 3 '***Gerar BackUp de tabelas***' )
			;;
		2)
			subMenu=$( dialog --stdout --title 'MySQL - Gerenciador de BackUp' --menu 'selecione uma opcao:' 0 0 0 1 'Restaurar BackUp completo do MySQL' 2 'Restaurar BackUp completo de bancos' 3 '***Restaurar BackUp de tabelas***' )
	esac
menuOpc="$menuOpc$subMenu"

funLogin

	case $menuOpc in
		11)
			backupFull
		;;
		12)
			backupBase
		;;
		13)
			backupTabela
		;;
		21)
			restoreFull
		;;
		22)
			restoreBase
		;;
		23)
			restoreTabelas
	esac

