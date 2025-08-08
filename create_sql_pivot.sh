#!/bin/bash
#
# Auteurs : j-luc.nizieux@uca.fr
#	     tristan.blanc@uca.fr
#
# SPDX-License-Identifier: AGPL-3.0-or-later
# License-Filename: LICENSE

# ---------------------------------------------------------------------------------------------------------------------
# create_sql_pivot.sh: script de génération des vacs pour les inserer en base pivot
# ---------------------------------------------------------------------------------------------------------------------


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

init_log()
{
echo "  =======================================" >> ${FIC_LOG}
echo "  Log du passage de create_pivot_sql" >> ${FIC_LOG}
echo "  Date d'execution : $(date  -I)" >> ${FIC_LOG}
echo "  Code Annee universitaire : ${COD_ANU}" >> ${FIC_LOG}
echo "  Type Detection : ${COD_TYP_DETECT}" >> ${FIC_LOG}
echo "  Code Objet : ${COD_OBJ}" >> ${FIC_LOG}
echo "  Code Version Objet : ${COD_VRS_OBJ}" >> ${FIC_LOG}
echo "  Transformation des conservations en capitalisations : ${TRANSFORMATION_CONSERVATION_CAPITALISATION}" >> ${FIC_LOG}
echo "  Dossier racine : ${DIR_FIC_ARCH}" >> ${FIC_LOG}
echo "  PDB : $PDB" >> ${PDB}
echo "  Fichier choisi Cle: ${fic_insert##*/}"
echo "  Fichier choisi Filtre formation: ${fic_vet##*/}"
echo "  PDB : $PDB	"
echo "  Activation prefix : ${PREFIXON} "
echo "  Prefix VDI : ${PREFIX_VDI} "
echo "  Prefix VET : ${PREFIX_VET} "
echo "  Code établissement : ${COD_ETB} "
echo "  Nombre de Thread: ${NBTHR}"
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
echo "  >>>   Fichier choisi Cle: ${fic_insert##*/}"
echo "  >>>   Fichier choisi Filtre formation: ${fic_vet##*/}"
echo "  >>>   PDB : $PDB	"
echo "  >>>   Identifiant base de donnee : ${LOGIN_APOGEE} "
echo "  >>>   Mot de passe base de donnee : ${MDP_APOGEE} "
echo "  >>>   Activation prefix : ${PREFIXON} "
echo "  >>>   Prefix VDI : ${PREFIX_VDI} "
echo "  >>>   Prefix VET : ${PREFIX_VET} "
echo "  >>>   Code établissement : ${COD_ETB} "
echo "  >>>   Nombre de Thread: ${NBTHR} "
echo "  >>>   En mode génération des VAC d'insertion !!"


if [ ! "${COD_ANU}" ] || [ ! "${COD_ETB}" ]  || [ ! "${MDP_APOGEE}" ] || [ ! "${LOGIN_APOGEE}" ] ;then
	echo "  >>> Probleme paramètre"
	exit
fi

if [ ! "${NBTHR}" ] ;then
	echo "  >>> Probleme paramètre NBTHR non-renseigné"
	exit
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
echo " Listes des fichiers de données disponibles :  "
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


choix_menu_vet()
{

# -----------------------------------------
# Affichage des parametres
# -----------------------------------------

echo "-------------------------------------------------"
echo " Listes des fichiers de filtre des VET disponibles :  "
number2=0
for fic in  `ls ${DIR_FIC_ARCHIVE}/vets_*`; do
	fichier=${fic##*/}
	number2=$(( ++number2))
	echo "  >>>  ${number2} - ${fichier}"
done
echo "-------------------------------------------------"


# -----------------------------------------
# Confirmation
# -----------------------------------------

read -p "Votre choix ? (1,2,..): " choice_vet

re='^[0-9]+$'
if ! [[ $choice_vet =~ $re ]] ; then
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
DIR_FIC_ARCHIVE=${DIR_FIC_ARCH}/archives/filtre_sortie


    #FICHIER INI (chemin à ajouter)
FIC_INI=${DIR_FIC_ARCH}/rdd_vac.ini

# Récupération Identifiant
LOGIN_APOGEE_SAISI=`grep "^LOGIN_APOGEE" $FIC_INI | cut -d\: -f2`
if  [[  -z ${LOGIN_APOGEE_SAISI} ]]
then
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

    # fichier de log
DIR_FIC_LOG=${DIR_FIC_ARCH}/logs

	#variable environnement
COD_ANU=`grep "^COD_ANU" $FIC_INI | cut -d\: -f2`
PREFIXON=`grep "^PREFIXON" $FIC_INI | cut -d\: -f2`
PREFIX_VET=`grep "^PREFIX_VET" $FIC_INI | cut -d\: -f2`
PREFIX_VDI=`grep "^PREFIX_VDI" $FIC_INI | cut -d\: -f2`

PDB=`printenv | grep ^TWO_TASK= | cut -d\= -f2`

COD_ETB=`grep "^COD_ETB" $FIC_INI | cut -d\: -f2`

NBTHR=`grep "^NB_THREAD" $FIC_INI | cut -d\: -f2`

#  Vérification existance du dossier log
if  ! test -d ${DIR_FIC_LOG}
then
	echo "  >>>    Dossier ${DIR_FIC_LOG} non existant"
	exit
fi

#  Vérification existance du dossier log
if  [[ -z ${LOGIN_APOGEE} ]]
then
	echo "  >>>    Login non existant"
	exit
fi

if  [[  -z ${MDP_APOGEE} ]]
then
	echo "  >>>   Mot de passe non existant"
	exit
fi


PDB=`grep "^PDB" $FIC_INI | cut -d\: -f2`
if [[  -z ${PDB} ]]
then
	PDB=`printenv | grep ^TWO_TASK= | cut -d\= -f2`
fi
if [[  -z ${PDB} ]]
then
echo "Probleme PDB ou TWO_TASK non positionnés"
	exit
fi
export TWO_TASK=${PDB}


# log du programme
BASE_FIC_LOG=${NOM_BASE}

FIC_LOG=${DIR_FIC_LOG}/${BASE_FIC_LOG}.log
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
choix_menu_vet


init_log

echo "  >   Debut programme"
echo "  >   Debut programme" >> ${FIC_LOG}

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

# Vérification existance du dossier log
if  ! test -d ${DIR_FIC_ARCHIVE}
then
	echo "  >>>   Dossier ${DIR_FIC_ARCHIVE} non existant"
	exit
fi


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

#choix du fichier de vet à tester
number2=0
for fic in  `ls ${DIR_FIC_ARCHIVE}/vets_*`; do
	number2=$(( ++number2 ))
	fic_vet=${fic}
	DIR_FIC_ARCHIVE=${fic}
	if [ "${number2}" -eq " ${choice_vet}" ];
	then
		break
	fi
done



#echo "BASE_FIC_LOG : ${FIC_LOG}"
#echo "fic_insert : ${fic_insert}"
#echo "fic_vet : ${DIR_FIC_ARCHIVE}"
GEN_TIMESTAMP=$(date  +%s)

    # Fichier de stockage SQL pour requete generation de VAC dans APOGEE
FIC_NAME_PIVOT_INSERT_CHC=insert_CHC_vac_pivot_${COD_ANU}_${GEN_TIMESTAMP}.csv
FIC_NAME_PIVOT_INSERT_COC=insert_COC_vac_pivot_${COD_ANU}_${GEN_TIMESTAMP}.csv
FIC_NAME_PIVOT_DELETE=delete_vac_pivot_${COD_ANU}_${GEN_TIMESTAMP}.sql


# Appel du menu
confirm_menu


sleep 1

test_filtre_formation()
{
 COD_ETP=$1
 COD_VRS_VET=$2
 FIC=$3
 FILTRE_FORMATION=`grep ">$COD_ETP-$COD_VRS_VET" $FIC `
 echo $FILTRE_FORMATION
}

process_coc() {
local ligne=$1
local str_conx=$2

sql_condition_string=${ligne}
echo "test: ${sql_condition_string}"
if [  -z ${sql_condition_string} ]
then
	exit
fi

echo "  >>>  Genération de la VAC d'insertion (coc) pour le pivot :  ${sql_condition_string}"

echo "  >>>  Genération de la VAC pour module COC d'insertion  pour le pivot :${sql_condition_string}" >> $FIC_LOG

#recuperation des valeurs dans les clés

IFS=';' read ANNEE COD_IND COD_ETP COD_VRS_VET COD_ELP DAT_DEC_ELP_VAA COD_CIP NOT_VAA BAR_NOT_VAA <<< "$sql_condition_string"

FILTRE_FORMATION="test_filtre_formation"
result=$(${FILTRE_FORMATION} "$COD_ETP" "$COD_VRS_VET" "$DIR_FIC_ARCHIVE")
echo "  >>>  Filtre formation trouve (coc) dans le fichier archive pour  ${sql_condition_string} : ${result}"
echo "  >>>  Filtre formation trouve (coc) dans le fichier archive pour ${sql_condition_string} : ${result}"  >> ${FIC_LOG}
IFS='>' read -r part1 part2 <<< "${result}"
IFS='-' read -r COD_DIP_FILTRE COD_VRS_VDI_FILTRE <<< "${part1}"

COD_ELP=$(echo "${COD_ELP}" | sed "s/'/''/g")
sqlplus -s <<FIN_SQL
${str_conx}
set serveroutput on
SET HEADING OFF
SET FEEDBACK OFF
SET TRIMSPOOL ON
set linesize 870
set pagesize 1
SPOOL ${DIR_FIC_SORTIE}/${FIC_NAME_PIVOT_INSERT_COC} append
DECLARE
	ANNEE_VAL varchar2(4) := '${ANNEE}';
	COD_IND_VAL number(8,0) := '${COD_IND}';
	COD_ETU_VAL number(8,0) := null;
	COD_ETP_VAL varchar2(6) := '${COD_ETP}';
	COD_VRS_VET_VAL number(3,0) := '${COD_VRS_VET}';
	COD_ELP_VAL varchar2(10) := '${COD_ELP}';
	COD_ETB_VAL varchar2(10) := '${COD_ETB}';
	COD_DIP_VAL varchar2(10) :=	NULL;
	COD_VRS_VDI_VAL varchar2(10) := NULL;
	COD_NEL_VAL varchar2(10) := NULL;
	NOT_VAA_VAL varchar2(10) := '${NOT_VAA}';
	BAR_NOT_VAA_VAL varchar2(10) := '${BAR_NOT_VAA}';
	COD_DEP_PAY_VAC varchar2(10) := NULL;
	COD_TYP_DEP_PAY_VAC varchar2(10) := NULL;
	COD_ETB varchar2(10) := NULL;
	COD_PRG varchar2(10) := NULL;
	NUM_SESSION  varchar2(2) := NULL;
	TEM_SNS_PRG varchar2(10) := NULL;
	PREFIXON_VAC varchar2(10) := '${PREFIXON}';
	PREFIX_VET_VAC varchar2(10) := '${PREFIX_VET}';
	PREFIX_VDI_VAC varchar2(10) := '${PREFIX_VDI}';
	LINEBUFFER varchar2(870) := '';
	CLE_CHC varchar2(50) := '';
	CLE_COC varchar2(100) := '';
	code_filtre_formation varchar2(50) := '';
	tem_capitalise varchar2(2) := null;
	tem_conservation varchar2(2) := null;
	duree_conservation number(8,0)  := null;
	note_minimale_conservation number(8,0)  := null;
	resultat_session1  varchar2(4)  := null;
	resultat_session2  varchar2(4) := null;
	note_session2 varchar2(10) := null;
	bareme_session2 varchar2(10) := null;
	COD_DIP_FILTRE_FILTRE_FORMATION varchar2(10) := '${COD_DIP_FILTRE}';
	COD_VRS_VDI_FILTRE_FORMATION varchar2(10) := '${COD_VRS_VDI_FILTRE}';

BEGIN

	-- une ligne est ajoutée dans apprenant_coc si et seulement si une note est renseignée
	IF NOT_VAA_VAL IS NOT NULL THEN
	
		--Récupération des valeurs pour créer les clés et les ordres SQL
		SELECT cod_dip, cod_vrs_vdi, cod_etu
		INTO COD_DIP_VAL, COD_VRS_VDI_VAL, COD_ETU_VAL
		FROM (
			SELECT iae.cod_dip, iae.cod_vrs_vdi, ind.cod_etu
			FROM ins_adm_etp iae,
				individu ind
			where iae.cod_etp = COD_ETP_VAL
				and iae.cod_vrs_vet = COD_VRS_VET_VAL
				and iae.cod_anu = ANNEE_VAL
				and iae.cod_ind = COD_IND_VAL
				and iae.cod_ind=ind.cod_ind
			)
			WHERE ROWNUM = 1;

		IF
		COD_DIP_VAL <> COD_DIP_FILTRE_FILTRE_FORMATION
		OR
		COD_VRS_VDI_FILTRE_FORMATION <>  COD_VRS_VDI_VAL
		THEN
			RAISE_APPLICATION_ERROR(-20001, 'VDI ou version différente du filtre formation!');
		END IF;

		SELECT cod_nel
		INTO COD_NEL_VAL
		FROM (
			SELECT cod_nel
			from element_pedagogi
			where cod_elp = COD_ELP_VAL
		)
		WHERE ROWNUM = 1;
		
		Select max(cod_ses)
			into NUM_SESSION
			from resultat_elp
			where COD_ADM = 1
			and cod_elp = COD_ELP_VAL
			and COD_IND = COD_IND_VAL;
		
		Select elp.tem_cap_elp, elp.tem_con_elp, elp.dur_con_elp, elp.not_min_con_elp
			into tem_capitalise, tem_conservation, duree_conservation, note_minimale_conservation
			from ELEMENT_PEDAGOGI elp
			where cod_elp = COD_ELP_VAL;
		
		Select max(CASE WHEN relp.cod_ses='1' AND relp.COD_TRE IS NOT NULL AND relp.COD_TRE NOT IN ('ABI','ABJ') THEN relp.COD_TRE
						WHEN relp.cod_ses='1' AND relp.NOT_SUB_ELP IS NOT NULL AND relp.NOT_SUB_ELP NOT IN ('ABI','ABJ') THEN relp.NOT_SUB_ELP
				END)
		into resultat_session1
		from resultat_elp relp
		where   cod_elp = COD_ELP_VAL
			and COD_IND = COD_IND_VAL
			and cod_ses = '1'
			and cod_adm = '1';

		Select max(CASE WHEN relp.cod_ses='2' AND relp.COD_TRE IS NOT NULL AND relp.COD_TRE NOT IN ('ABI','ABJ') THEN relp.COD_TRE
			WHEN relp.cod_ses='2' AND relp.NOT_SUB_ELP IS NOT NULL AND relp.NOT_SUB_ELP NOT IN ('ABI','ABJ') THEN relp.NOT_SUB_ELP
				END)
		into resultat_session2
		from resultat_elp relp
		where  cod_elp = COD_ELP_VAL
			and COD_IND = COD_IND_VAL
			and cod_ses = '2'
			and cod_adm = '1';
		Begin
			Select not_elp
			into note_session2
			from resultat_elp relp
			where  cod_elp = COD_ELP_VAL
			and COD_IND = COD_IND_VAL
			and cod_ses = '2'
			and cod_adm = '1';

			Select bar_not_elp
			into bareme_session2
			from resultat_elp relp
			where  cod_elp = COD_ELP_VAL
			and COD_IND = COD_IND_VAL
			and cod_ses = '2'
			and cod_adm = '1';
		exception
			when others
				then
				bareme_session2  := 'NULL';
				note_session2 := 'NULL';
		end;


		CLE_COC  := COD_IND_VAL || '-'||ANNEE_VAL || '-'|| COD_DIP_VAL ||'-'||COD_VRS_VDI_VAL||'-'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL ||'-ELP-'|| COD_ELP_VAL;
		code_filtre_formation := COD_DIP_VAL||'-'|| COD_VRS_VDI_VAL;

		-- Création de la clé pour les COC et le filtre formation en fonction du préfixage
		IF PREFIXON_VAC = 'Y'
		THEN
			CLE_COC  := COD_IND_VAL || '-'||ANNEE_VAL || '-'||PREFIX_VDI_VAC||'-'|| COD_DIP_VAL ||'-'||COD_VRS_VDI_VAL ||'-'||PREFIX_VET_VAC||'-'||PREFIX_VET_VAC||'-'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL ||'-ELP-'|| COD_ELP_VAL;
			code_filtre_formation := PREFIX_VET_VAC||'-'||COD_ETP_VAL||'-'|| COD_VRS_VET_VAL;
		END IF;

		--  Création de l'ordre d'insertion des coc en fonction des PRC trouvées dans APOGEE
		LINEBUFFER := LINEBUFFER || CLE_COC||';';
		LINEBUFFER := LINEBUFFER || code_filtre_formation||';';
		LINEBUFFER := LINEBUFFER || COD_ELP_VAL||';';
		LINEBUFFER := LINEBUFFER || COD_DIP_VAL||'-' || COD_VRS_VDI_VAL||'>' || COD_ETP_VAL||'-' || COD_VRS_VET_VAL||';';
		LINEBUFFER := LINEBUFFER || ANNEE_VAL||';';
		LINEBUFFER := LINEBUFFER || COD_ETB_VAL||';';
		LINEBUFFER := LINEBUFFER || COD_IND_VAL||';';
		LINEBUFFER := LINEBUFFER || COD_ETU_VAL||';';
		LINEBUFFER := LINEBUFFER || COD_NEL_VAL||';';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER ||	nvl(NOT_VAA_VAL,'NULL')||';';
		LINEBUFFER := LINEBUFFER || nvl(BAR_NOT_VAA_VAL,'NULL')||';';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || nvl(NOT_VAA_VAL,'NULL')||';';
		LINEBUFFER := LINEBUFFER || nvl(BAR_NOT_VAA_VAL,'NULL')||';';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		IF NUM_SESSION = 2
		then
			LINEBUFFER := LINEBUFFER || nvl(NOT_VAA_VAL,'NULL')||';';
			LINEBUFFER := LINEBUFFER ||nvl(BAR_NOT_VAA_VAL,'NULL')||';';
		else
			LINEBUFFER := LINEBUFFER || 'NULL;';
			LINEBUFFER := LINEBUFFER || 'NULL;';

		end if;
		LINEBUFFER := LINEBUFFER || 'NULL;';
		IF  resultat_session2 is not null
			then
				LINEBUFFER := LINEBUFFER || resultat_session2 ||';';
			else
				IF  resultat_session1 is not null
				then
					LINEBUFFER := LINEBUFFER || resultat_session1 ||';';
				else
					LINEBUFFER := LINEBUFFER || 'NULL;';
				end if;

		end if;

		IF  resultat_session1 is not null
		then
			LINEBUFFER := LINEBUFFER || resultat_session1 ||';';
		else
			LINEBUFFER := LINEBUFFER || 'NULL;';
		end if;

		IF  resultat_session2 is not null
		then
			LINEBUFFER := LINEBUFFER || resultat_session2 ||';';
		else
			LINEBUFFER := LINEBUFFER || 'NULL;';
		end if;
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'T;';
		LINEBUFFER := LINEBUFFER || 'T;';
		IF NUM_SESSION = 2
		then
			LINEBUFFER := LINEBUFFER || '2;';
		else
			LINEBUFFER := LINEBUFFER || '1;';
		end if;
		
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';

		IF NUM_SESSION = 2
		then
			LINEBUFFER := LINEBUFFER || 'O;';
		else
			LINEBUFFER := LINEBUFFER || 'N;';
		end if;
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || tem_capitalise||';';
		LINEBUFFER := LINEBUFFER || tem_conservation||';';
		if duree_conservation is not null
		then
			LINEBUFFER := LINEBUFFER || duree_conservation||';';
		else
			LINEBUFFER := LINEBUFFER || 'NULL;';
		end if;
		if note_minimale_conservation is not null
		then
			LINEBUFFER := LINEBUFFER || note_minimale_conservation||';';
		else
			LINEBUFFER := LINEBUFFER || 'NULL;';
		end if;
		LINEBUFFER := LINEBUFFER || 'NULL';

		dbms_output.put_line(LINEBUFFER);
	-- Fin SI note renseignée
	END IF;
EXCEPTION
	WHEN OTHERS
	THEN
		ROLLBACK;
END;
/
SPOOL OFF

EXIT
FIN_SQL

}

echo "  >> Debut Generation COC"
echo "  >> Debut Generation COC" >> $FIC_LOG

# Number of threads
num_threads=${NBTHR}

# parcours du fichier
start=`date +%s`
mapfile -t lines <  $fic_insert

array_length=${#lines[@]}
number_item=$((${array_length}/${num_threads}))
items_per_packet=$(printf "%.0f" "$number_item")



for ((i=0; i<${#lines[@]}; i+=$items_per_packet)); do
    
    packet=("${lines[@]:$i:$items_per_packet}")

    
    (
        for item in "${packet[@]}"; do
            process_coc "${item}" "${STR_CONX}"
		done
    ) & 
    pids+=($!)  # Store the process ID
    
    if [[ ${#pids[@]} -eq $num_threads ]]; then
        wait -n
        pids=("${pids[@]/$!/}")  
    fi

done


for pid in ${pids[*]}; do
    wait $pid
done

end=`date +%s`
runtime=$((end-start))
echo "  >> Fin Generation COC"
echo "  >> Fin Generation COC" >> $FIC_LOG

sleep 1

start_2=`date +%s`

process_chc() {
local ligne=$1
local str_conx=$2

sql_condition_string=${ligne}

if [  -z ${sql_condition_string} ]
then
	exit
fi

echo "  >>>  Genération de la VAC d'insertion (chc) pour le pivot :  ${sql_condition_string}"

echo "  >>>  Genération de la VAC pour module CHC d'insertion  pour le pivot :${sql_condition_string}" >> $FIC_LOG

#recuperation des valeurs dans les clés
IFS=';' read ANNEE COD_IND COD_ETP COD_VRS_VET COD_ELP DAT_DEC_ELP_VAA COD_CIP NOT_VAA BAR_NOT_VAA <<< "$sql_condition_string"


FILTRE_FORMATION="test_filtre_formation"
result=$(${FILTRE_FORMATION} "$COD_ETP" "$COD_VRS_VET" "$DIR_FIC_ARCHIVE")
echo "  >>>  Filtre formation pour (chc) trouve dans le fichier archive pour  ${sql_condition_string} : ${result}"
echo "  >>>  Filtre formation pour (chc) trouve dans le fichier archive pour  ${sql_condition_string}  : ${result}" >> ${FIC_LOG}
IFS='>' read -r part1 part2 <<< "${result}"
IFS='-' read -r COD_DIP_FILTRE COD_VRS_VDI_FILTRE <<< "${part1}"

COD_ELP=$(echo "${COD_ELP}" | sed "s/'/''/g")
sqlplus -s <<FIN_SQL
${STR_CONX}
set serveroutput on
SET HEADING OFF
SET FEEDBACK OFF
SET TRIMSPOOL ON
set linesize 4000
set pagesize 1
SPOOL ${DIR_FIC_SORTIE}/${FIC_NAME_PIVOT_INSERT_CHC} append
DECLARE
	ANNEE_VAL varchar2(4) := '${ANNEE}';
	COD_IND_VAL		number(8,0) := '${COD_IND}';
	COD_ETU_VAL		number(8,0) := null;
	COD_ETP_VAL		varchar2(6) := '${COD_ETP}';
	COD_VRS_VET_VAL	number(3,0) := '${COD_VRS_VET}';
	COD_ELP_VAL		varchar2(10) := '${COD_ELP}';
	COD_ETB_VAL		varchar2(10) := '${COD_ETB}';
	COD_DIP_VAL		varchar2(10) :=	NULL;
	COD_VRS_VDI_VAL	varchar2(10) := NULL;
	CREDIT_VAL		number(8,0) := null;
	COD_NEL_VAL		varchar2(10) := NULL;
	NOT_VAA_VAL		varchar2(10) := '${NOT_VAA}';
	BAR_NOT_VAA_VAL	varchar2(10) := '${BAR_NOT_VAA}';
	COD_DEP_PAY_VAC	varchar2(3) := NULL;
	COD_TYP_DEP_PAY_VAC varchar2(10) := NULL;
	COD_ETB			varchar2(10) := NULL;
	COD_PRG			varchar2(10) := NULL;
	TEM_SNS_PRG		varchar2(10) := NULL;
	PREFIXON_VAC	varchar2(10) := '${PREFIXON}';
	PREFIX_VET_VAC	varchar2(10) := '${PREFIX_VET}';
	PREFIX_VDI_VAC	varchar2(10) := '${PREFIX_VDI}';
	LINEBUFFER		varchar2(4000) := '';
	CLE_CHC			varchar2(50) := '';
	code_filtre_formation varchar2(25) := '';
	chemin_element	varchar2(5000) := '';
	count_elp		number(8,0) := 0;
	first_elp		varchar2(10) := 0;
	isExists		number(8,0) := 0;
	COD_ANU_out		varchar2(10) := null;
	cod_typ_lse_out	varchar2(2) := null;
	cod_ind_out		varchar2(10) := null;
	type_amenagement	varchar2(10) := '';
	COD_DIP_FILTRE_FILTRE_FORMATION varchar2(10) := '${COD_DIP_FILTRE}';
	COD_VRS_VDI_FILTRE_FORMATION varchar2(10) := '${COD_VRS_VDI_FILTRE}';
	
	-- curseur de creation du chemin
	cursor create_chemin_cur
	is
		SELECT  DISTINCT  replace(SYS_CONNECT_BY_PATH(DECODE(lse.cod_typ_lse,'O','','L-'||ice.cod_lse||'>')||ice.cod_elp, '>>'),'>>','>') AS CHEMIN
					,ice.cod_elp AS cod_elp_fils
					,connect_by_root(ice.cod_anu) AS COD_ANU,
					lse.cod_typ_lse,
					ice.cod_ind
			FROM IND_CONTRAT_ELP ice
					,LISTE_ELP lse
			WHERE lse.cod_lse=ice.cod_lse
			CONNECT BY PRIOR ice.cod_elp = ice.cod_elp_sup
					AND PRIOR ice.cod_anu = ice.cod_anu
					AND PRIOR ice.cod_etp=ice.cod_etp
					AND PRIOR ice.cod_vrs_vet=ice.cod_vrs_vet
					AND PRIOR ice.cod_ind=ice.cod_ind
			START WITH 	ice.cod_anu= ANNEE_VAL
					AND ice.cod_ind = COD_IND_VAL
					AND ice.cod_etp = COD_ETP_VAL
					AND ice.cod_vrs_vet = COD_VRS_VET
					AND ice.cod_elp_sup IS NULL;
	chemin varchar2(2000);
	cod_elp_fils_chemin varchar2(10);
	cod_ind_cursor varchar2(10);
	tem_prc_ice varchar2(1);

BEGIN
	--Récupération des valeurs pour créer les clés et les ordres SQL
	SELECT cod_dip, cod_vrs_vdi, cod_etu
	INTO COD_DIP_VAL, COD_VRS_VDI_VAL, COD_ETU_VAL
	FROM (
		SELECT iae.cod_dip, iae.cod_vrs_vdi, ind.cod_etu
		FROM ins_adm_etp iae,
			individu ind
		where iae.cod_etp = COD_ETP_VAL
			and iae.cod_vrs_vet = COD_VRS_VET_VAL
			and iae.cod_anu = ANNEE_VAL
			and iae.cod_ind = COD_IND_VAL
			and iae.cod_ind=ind.cod_ind
		)
		WHERE ROWNUM = 1;

	IF
	COD_DIP_VAL <> COD_DIP_FILTRE_FILTRE_FORMATION
	OR
	COD_VRS_VDI_FILTRE_FORMATION <>  COD_VRS_VDI_VAL
	THEN
		RAISE_APPLICATION_ERROR(-20001, 'VDI ou version diffèrente du filtre formation!');
	END IF;


	SELECT cod_nel
	INTO COD_NEL_VAL
	FROM (
		SELECT cod_nel
		from element_pedagogi
		where cod_elp = COD_ELP_VAL
	)
	WHERE ROWNUM = 1;

	chemin_element  := COD_DIP_VAL ||'-'||COD_VRS_VDI_VAL||'>'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL;
	IF PREFIXON_VAC = 'Y'
	THEN
		chemin_element := PREFIX_VDI_VAC||'-'|| COD_DIP_VAL ||'-'||COD_VRS_VDI_VAL ||'>'||PREFIX_VET_VAC||'-'|| COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL;
	END IF;

	count_elp := 0;
	open create_chemin_cur;
	LOOP
	fetch create_chemin_cur into chemin, cod_elp_fils_chemin,COD_ANU_out ,cod_typ_lse_out,cod_ind_out  ;
		EXIT WHEN  create_chemin_cur%NOTFOUND;

		IF cod_elp_fils_chemin = COD_ELP_VAL and count_elp < 1
		THEN
			chemin_element := chemin_element ||''||chemin;
			count_elp := count_elp + 1;
		END IF;
	END LOOP;
	close create_chemin_cur;

	-- generation des clés
	CLE_CHC  := COD_IND_VAL || '-'|| ANNEE_VAL ||'-'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL||'-'|| COD_ELP_VAL;
	code_filtre_formation := COD_DIP_VAL ||'-'|| COD_VRS_VDI_VAL||'>'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL;

	-- generation du SQL
	LINEBUFFER := '' || CLE_CHC||';';
	LINEBUFFER := LINEBUFFER || '' || ANNEE_VAL||';';
	LINEBUFFER := LINEBUFFER || '' || COD_IND_VAL||';';
	LINEBUFFER := LINEBUFFER || '' || COD_ETU_VAL||';';
	LINEBUFFER := LINEBUFFER || '' || COD_DIP_VAL||'-' || COD_VRS_VDI_VAL||'>' || COD_ETP_VAL||'-' || COD_VRS_VET_VAL||';';	
	LINEBUFFER := LINEBUFFER || '' || COD_ELP_VAL||';';
	LINEBUFFER := LINEBUFFER || '' || chemin_element||';';
	LINEBUFFER := LINEBUFFER || 'NULL;';
	LINEBUFFER := LINEBUFFER || '' || COD_ETB_VAL||';';
	LINEBUFFER := LINEBUFFER || 'N;';
	LINEBUFFER := LINEBUFFER || 'NULL;';
	LINEBUFFER := LINEBUFFER || 'NULL;';
	LINEBUFFER := LINEBUFFER || 'O;';
	LINEBUFFER := LINEBUFFER || 'N;';
	LINEBUFFER := LINEBUFFER || 'NULL;';
	LINEBUFFER := LINEBUFFER || 'NULL;';
	LINEBUFFER := LINEBUFFER || 'AM;';
	-- choix du type d'aménagement :
	--	- présence de note => EVAL
	--	- pas de note => DISPENSE
	IF NOT_VAA_VAL IS NOT NULL THEN
		type_amenagement := 'EVAL';
	ELSE
		type_amenagement := 'DISPENSE';
	END IF;
	LINEBUFFER := LINEBUFFER || type_amenagement||';';
	LINEBUFFER := LINEBUFFER || 'false';

	dbms_output.put_line(LINEBUFFER);

EXCEPTION
	WHEN OTHERS
	THEN
		-- ne pas tracer l'exclusion d'une ligne dans le CSV, sinon CSV inexploitable
		IF SQLCODE=-20001 THEN
			NULL;
		ELSE
			dbms_output.put_line(SQLERRM);
		END IF;
END;
/
SPOOL OFF
EXIT
FIN_SQL
}

echo "  >> Debut Generation CHC"
echo "  >> Debut Generation CHC" >> $FIC_LOG

for ((i=0; i<${#lines[@]}; i+=$items_per_packet)); do

    packet=("${lines[@]:$i:$items_per_packet}")


    (
        for item in "${packet[@]}"; do
            process_chc "${item}" "${STR_CONX}"
		done
    )  &
    pids+=($!)

    if [[ ${#pids[@]} -eq $num_threads ]]; then
        wait -n
        pids=("${pids[@]/$!/}")
    fi

done


for pid in ${pids[*]}; do
    wait $pid
done

sleep 1

end_2=`date +%s`
runtime_2=$((end_2-start_2))
echo "  >> Fin Generation CHC"
echo "  >> Fin Generation CHC" >> $FIC_LOG

sleep 1

#ajout ligne entête
#fichier COC
sed -i '1s/^/"id";"code_formation";"code_objet_formation";"code_filtre_formation";"code_periode";"code_structure";"id_apprenant";"code_apprenant";"type_objet_formation";"code_mention";"grade_ects";"gpa";"note_retenue";"bareme_note_retenue";"point_jury_retenu";"note_session1";"bareme_note_session1";"point_jury_session1";"credit_ects_session1";"rang_session1";"note_session2";"bareme_note_session2";"point_jury_session2";"resultat_final";"resultat_session1";"resultat_session2";"rang_final";"credit_ects_final";"statut_deliberation_session1";"statut_deliberation_session2_final";"session_retenue";"absence_finale";"absence_session1";"absence_session2";"temoin_concerne_session2";"statut_publication_session1";"statut_publication_session2";"statut_publication_final";"temoin_capitalise";"temoin_conserve";"duree_conservation";"note_minimale_conservation";"temoin_validation_acquis"\n/' ${DIR_FIC_SORTIE}/${FIC_NAME_PIVOT_INSERT_COC}
#fichier CHC
sed -i '1s/^/"id";"code_periode";"id_apprenant";"code_apprenant";"code_formation";"code_objet_formation";"code_chemin";"code_type_objet_maquette";"code_structure";"type_chc";"nombre_credit_formation";"nombre_credit_objet_formation";"temoin_objet_capitalisable";"temoin_objet_conservable";"duree_conservation";"etat_objet_dispense";"operation";"type_amenagement";"temoin_injection_chc"\n/' ${DIR_FIC_SORTIE}/${FIC_NAME_PIVOT_INSERT_CHC}

# remplacement des séparateurs décimaux par le . pour import des numériques avec une locale américaine (en_US.utf8) en base pivot
sed -i 's/\,/\./g'  ${DIR_FIC_SORTIE}/${FIC_NAME_PIVOT_INSERT_COC}
sed -i 's/\,/\./g'  ${DIR_FIC_SORTIE}/${FIC_NAME_PIVOT_INSERT_CHC}

echo -e "  >>>   Fin Genération des VACS d'insertion pour la base pivot" >> $FIC_LOG
echo -e "  >>>   Fin Genération des VACS d'insertion pour la base pivot"
sleep 1
echo "temps generation coc : ${runtime} secondes"
echo "temps generation chc : ${runtime_2} secondes"
# -----------------------------------------
# Fin du programme
# -----------------------------------------
echo "  >   Fin de l'execution du programme"
echo "  >   Fin de l'execution du programme" >> ${FIC_LOG}
echo "  =======================================" >> ${FIC_LOG}