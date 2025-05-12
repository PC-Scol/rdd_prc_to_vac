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
echo "  >>>   Activation prefix : ${PREFIXON} "
echo "  >>>   Prefix VDI : ${PREFIX_VDI} "	
echo "  >>>   Prefix VET : ${PREFIX_VET} "	
echo "  >>>   Code établissement : ${COD_ETB} "
echo "  >>>   Directory Cree : ${DIRECTORY} "
echo "  >>>   En mode génération des VAC d'insertion !!"


if [ ! "${COD_ANU}" ] || [ ! "${COD_ETB}" ]  || [ ! "${MDP_APOGEE}" ] || [ ! "${LOGIN_APOGEE}" ] ;then
   echo "  >>> Probleme paramètre"
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

# Modification Identifiant
echo -e "Login APOGEE ?  : \c"
      read LOGIN_APOGEE_SAISI

LOGIN_APOGEE=$LOGIN_APOGEE_SAISI

#Modification  Mot de passe

echo -e "Mot de passe APOGEE ?: \c"
      read MDP_APOGEE_SAISI

MDP_APOGEE=${MDP_APOGEE_SAISI}

    # chaine de connexion
STR_CONX=${LOGIN_APOGEE}/${MDP_APOGEE}

    # fichier de log
DIR_FIC_LOG=${DIR_FIC_ARCH}/logs
 # fichier de dossier tmp
DIR_FIC_TMP=${DIR_FIC_ARCH}/tmp


	#variable environnement
COD_ANU=`grep "^COD_ANU" $FIC_INI | cut -d\: -f2`
PREFIXON=`grep "^PREFIXON" $FIC_INI | cut -d\: -f2`
PREFIX_VET=`grep "^PREFIX_VET" $FIC_INI | cut -d\: -f2`
PREFIX_VDI=`grep "^PREFIX_VDI" $FIC_INI | cut -d\: -f2`

PDB=`printenv | grep ^TWO_TASK= | cut -d\= -f2`

COD_ETB=`grep "^COD_ETB" $FIC_INI | cut -d\: -f2`



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


if [[  -z ${PDB} ]]
then
  PDB=FIC_NAME_FILTRE=`grep "^PDB" $FIC_INI | cut -d\: -f2`
  if [[  -z ${PDB} ]]
  then
  	echo "Probleme PDB ou TWO_TASK"
       exit
  fi
fi

#Modification  Directory

echo -e "Nom Directory cree ?: \c"
      read DIRECTORY_SAISI

DIRECTORY=${DIRECTORY_SAISI}



 # log du programme
BASE_FIC_LOG=${NOM_BASE}

FIC_LOG=${DIR_FIC_LOG}/${BASE_FIC_LOG}.log
    # Variables du fichier d'environnement
    # Code annee universitaire

number=0
number=`ls ${DIR_FIC_LOG} | grep  "${BASE_FIC_LOG}*" | wc -l`

 # Appel du menu
choix_menu

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


# recuperation du chemin du fichier
number=0
#choix du fichier
for fic in  `ls ${DIR_FIC_SORTIE}/cle_vac*`; do 
	number=$(( ++number ))
	fic_insert=${fic}
	BASE_FIC_LOG=${BASE_FIC_LOG}_${fic##*/}
 	if [ "${number}" -eq " ${choice}" ];
	then
	  break
	fi
done

GEN_TIMESTAMP=$(date  +%s)

    # Fichier de stockage SQL pour requete generation de VAC dans APOGEE
FIC_NAME_PIVOT_INSERT_CHC=insert_CHC_vac_pivot_${COD_ANU}_${GEN_TIMESTAMP}.csv

FIC_NAME_PIVOT_INSERT_COC=insert_COC_vac_pivot_${COD_ANU}_${GEN_TIMESTAMP}.csv

FIC_NAME_PIVOT_DELETE=delete_vac_pivot_${COD_ANU}_${GEN_TIMESTAMP}.sql


number_fic=0
# sequence fic log
if [ $number_fic -ne 0 ];
then
  number=$(( ++number ))
  FIC_LOG=${DIR_FIC_LOG}/${BASE_FIC_LOG}_${$number_fic}.log
  echo "  >>>   Fichier avec masque ${FIC_LOG} existant"  

else
  FIC_LOG=${DIR_FIC_LOG}/${BASE_FIC_LOG}.log
fi

 # Appel du menu
confirm_menu


sleep 1


path_directory=`sqlplus -s ${STR_CONX} <<EOF
set pages 0
set head off
set feed off
SELECT directory_path
	  FROM dba_directories
	 WHERE directory_name = '${DIRECTORY}';
exit
EOF`


process_coc() {
local ligne=$1
local str_conx=$2

sql_condition_string=${ligne}

if [  -z ${sql_condition_string} ]
then
  exit
fi


echo "  >>>  Genération de la VAC d'insertion (coc) pour le pivot :  ${sql_condition_string}"

echo "  >>>  Genération de la VAC pour module COC d'insertion  pour le pivot :${sql_condition_string}" >> $FIC_LOG
echo "  >>>>   Genération de la VAC module COC d'insertion pour le pivot  " >> $FIC_LOG

#recuperation des valeurs dans les clés

IFS=';' read ANNEE COD_IND COD_ETP COD_VRS_VET COD_ELP DAT_DEC_ELP_VAA COD_CIP NOT_VAA BAR_NOT_VAA <<< "$sql_condition_string"

COD_ELP=$(echo "${COD_ELP}" | sed "s/'/''/g")
sqlplus -s <<FIN_SQL 
${str_conx}
set serveroutput on
SET HEADING OFF
SET FEEDBACK OFF 
set pagesize 1
VARIABLE ret_code NUMBER
BEGIN
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
		TEM_SNS_PRG varchar2(10) := NULL;
		PREFIXON_VAC varchar2(10) := '${PREFIXON}';
		PREFIX_VET_VAC varchar2(10) := '${PREFIX_VET}';
		PREFIX_VDI_VAC varchar2(10) := '${PREFIX_VDI}';
		LINEBUFFER varchar2(1000) := '';
		CLE_CHC varchar2(50) := '';
		CLE_COC varchar2(100) := '';
		key_ins varchar2(20000) := '';
		code_filtre_formation varchar2(50) := '';
		EXCEPTION_PROGRAMME EXCEPTION;


		-- utl file config
	       repertoire  varchar2(100)  := '${DIRECTORY}';
   	       fichier  varchar2(100)     := '${FIC_NAME_PIVOT_INSERT_COC}';
		fichier_sortie UTL_FILE.FILE_TYPE;

		fexists   BOOLEAN;
		file_length  NUMBER;
  		block_size   BINARY_INTEGER;
		entete varchar2(2000) :='"id";"code_formation";"code_objet_formation";"code_filtre_formation";"code_periode";"code_structure";"id_apprenant";"code_apprenant";"type_objet_formation";"code_mention";"grade_ects";"gpa";"note_retenue";"bareme_note_retenue";"point_jury_retenu";"note_session1";"bareme_note_session1";"point_jury_session1";"credit_ects_session1";"rang_session1";"note_session2";"bareme_note_session2";"point_jury_session2";"resultat_final";"resultat_session1";"resultat_session2";"rang_final";"credit_ects_final";"statut_deliberation_session1";"statut_deliberation_session2_final";"session_retenue";"absence_finale";"absence_session1";"absence_session2";"temoin_concerne_session2";"statut_publication_session1";"statut_publication_session2";"statut_publication_final";"temoin_capitalise";"temoin_conserve";"duree_conservation"; "note_minimale_conservation"; "temoin_validation_acquis"';

	BEGIN

		UTL_FILE.FGETATTR(repertoire  , fichier  , fexists, file_length, block_size);
    		IF not fexists THEN       	
			fichier_sortie  := utl_file.fopen(repertoire, fichier, 'A');
			utl_file.put_line(fichier_sortie,entete);
			utl_file.fclose(fichier_sortie);
			
   		END IF;

		 --Récupération des valeurs pour créer les clés et les ordres SQL
					
		DECLARE
			 custom_exception EXCEPTION;
		BEGIN	
	
		SELECT cod_dip
		INTO COD_DIP_VAL
		FROM (
 				SELECT cod_dip
 				FROM ins_adm_etp
 				 where cod_etp = COD_ETP_VAL
			 		and cod_vrs_vet = COD_VRS_VET_VAL
				 	and cod_anu = ANNEE_VAL
				 	and cod_ind = COD_IND_VAL
			)
			WHERE ROWNUM = 1;			
		 	
			IF COD_DIP_VAL IS NULL
			then 
				raise custom_exception;
			end if;

		EXCEPTION
        	WHEN OTHERS
			THEN 
				SELECT cod_dip
				INTO COD_DIP_VAL
				FROM (
  					SELECT cod_dip
 					FROM vdi_fractionner_vet
 				 	where cod_etp = COD_ETP_VAL
					and cod_vrs_vet = COD_VRS_VET_VAL
					and daa_deb_rct_vet <=  ANNEE_VAL
					and daa_fin_rct_vet >  ANNEE_VAL
				)
				WHERE ROWNUM = 1;
		END;		

		DECLARE
			 custom_exception EXCEPTION;
		BEGIN	
		SELECT cod_vrs_vdi
		INTO  COD_VRS_VDI_VAL
		FROM (
  			SELECT cod_vrs_vdi
 			FROM ins_adm_etp
 			where cod_etp = COD_ETP_VAL
			and cod_vrs_vet = COD_VRS_VET_VAL
			and cod_anu = ANNEE_VAL
			and cod_ind = COD_IND_VAL
		)
		WHERE ROWNUM = 1;	
			
			
		IF COD_VRS_VDI_VAL IS NULL
		then 			
			RAISE custom_exception;
			
		END IF;
		EXCEPTION
        	WHEN OTHERS
			THEN 
		 	SELECT cod_vrs_vdi
			INTO  COD_VRS_VDI_VAL
			FROM (
  				SELECT cod_vrs_vdi
 				FROM vdi_fractionner_vet
 				 	where cod_etp = COD_ETP_VAL
					and cod_vrs_vet = COD_VRS_VET_VAL
					and daa_deb_rct_vet <=  ANNEE_VAL
					and daa_fin_rct_vet >  ANNEE_VAL
 			)
			WHERE ROWNUM = 1;		
		END;

		
	
		DECLARE
			 custom_exception EXCEPTION;
		BEGIN

		SELECT cod_etu
		INTO COD_ETU_VAL
		FROM (
 			 SELECT cod_etu
			 from individu
			 where cod_ind  = COD_IND_VAL
		   )
		 WHERE ROWNUM = 1;

		EXCEPTION
        	WHEN OTHERS
			THEN 
		 	dbms_output.put_line('CODE ETU' || SQLERRM);
		END;

		DECLARE
			 custom_exception EXCEPTION;

		BEGIN
			SELECT cod_nel
				INTO COD_NEL_VAL				
				FROM (
  					SELECT cod_nel
 					from element_pedagogi
					where cod_elp = COD_ELP_VAL
				)
				WHERE ROWNUM = 1;
		EXCEPTION
        	WHEN OTHERS
			THEN 
		 	dbms_output.put_line('CODE NEL' ||SQLERRM);
		END;

		CLE_COC  := COD_IND_VAL || '-'||ANNEE_VAL || '-'|| COD_DIP_VAL ||'-'||COD_VRS_VDI_VAL||'-'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL ||'-ELP-'|| COD_ELP_VAL;
		code_filtre_formation := COD_DIP_VAL||'-'|| COD_VRS_VDI_VAL;

		-- Création de la clé pour les COC et le filtre formation en fonction du préfixage
		IF PREFIXON_VAC = 'Y'
		THEN
			CLE_COC  := COD_IND_VAL || '-'||ANNEE_VAL || '-'||PREFIX_VDI_VAC||'-'|| COD_DIP_VAL ||'-'||COD_VRS_VDI_VAL ||'-'||PREFIX_VET_VAC||'-'||PREFIX_VET_VAC||'-'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL ||'-ELP-'|| COD_ELP_VAL;
			code_filtre_formation := PREFIX_VET_VAC||'-'||COD_ETP_VAL||'-'|| COD_VRS_VET_VAL;
		END IF;
	
		--  Création de l'ordre d'insertion des coc en fonction des PRC trouvées dans APOGEE
		LINEBUFFER := LINEBUFFER || '''' || CLE_COC||''';';	
		LINEBUFFER := LINEBUFFER || '''' || code_filtre_formation||''';';				
		LINEBUFFER := LINEBUFFER || '''' || COD_ELP_VAL||''';';
		LINEBUFFER := LINEBUFFER || '''' || COD_DIP_VAL||'-' || COD_VRS_VDI_VAL||'>' || COD_ETP_VAL||'-' || COD_VRS_VET_VAL||''';';
		LINEBUFFER := LINEBUFFER || '''' || ANNEE_VAL||''';';
		LINEBUFFER := LINEBUFFER || '''' || COD_ETB_VAL||''';';
		LINEBUFFER := LINEBUFFER || '''' || COD_IND_VAL||''';';
		LINEBUFFER := LINEBUFFER || '''' || COD_ETU_VAL||''';';
		LINEBUFFER := LINEBUFFER || '''' || COD_NEL_VAL||''';';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER ||	NOT_VAA_VAL||';';
		LINEBUFFER := LINEBUFFER || BAR_NOT_VAA_VAL||';';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || NOT_VAA_VAL||';';
		LINEBUFFER := LINEBUFFER ||BAR_NOT_VAA_VAL||';';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';	
		LINEBUFFER := LINEBUFFER ||NOT_VAA_VAL||';';
		LINEBUFFER := LINEBUFFER ||BAR_NOT_VAA_VAL||';';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || '''ADM'';';
		LINEBUFFER := LINEBUFFER || '''ADM'';';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || '''T'';';
		LINEBUFFER := LINEBUFFER || '''T'';';
		LINEBUFFER := LINEBUFFER || '2;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || '''O'';';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || '''N'';';
		LINEBUFFER := LINEBUFFER || '''O'';';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL;';
		LINEBUFFER := LINEBUFFER || 'NULL';

		fichier_sortie  := utl_file.fopen(repertoire, fichier, 'A');
		utl_file.put_line(fichier_sortie,LINEBUFFER);
		utl_file.fclose(fichier_sortie);





	EXCEPTION
        WHEN OTHERS
		THEN 
		 ROLLBACK;
	END;
	
END;
/
EXIT
FIN_SQL

}

# Number of threads
num_threads=4

# parcours du fichier
start=`date +%s`
mapfile -t lines <  $fic_insert

array_length=${#lines[@]}
number_item=$((${array_length}/${num_threads}))
items_per_packet=$(printf "%.0f" "$number_item")


# Process items in packets
for ((i=0; i<${#lines[@]}; i+=$items_per_packet)); do
    # Create a packet of items
    packet=("${lines[@]:$i:$items_per_packet}")

    # Process the packet in parallel
    (
        for item in "${packet[@]}"; do
            process_coc "${item}" "${STR_CONX}"
	 done
    ) & 
    pids+=($!)  # Store the process ID
    # If we have reached the maximum number of threads, wait for one to finish
    if [[ ${#pids[@]} -eq $num_threads ]]; then
        wait -n
        pids=("${pids[@]/$!/}")  # Remove the finished process ID from the array
    fi

done


# wait for all pids
for pid in ${pids[*]}; do
    wait $pid
done

end=`date +%s`
runtime=$((end-start))
sleep 1

start=`date +%s`

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
echo "  >>>>   Genération de la VAC module CHC d'insertion pour le pivot  " >> $FIC_LOG

#recuperation des valeurs dans les clés
IFS=';' read ANNEE COD_IND COD_ETP COD_VRS_VET COD_ELP DAT_DEC_ELP_VAA COD_CIP NOT_VAA BAR_NOT_VAA <<< "$sql_condition_string"

COD_ELP=$(echo "${COD_ELP}" | sed "s/'/''/g")
sqlplus -s <<FIN_SQL 
${STR_CONX}
set serveroutput on
SET HEADING OFF
SET FEEDBACK OFF
set pagesize 1
VARIABLE ret_code NUMBER
BEGIN
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
		CREDIT_VAL number(8,0) := null;
		COD_NEL_VAL varchar2(10) := NULL;
		NOT_VAA_VAL varchar2(10) := '${NOT_VAA}';
		BAR_NOT_VAA_VAL varchar2(10) := '${BAR_NOT_VAA}';
		COD_DEP_PAY_VAC varchar2(3) := NULL;
		COD_TYP_DEP_PAY_VAC varchar2(10) := NULL;
		COD_ETB varchar2(10) := NULL;
		COD_PRG varchar2(10) := NULL;
		TEM_SNS_PRG varchar2(10) := NULL;
		PREFIXON_VAC varchar2(10) := '${PREFIXON}';
		PREFIX_VET_VAC varchar2(10) := '${PREFIX_VET}';
		PREFIX_VDI_VAC varchar2(10) := '${PREFIX_VDI}';
		LINEBUFFER varchar2(10000) := '';
		CLE_CHC varchar2(50) := '';
		code_filtre_formation varchar2(25) := '';
		chemin_element varchar2(5000) := '';
		count_elp number(8,0) := 0;
		first_elp varchar2(10) := 0;
		isExists number(8,0) := 0;
		EXCEPTION_PROGRAMME EXCEPTION;
		
		entete varchar2(2000) := '"id";"code_periode";"id_apprenant";"code_apprenant";"code_formation";"code_objet_formation";"code_chemin";"code_type_objet_maquette";"code_structure";"type_chc";"nombre_credit_formation";"nombre_credit_objet_formation";"temoin_objet_capitalisable";"temoin_objet_conservable";"duree_conservation";"etat_objet_dispense";"operation";"type_amenagement";"temoin_injection_chc"';
		-- utl file config
	       repertoire  varchar2(100)  := '${DIRECTORY}';
   	       fichier  varchar2(100)     := '${FIC_NAME_PIVOT_INSERT_CHC}';
		fichier_sortie UTL_FILE.FILE_TYPE;

		fexists   BOOLEAN;
		file_length  NUMBER;
  		block_size   BINARY_INTEGER;

	BEGIN
	  DECLARE
		-- curseur de creation du chemin
		cursor create_chemin_cur 
		is 
		 SELECT ice.cod_elp cod_elp_cur_val,
			 ice.cod_elp_sup cod_elp_sup_val,
			 ere.cod_typ_lse cod_typ_lse_val,
			 'L-' || ice.cod_lse cod_lse_val,
			 LEVEL number_niv
		 FROM ind_contrat_elp ice,
	 	      elp_regroupe_elp ere
		 CONNECT BY PRIOR ice.cod_elp_sup = ice.cod_elp 
			AND ere.cod_elp_pere = ice.cod_elp_sup
			AND ice.cod_ind =  COD_IND_VAL
			AND ice.cod_anu = ANNEE_VAL
			AND ice.cod_etp = COD_ETP_VAL
			AND ice.cod_vrs_vet = COD_VRS_VET_VAL
			AND ere.cod_lse=ice.cod_lse
		 START WITH ice.cod_elp = COD_ELP_VAL
			AND ice.cod_ind = COD_IND_VAL
			AND ice.cod_anu = ANNEE_VAL
			AND ice.cod_etp = COD_ETP_VAL
			AND ice.cod_vrs_vet = COD_VRS_VET_VAL
			AND ere.cod_elp_fils = ice.cod_elp
			AND ere.cod_lse=ice.cod_lse
		  GROUP BY ice.cod_elp,						
			ice.cod_elp_sup,
			'L-' || ice.cod_lse,
			ere.cod_typ_lse,		
			LEVEL 
		  ORDER BY LEVEL DESC;

		cod_elp_cur_val varchar2(10);
		cod_elp_sup_val varchar2(10);
		cod_lse_val varchar2(10);
		cod_typ_lse_val varchar2(10);
		niv number(8,0) := 0;
	  BEGIN

		UTL_FILE.FGETATTR(repertoire  , fichier  , fexists, file_length, block_size);
    		IF not fexists THEN       	
			fichier_sortie  := utl_file.fopen(repertoire, fichier, 'A');
			utl_file.put_line(fichier_sortie,entete);
			utl_file.fclose(fichier_sortie);
			
   		END IF;

	
		 --Récupération des valeurs pour créer les clés et les ordres SQL
					
		DECLARE
			 custom_exception EXCEPTION;
		BEGIN	
	
		SELECT cod_dip
		INTO COD_DIP_VAL
		FROM (
 				SELECT cod_dip
 				FROM ins_adm_etp
 				 where cod_etp = COD_ETP_VAL
			 		and cod_vrs_vet = COD_VRS_VET_VAL
				 	and cod_anu = ANNEE_VAL
				 	and cod_ind = COD_IND_VAL
			)
			WHERE ROWNUM = 1;			
		 	
			IF COD_DIP_VAL IS NULL
			then 
				raise custom_exception;
			end if;

		EXCEPTION
        	WHEN OTHERS
			THEN 
				SELECT cod_dip
				INTO COD_DIP_VAL
				FROM (
  					SELECT cod_dip
 					FROM vdi_fractionner_vet
 				 	where cod_etp = COD_ETP_VAL
					and cod_vrs_vet = COD_VRS_VET_VAL
					and daa_deb_rct_vet <=  ANNEE_VAL
					and daa_fin_rct_vet >  ANNEE_VAL
				)
				WHERE ROWNUM = 1;
		END;
		
		DECLARE
			 custom_exception EXCEPTION;
		BEGIN	
		SELECT cod_vrs_vdi
		INTO  COD_VRS_VDI_VAL
		FROM (
  			SELECT cod_vrs_vdi
 			FROM ins_adm_etp
 			where cod_etp = COD_ETP_VAL
			and cod_vrs_vet = COD_VRS_VET_VAL
			and cod_anu = ANNEE_VAL
			and cod_ind = COD_IND_VAL
		)
		WHERE ROWNUM = 1;	
			
			
		IF COD_VRS_VDI_VAL IS NULL
		then 			
			RAISE custom_exception;
			
		END IF;
		EXCEPTION
        	WHEN OTHERS
			THEN 
		 	SELECT cod_vrs_vdi
			INTO  COD_VRS_VDI_VAL
			FROM (
  				SELECT cod_vrs_vdi
 				FROM vdi_fractionner_vet
 				 	where cod_etp = COD_ETP_VAL
					and cod_vrs_vet = COD_VRS_VET_VAL
					and daa_deb_rct_vet <=  ANNEE_VAL
					and daa_fin_rct_vet >  ANNEE_VAL
 			)
			WHERE ROWNUM = 1;		
		END;

		
	
		DECLARE
			 custom_exception EXCEPTION;
		BEGIN

		SELECT cod_etu
		INTO COD_ETU_VAL
		FROM (
 			 SELECT cod_etu
			 from individu
			 where cod_ind  = COD_IND_VAL
		   )
		   WHERE ROWNUM = 1;

		EXCEPTION
        	WHEN OTHERS
			THEN 
		 	dbms_output.put_line('CODE ETU' || SQLERRM);
		END;

		DECLARE
			 custom_exception EXCEPTION;

		BEGIN
			SELECT cod_nel
				INTO COD_NEL_VAL				
				FROM (
  					SELECT cod_nel
 					from element_pedagogi
					where cod_elp = COD_ELP_VAL
				)
				WHERE ROWNUM = 1;
		EXCEPTION
        	WHEN OTHERS
			THEN 
		 	dbms_output.put_line('CODE NEL' ||SQLERRM);
		END;

		count_elp := 0;

		open create_chemin_cur;
		LOOP
		fetch create_chemin_cur into cod_elp_cur_val, cod_elp_sup_val,cod_typ_lse_val, cod_lse_val ,niv ;
			EXIT WHEN  create_chemin_cur%NOTFOUND;
			-- creation du chemin de l'élement en fonction des contrats pédagogiques d'APOGEE
			IF count_elp = 0
			then
			
				chemin_element  := COD_DIP_VAL ||'-'||COD_VRS_VDI_VAL||'>'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL;
				IF PREFIXON_VAC = 'Y'
				THEN
					chemin_element := PREFIX_VDI_VAC||'-'|| COD_DIP_VAL ||'-'||COD_VRS_VDI_VAL ||'>'||PREFIX_VET_VAC||'-'|| COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL;
				END IF;
				BEGIN
					SELECT COD_LSE
 					INTO first_elp
  					FROM (
    						SELECT DISTINCT COD_LSE
    						FROM ELP_REGROUPE_ELP
   						WHERE COD_ELP_FILS = cod_elp_sup_val
      						AND COD_TYP_LSE IN ('X', 'F')
    						ORDER BY COD_LSE
  					)
 					 WHERE ROWNUM = 1;	
				EXCEPTION
  				WHEN NO_DATA_FOUND THEN
   					 first_elp := NULL;
  				WHEN OTHERS THEN
   					 dbms_output.put_line(SQLERRM);
				END;

				if first_elp is not null then				
					chemin_element := chemin_element || '>L-' || first_elp;	
				END IF;
				
				-- si liste non trouve, ajout liste dans curseur
				IF cod_typ_lse_val in ('X','F')  
				and cod_elp_sup_val is null 
				and first_elp <>  cod_lse_val	
				then 
					chemin_element := chemin_element || '>' ||  cod_lse_val;											
				end if;			

				--- mettre element superieur
				if   cod_elp_sup_val is not null
				then
					chemin_element  := chemin_element   ||'>'|| cod_elp_sup_val;
				end if;

				first_elp := null;

			end if;
			-- ajout au chemin de la liste facultative ou obligatoire
			IF cod_typ_lse_val in ('X','F') and cod_elp_sup_val is not null
			then 
				chemin_element := chemin_element || '>' || cod_lse_val;			
			end if;

			-- ajout de l'element
			chemin_element := chemin_element || '>' || cod_elp_cur_val;


			count_elp := count_elp + 1;
		  
  		END LOOP;
		close create_chemin_cur;


		first_elp := null;

		-- generation des clés
		CLE_CHC  := COD_IND_VAL || '-'|| ANNEE_VAL ||'-'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL||'-'|| COD_ELP_VAL;
		code_filtre_formation := COD_DIP_VAL ||'-'|| COD_VRS_VDI_VAL||'>'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL;

		BEGIN
		-- generation du SQL
			LINEBUFFER := '''' || CLE_CHC||''';';
			LINEBUFFER := LINEBUFFER || '''' || ANNEE_VAL||''';';
			LINEBUFFER := LINEBUFFER || '''' || COD_IND_VAL||''';';
			LINEBUFFER := LINEBUFFER || '''' || COD_ETU_VAL||''';';
			LINEBUFFER := LINEBUFFER || '''' || COD_DIP_VAL||'-' || COD_VRS_VDI_VAL||'>' || COD_ETP_VAL||'-' || COD_VRS_VET_VAL||''';';	
			LINEBUFFER := LINEBUFFER || '''' || COD_ELP_VAL||''';';		
			LINEBUFFER := LINEBUFFER || '''' || chemin_element||''';';
			LINEBUFFER := LINEBUFFER || 'NULL;';
			LINEBUFFER := LINEBUFFER || '''' || COD_ETB_VAL||''';';
			LINEBUFFER := LINEBUFFER || '''N'';';
			LINEBUFFER := LINEBUFFER ||CREDIT_VAL||';';			
			LINEBUFFER := LINEBUFFER || 'NULL;';
			LINEBUFFER := LINEBUFFER || '''O'';';
			LINEBUFFER := LINEBUFFER || '''N'';';
			LINEBUFFER := LINEBUFFER || 'NULL;';
			LINEBUFFER := LINEBUFFER || 'NULL;';
			LINEBUFFER := LINEBUFFER || '''AM'';';
			LINEBUFFER := LINEBUFFER || '''EVAL'';';
			LINEBUFFER := LINEBUFFER || 'false'; 			
			LINEBUFFER := LINEBUFFER;
		
			fichier_sortie  := utl_file.fopen(repertoire, fichier, 'A');
			utl_file.put_line(fichier_sortie,LINEBUFFER);
			utl_file.fclose(fichier_sortie);
	
		EXCEPTION
        	WHEN OTHERS
			THEN 
		 	dbms_output.put_line(SQLERRM);
		END;

		
	 	EXCEPTION
        	WHEN OTHERS
			THEN 
		 	dbms_output.put_line(SQLERRM);
		END;


	EXCEPTION
        WHEN OTHERS
		THEN 
		 ROLLBACK;
	END;
	
END;
/
EXIT
FIN_SQL
}

# Process items in packets
for ((i=0; i<${#lines[@]}; i+=$items_per_packet)); do
    # Create a packet of items
    packet=("${lines[@]:$i:$items_per_packet}")

    # Process the packet in parallel
    (
        for item in "${packet[@]}"; do
            process_chc "${item}" "${STR_CONX}"
	 done
    )  &
    pids+=($!)  # Store the process ID
    # If we have reached the maximum number of threads, wait for one to finish
    if [[ ${#pids[@]} -eq $num_threads ]]; then
        wait -n
        pids=("${pids[@]/$!/}")  # Remove the finished process ID from the array
    fi

done

# wait for all pids
for pid in ${pids[*]}; do
    wait $pid
done

sleep 1


end=`date +%s`
runtime_2=$((end-start))

sleep 1



if [ ! -d ${DIR_FIC_TMP} ]; then
  mkdir ${DIR_FIC_TMP}
fi

awk 'NF > 0' ${path_directory}/${FIC_NAME_PIVOT_INSERT_COC}  > ${DIR_FIC_TMP}/fichier_tempo.tmp
awk 'NF > 0' ${path_directory}/${FIC_NAME_PIVOT_INSERT_CHC}  > ${DIR_FIC_TMP}/fichier_tempo_2.tmp
rm -f ${path_directory}/${FIC_NAME_PIVOT_INSERT_COC} 
rm -f ${path_directory}/${FIC_NAME_PIVOT_INSERT_CHC}
mv ${DIR_FIC_TMP}/fichier_tempo.tmp ${DIR_FIC_SORTIE}/${FIC_NAME_PIVOT_INSERT_COC}
mv ${DIR_FIC_TMP}/fichier_tempo_2.tmp ${DIR_FIC_SORTIE}/${FIC_NAME_PIVOT_INSERT_CHC}
if [ -d ${DIR_FIC_TMP} ]; then
  rmdir ${DIR_FIC_TMP}
fi



echo -e "  >>>   Fin Genération des VACS d'insertion pour la base pivot" >> $FIC_LOG
echo -e "  >>>   Fin Genération des VACS d'insertion pour la base pivot"
sleep 1
echo "temps coc : ${runtime}"
echo "temps chc : ${runtime_2}"
# -----------------------------------------
# Fin du programme
# -----------------------------------------
echo "  >   Fin de l'execution du programme" 
