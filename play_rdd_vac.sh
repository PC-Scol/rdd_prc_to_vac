#!/bin/bash
#
# Auteurs : j-luc.nizieux@uca.fr
#	     tristan.blanc@uca.fr
#
# SPDX-License-Identifier: AGPL-3.0-or-later
# License-Filename: LICENSE

# -----------------------------------------------------------------------------
# play_rdd_vac.sh: script pour jouer les VAC pour RDD PEGASE
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# FONCTION POUR CATCH LES ERREURS
# -----------------------------------------------------------------------------

exit_if_error() {
  local exit_code=$1
  shift
  [[ $exit_code ]] &&
    ((exit_code != 0)) && {
      printf 'ERROR: %s\n' "$@" >&2
      exit "$exit_code"
                                    
    }
}
# -----------------------------------------------------------------------------
# FONCTION DE MESSAGE D'USAGE
# -----------------------------------------------------------------------------

mess_usage()
{
echo -e "Usage : $0  [-admin] ..."
exit 10
}

#Initialisation log
init_log()
{
echo "  =======================================" >> ${FIC_LOG}
echo "  Log du passage de play_rdd_vac" >> ${FIC_LOG}
echo "  Date d'execution : $(date  -I)" >> ${FIC_LOG}
echo "  Code Année universitaire : ${COD_ANU} " >> ${FIC_LOG}
echo "  Fichier choisi : ${fic_insert}" >> ${FIC_LOG}
echo "  PDB : ${PDB}" >> ${FIC_LOG}
if [ "$TEM_DELETE" = "Y" ];
then
	echo "  Mode : Mode Suppression !!" >> ${FIC_LOG}
else
	echo "  Mode : Mode Insertion !!" >> ${FIC_LOG}

fi
echo "  =======================================" >> ${FIC_LOG}
echo "  Processus d'execution : " >> ${FIC_LOG}
echo "  =======================================" >> ${FIC_LOG}
echo "  " >> ${FIC_LOG}

}


# -----------------------------------------------------------------------------
# MENU CONFIRMATION
# -----------------------------------------------------------------------------
confirm_menu()
{

# -----------------------------------------
# Affichage des parametres
# -----------------------------------------
echo "-------------------------------------------------"
echo "Recapitulatif :"
echo "  >>>   Code Année universitaire : ${COD_ANU} "
echo "  >>>   Fichier choisi : ${fic_insert##*/}"
echo "  >>>   PDB : $PDB	"
echo "  >>>   Identifiant base de donnee : ${LOGIN_APOGEE} "
echo "  >>>   Mot de passe base de donnee : ${MDP_APOGEE} "

if [ "$TEM_DELETE" = "Y" ];
then
	echo "  >>>   En mode Suppression !!"
else
	if [ "$TEM_DELETE" = "N" ];
	then
		echo "  >>>   En mode insertion !!"
	else
	  echo "  >>>    Impossible !!"
	  exit
	fi

fi


	        
echo "-------------------------------------------------"
# -----------------------------------------
# Confirmation
# -----------------------------------------

echo "Continuer ? (Ctrl-c pour annuler) :"
read pocpoc

echo "  >   Debut de l'execution du programme"   
}


# -----------------------------------------------------------------------------
# MENU CHOIX FICHIER
# -----------------------------------------------------------------------------
choix_menu()
{

# -----------------------------------------
# Affichage des parametres
# -----------------------------------------

echo "-------------------------------------------------"
echo " Listes des fichiers disponibles :  "
number=0
for fic in  `ls ${DIR_FIC_SORTIE}/cle_vac*`; do 
 	fichier=${fic##*/}
 	number=$(( ++number ))
       echo "  >>>  ${number} - ${fichier}"  
done
echo "-------------------------------------------------"


# -----------------------------------------
# Confirmation
# -----------------------------------------

read -p "Votre choix ? (1,2,..): " choice

re='^[0-9]+$'
if ! [[ $choice =~ $re ]] ; then
   echo "  >>>   Saisie invalide" >&2; exit 1
fi

}

# -----------------------------------------------------------------------------
# ETAPE 1 : INITIALISATION DE VARIABLES DE TRAVAIL, DE LA LOG ET DES DROITS DE LA LOG
# -----------------------------------------------------------------------------

# -----------------------------------------
# initialisation de variables de travail
# -----------------------------------------


    # nom de base pour les ressources
NOM_BASE=`basename ${0} .sh`


    # dossier pere
DIR_FIC_ARCH=`printenv | grep ^PWD= | cut -d\= -f2`
    # dossier archive
DIR_FIC_SORTIE=${DIR_FIC_ARCH}/fichier_sortie_sql


    #FICHIER INI (chemin à ajouter)
FIC_INI=${DIR_FIC_ARCH}/rdd_vac.ini

    # fichier de log
DIR_FIC_LOG=${DIR_FIC_ARCH}/logs

COD_ANU=`grep "^COD_ANU" $FIC_INI | cut -d\: -f2`

PDB=`printenv | grep ^TWO_TASK= | cut -d\= -f2`


TEM_DELETE=`grep "^TEM_DELETE" $FIC_INI | cut -d\: -f2`


#  Vérification existance du dossier log
if  ! test -d ${DIR_FIC_LOG}
then
	echo "  >>>    Dossier ${DIR_FIC_LOG} non existant"
	exit
fi

# Récupération Identifiant
LOGIN_APOGEE_SAISI=`grep "^LOGIN_APOGEE" $FIC_INI | cut -d\: -f2`
if  [[  -z ${LOGIN_APOGEE_SAISI} ]]
then
echo "-------------------------------------------------"
echo "Vos identifiants et mot de passe :"

	echo -e "Login APOGEE ?  : \c"
	read LOGIN_APOGEE_SAISI
fi
LOGIN_APOGEE=${LOGIN_APOGEE_SAISI}


# Récupération Mot de passe
MDP_APOGEE_SAISI=`grep "^MDP_APOGEE" $FIC_INI | cut -d\: -f2`
if  [[  -z ${MDP_APOGEE_SAISI} ]]
then
	echo -e "Mot de passe APOGEE ?: \c"
	read MDP_APOGEE_SAISI
fi
MDP_APOGEE=${MDP_APOGEE_SAISI}

    # chaine de connexion
STR_CONX=${LOGIN_APOGEE}/${MDP_APOGEE}



if [[  -z ${PDB} ]]
then
	PDB=`grep "^PDB" $FIC_INI | cut -d\: -f2`
	if [[  -z ${PDB} ]]
	then
		echo "Probleme PDB ou TWO_TASK"
		exit
	fi
fi

 # log du programme
BASE_FIC_LOG=${NOM_BASE}

FIC_LOG=${BASE_FIC_LOG}.log
    # Variables du fichier d'environnement
    # Code annee universitaire

GEN_TIMESTAMP=$(date  -I)

number_fic=`ls ${DIR_FIC_LOG} | grep  "${BASE_FIC_LOG}*" | wc -l`
# sequence fic log
if [ $number_fic -ne 0 ];
then
	number_fic=$(( ++number_fic ))
	FIC_LOG=${DIR_FIC_LOG}/log_${BASE_FIC_LOG}_${GEN_TIMESTAMP}_${number_fic}.log

	echo "  >>>   Fichier avec masque ${FIC_LOG} existant"  

else
	FIC_LOG=${DIR_FIC_LOG}/log_${BASE_FIC_LOG}_${GEN_TIMESTAMP}.log
fi

 # Appel du menu
choix_menu

# recuperation du chemin du fichier
number=0
#choix du fichier
for fic in  `ls ${DIR_FIC_SORTIE}/cle_vac*`; do 
	number=$(( ++number ))
	fic_insert=${fic}
	if [ "${number}" -eq " ${choice}" ];
	then
		break
	fi
done


init_log


echo "  >>  Debut Programme " >> ${FIC_LOG}


if [ "${choice}" -gt "$number" ]
then
	echo "  >>>   Impossible nombre fichier trop grand" >&2; exit 1
fi 

# Vérification existance du dossier log
if  ! test -d ${DIR_FIC_SORTIE}
then
	echo "  >>>   Dossier ${DIR_FIC_SORTIE} non existant"
	exit
fi



number_fic=0

# Appel du menu
confirm_menu

if test -f "${DIR_FIC_LOG}/${FIC_LOG}"; then
    rm -f ${DIR_FIC_LOG}/${FIC_LOG}
fi

sleep 1



if [ "$TEM_DELETE" = "N" ];
then

# parcours du fichier
for sql_condition_string in  $(cat <  ${fic_insert}); do 

echo "  >>>  Insertion de la VAC ${sql_condition_string}"

echo "  >>>  Insertion de la VAC ${sql_condition_string}" >> ${FIC_LOG}
echo "  >>>>  Insertion pour la VAC " >> ${FIC_LOG}

#Recupération des Valeurs du fichier cle
ANNEE="$(cut -d';' -f1 <<< ${sql_condition_string})"
COD_IND="$(cut -d';'  -f2 <<< ${sql_condition_string})"
COD_ETP="$(cut -d';'  -f3 <<< ${sql_condition_string})" 
COD_VRS_VET="$(cut -d';'  -f4 <<< ${sql_condition_string})"
COD_ELP="$(cut -d';'  -f5 <<< ${sql_condition_string})" 
DAT_DEC_ELP_VAA="$(cut -d';'  -f6 <<< ${sql_condition_string})"
COD_CIP="$(cut -d';'  -f7 <<< ${sql_condition_string})" 
NOT_VAA="$(cut -d';'  -f8 <<< ${sql_condition_string})"
BAR_NOT_VAA="$(cut -d';'  -f9 <<< ${sql_condition_string})"


#Suppression des VACS dans Apogee
sqlplus -s <<FIN_SQL 
${STR_CONX}
set serveroutput on
SET HEADING OFF
SET FEEDBACK OFF
set pagesize 1
SPOOL ${FIC_LOG} append
VARIABLE ret_code NUMBER
BEGIN
	DECLARE 
		ANNEE varchar2(4) := '${ANNEE}';
		COD_IND number(8,0) := '${COD_IND}';		
		COD_ETP varchar2(6) := '${COD_ETP}';
		COD_VRS_VET number(3,0) := '${COD_VRS_VET}';
		COD_ELP varchar2(20000) := '${COD_ELP}';
		DAT_DEC_ELP_VAA date := sysdate;
		COD_CIP varchar2(20000) := '${COD_CIP}';
		NOT_VAA number(8,3) := NULL;
		BAR_NOT_VAA number(5,0) := NULL;
		COD_DEP_PAY_VAC varchar2(3) := NULL;
		COD_TYP_DEP_PAY_VAC varchar2(20000) := NULL;
		COD_ETB varchar2(20000) := NULL;
		COD_PRG varchar2(20000) := NULL;
		TEM_SNS_PRG varchar2(20000) := NULL;
		LINEBUFFER varchar2(2000) := '';
				
	BEGIN
		IF '${NOT_VAA}' <> 'NULL' THEN
			NOT_VAA :='${NOT_VAA}';
		end if;

		IF '${BAR_NOT_VAA}' <> 'NULL' THEN
			BAR_NOT_VAA :='${BAR_NOT_VAA}';
		END IF;


		execute immediate 
			'INSERT INTO IND_DISPENSE_ELP(COD_ANU,COD_IND,COD_ETP,COD_VRS_VET,COD_ELP,DAT_DEC_ELP_VAA,COD_CIP,NOT_VAA,BAR_NOT_VAA,COD_DEP_PAY_VAC,COD_TYP_DEP_PAY_VAC,COD_ETB,COD_PRG,TEM_SNS_PRG)
			VALUES
			(:b1,:b2,:b3,:b4,:b5,:b6,:b7,:b8,:b9,:b10,:b11,:b12,:b13,:b14)'
			using ANNEE, COD_IND,COD_ETP,COD_VRS_VET,COD_ELP,DAT_DEC_ELP_VAA,COD_CIP,NOT_VAA,BAR_NOT_VAA,COD_DEP_PAY_VAC,COD_TYP_DEP_PAY_VAC,COD_ETB ,COD_PRG,TEM_SNS_PRG;
			commit;

	EXCEPTION
        WHEN OTHERS
		THEN 
			LINEBUFFER := 'Erreur sur ${sql_condition_string}';
			LINEBUFFER := LINEBUFFER ||'-'|| SQLERRM;
			DBMS_OUTPUT.PUT_LINE(LINEBUFFER);	
			ROLLBACK;
	END;
	
END;
/
EXIT
FIN_SQL

	
echo "  >>>> Fin Insertion de la VAC" >> ${FIC_LOG}		

done

sleep 1

echo -e "  >>>   Fin de l'insertion des VACS" >> ${FIC_LOG}	
echo -e "  >>>   Fin de l'insertion des VACS"
fi

if [ "$TEM_DELETE" = "Y" ];then

# parcours du fichier
for sql_condition_string in  $(cat <  ${fic_insert}); do 

echo "  >>>  Suppression de la VAC ${sql_condition_string}"

echo "  >>>  Suppression de la VAC ${sql_condition_string}" >> ${FIC_LOG}
echo "  >>>>   Suppression de la VAC " >> ${FIC_LOG}
ANNEE="$(cut -d';' -f1 <<< ${sql_condition_string})"
COD_IND="$(cut -d';'  -f2 <<< ${sql_condition_string})"
COD_ETP="$(cut -d';'  -f3 <<< ${sql_condition_string})"
COD_VRS_VET="$(cut -d';'  -f4 <<< ${sql_condition_string})"
COD_ELP="$(cut -d';'  -f5 <<< ${sql_condition_string})"



#Suppression des VACS dans Apogee
sqlplus -s <<FIN_SQL 
${STR_CONX}
set serveroutput on
SET HEADING OFF
SET FEEDBACK OFF
set pagesize 1
SPOOL ${FIC_LOG} append
VARIABLE ret_code NUMBER
BEGIN
	DECLARE 
		ANNEE varchar2(4) := '${ANNEE}';
		COD_IND number(8,0) := '${COD_IND}';
		COD_ETP varchar2(6) := '${COD_ETP}';
		COD_VRS_VET number(3,0) := '${COD_VRS_VET}';
		COD_ELP varchar2(20000) := '${COD_ELP}';
		LINEBUFFER varchar2(2000) := '';
	BEGIN
		
					
		execute immediate 
			'DELETE FROM IND_DISPENSE_ELP WHERE COD_ANU = :b1 AND COD_IND = :b2 AND COD_ETP = :b3 AND COD_VRS_VET= :b4 AND COD_ELP = :b5'
			using annee, cod_ind,COD_ETP,COD_VRS_VET,COD_ELP;
			commit;

	EXCEPTION
        WHEN OTHERS
		THEN 
			LINEBUFFER := 'Erreur sur ${sql_condition_string}';
			LINEBUFFER := LINEBUFFER ||'-'|| SQLERRM;
			DBMS_OUTPUT.PUT_LINE(LINEBUFFER);	
			ROLLBACK;
	END;
	
END;
/
EXIT
FIN_SQL

echo "  >>>>   Fin Suppression de la VAC " >> ${FIC_LOG}	


done

fi

echo "  >>>>   Fin Suppression des VAC" 
echo "  >>>>   Fin Suppression des VAC" >> ${FIC_LOG}
# -----------------------------------------
# Fin du programme
# -----------------------------------------
echo "  >   Fin de l'execution du programme" 
echo "  >   Fin de l'execution du programme"  >> ${FIC_LOG}
echo "  =======================================" >> ${FIC_LOG}