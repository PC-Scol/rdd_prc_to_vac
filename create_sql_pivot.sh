# 
# Auteurs : j-luc.nizieux@uca.fr
#	     tristan.blanc@uca.fr 
# 
# SPDX-License-Identifier: AGPL-3.0-or-later
# License-Filename: LICENSE

# ---------------------------------------------------------------------------------------------------------------------
# create_sql_pivot.sh: script de génération des vacs pour les inserer ou le supprimer en base pivot
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
if [ "$TEM_DELETE" = "Y" ];
then
	echo "  >>>   En mode génération des VAC de Suppression !!"
else
	if [ "$TEM_DELETE" = "N" ];
	then
		echo "  >>>   En mode génération des VAC d'insertion !!"
	else
	  echo "  >>>    Impossible !!"
	  exit
	fi

fi

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

TEM_DELETE=`grep "^TEM_DELETE" $FIC_INI | cut -d\: -f2`

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
FIC_NAME_PIVOT_INSERT_CHC=insert_CHC_vac_pivot_${COD_ANU}_${GEN_TIMESTAMP}.sql

FIC_NAME_PIVOT_INSERT_COC=insert_COC_vac_pivot_${COD_ANU}_${GEN_TIMESTAMP}.sql

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


if [ "$TEM_DELETE" = "N" ];
then

# parcours du fichier
for sql_condition_string in  $(cat <  ${fic_insert}); do 

echo "  >>>  Genération de la VAC d'insertion  pour le pivot :  ${sql_condition_string}"

echo "  >>>  Genération de la VAC pour module CHC d'insertion  pour le pivot :${sql_condition_string}" >> $FIC_LOG
echo "  >>>>   Genération de la VAC module CHC d'insertion pour le pivot  " >> $FIC_LOG

#recuperation des valeurs dans les clés
ANNEE="$(cut -d';' -f1 <<< ${sql_condition_string})"
COD_IND="$(cut -d';'  -f2 <<< ${sql_condition_string})"
COD_ETP="$(cut -d';'  -f3 <<< ${sql_condition_string})" 
COD_VRS_VET="$(cut -d';'  -f4 <<< ${sql_condition_string})"
COD_ELP="$(cut -d';'  -f5 <<< ${sql_condition_string})" 
DAT_DEC_ELP_VAA="$(cut -d';'  -f6 <<< ${sql_condition_string})"
COD_CIP="$(cut -d';'  -f7 <<< ${sql_condition_string})" 
NOT_VAA="$(cut -d';'  -f8 <<< ${sql_condition_string})"
BAR_NOT_VAA="$(cut -d';'  -f9 <<< ${sql_condition_string})"


$ORACLE_HOME/bin/sqlplus -s <<FIN_SQL 
${STR_CONX}
SPOOL ${DIR_FIC_SORTIE}/${FIC_NAME_PIVOT_INSERT_CHC} append
set serveroutput on
SET HEADING OFF
SET FEEDBACK OFF
set linesize 20000 
set pagesize 1
VARIABLE ret_code NUMBER
BEGIN
	DECLARE 
	 	ANNEE_VAL varchar2(4) := '${ANNEE}';
		COD_IND_VAL number(8,0) := '${COD_IND}';	
		COD_ETU_VAL number(8,0) := null;	
		COD_ETP_VAL varchar2(6) := '${COD_ETP}';
		COD_VRS_VET_VAL number(3,0) := '${COD_VRS_VET}';
		COD_ELP_VAL varchar2(20000) := '${COD_ELP}';
		COD_ETB_VAL varchar2(20000) := '${COD_ETB}';
		COD_DIP_VAL varchar2(20000) :=	NULL;
		COD_VRS_VDI_VAL varchar2(20000) := NULL;
		COD_NEL_VAL varchar2(20000) := NULL;
		NOT_VAA_VAL varchar2(20000) := '${NOT_VAA}';
		BAR_NOT_VAA_VAL varchar2(20000) := '${BAR_NOT_VAA}';
		COD_DEP_PAY_VAC varchar2(3) := NULL;
		COD_TYP_DEP_PAY_VAC varchar2(20000) := NULL;
		COD_ETB varchar2(20000) := NULL;
		COD_PRG varchar2(20000) := NULL;
		TEM_SNS_PRG varchar2(20000) := NULL;
		PREFIXON_VAC varchar2(20000) := '${PREFIXON}';
		PREFIX_VET_VAC varchar2(20000) := '${PREFIX_VET}';
		PREFIX_VDI_VAC varchar2(20000) := '${PREFIX_VDI}';
		LINEBUFFER varchar2(20000) := '';
		CLE_CHC varchar2(20000) := '';
		CLE_COC varchar2(20000) := '';
		key_ins varchar2(20000) := '';
		code_filtre_formation varchar2(20000) := '';
		code_chemin varchar2(20000) := NULL;
		chemin_element varchar2(20000) := '';
		count_elp number(8,0) := 0;
		first_elp varchar2(20000) := 0;
		isExists number(8,0) := 0;
		EXCEPTION_PROGRAMME EXCEPTION;

		-- curseur de creation du chemin
		cursor create_chemin_cur (cod_ind_in in varchar2, cod_anu_in in varchar2, cod_elp_in in varchar2, cod_etp_in in varchar2, cod_vrs_vet_in in varchar2)
		is 
		 SELECT ice.cod_elp,
			 ice.cod_elp_sup,
			 ere.cod_typ_lse type_lse,
			 'L-' || ice.cod_lse cod_lse,
			 LEVEL number_niv
		 FROM ind_contrat_elp ice,
	 	      elp_regroupe_elp ere
		 CONNECT BY PRIOR ice.cod_elp_sup = ice.cod_elp 
			AND ere.cod_elp_pere = ice.cod_elp_sup
			AND ice.cod_ind = cod_ind_in
			AND ice.cod_anu = cod_anu_in
			AND ice.cod_etp = cod_etp_in
			AND ice.cod_vrs_vet = cod_vrs_vet_in
			AND ere.cod_lse=ice.cod_lse
		 START WITH ice.cod_elp = cod_elp_in
			AND ice.cod_ind = cod_ind_in
			AND ice.cod_anu = cod_anu_in
			AND ice.cod_etp = cod_etp_in
			AND ice.cod_vrs_vet = cod_vrs_vet_in
			AND ere.cod_elp_fils = ice.cod_elp
			AND ere.cod_lse=ice.cod_lse
		  GROUP BY ice.cod_elp,						
			ice.cod_elp_sup,
			'L-' || ice.cod_lse,
			ere.cod_typ_lse,
			LEVEL 
		  ORDER BY LEVEL desc;


	
	BEGIN
					
		 SELECT DISTINCT cod_dip
		 into COD_DIP_VAL
		 from ins_adm_etp
			 where cod_etp = COD_ETP_VAL
			 and cod_vrs_vet = COD_VRS_VET_VAL
			 and cod_anu = ANNEE_VAL
			 and cod_ind = COD_IND_VAL
			  ;

		select DISTINCT cod_vrs_vdi
 		into COD_VRS_VDI_VAL
		from ins_adm_etp
			 where cod_etp = COD_ETP_VAL
			 and cod_vrs_vet = COD_VRS_VET_VAL
			 and cod_anu = ANNEE_VAL
			 and cod_ind = COD_IND_VAL;


		SELECT cod_etu
		into COD_ETU_VAL
		from individu
		where cod_ind  = COD_IND_VAL;


		select cod_nel
		into COD_NEL_VAL
		from element_pedagogi
		where cod_elp = COD_ELP_VAL;


		count_elp := 0;
		-- creation du chemin de l'élement en fonction des contrats pédagogiques d'APOGEE
		for create_chemin_rec in create_chemin_cur (COD_IND_VAL,ANNEE_VAL,COD_ELP_VAL,COD_ETP_VAL,COD_VRS_VET_VAL)
		loop
			IF count_elp = 0
			then
			
				IF PREFIXON_VAC = 'Y'
				THEN
					chemin_element := PREFIX_VDI_VAC||'-'|| COD_DIP_VAL ||'-'||COD_VRS_VDI_VAL ||'>'||PREFIX_VET_VAC||'-'|| COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL;
				ELSE
					chemin_element  := COD_DIP_VAL ||'-'||COD_VRS_VDI_VAL||'>'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL;
					
				END IF;

				-- verification de l'existence d'une liste entre vet et element fils
				select count(*) into isExists from ELP_REGROUPE_ELP ERE where  COD_ELP_FILS = create_chemin_rec.cod_elp_sup and COD_TYP_LSE = 'X';
   				IF isExists  > 0
				THEN 


				  	select FIRST_VALUE (COD_LSE) OVER (ORDER BY COD_LSE ASC)
					into first_elp
					from ELP_REGROUPE_ELP ERE
					where  COD_ELP_FILS = create_chemin_rec.cod_elp_sup
					and COD_TYP_LSE in ('X','F') ;
						
					first_elp := 'L-'|| first_elp;
					
					chemin_element := chemin_element || '>' || first_elp;	
	
				
				END IF;
				
				-- si liste non trouve, ajout liste dans curseur
				IF create_chemin_rec.type_lse in ('X','F')  
				and create_chemin_rec.cod_elp_sup is null 
				and first_elp <> create_chemin_rec.cod_lse		
				then 
					chemin_element := chemin_element || '>' || create_chemin_rec.cod_lse;											
				end if;			

				--- mettre element superieur
				if   create_chemin_rec.cod_elp_sup is not null
				then
						chemin_element  := chemin_element   ||'>'|| create_chemin_rec.cod_elp_sup;
				end if;

				first_elp := null;

			end if;
			-- ajout au chemin de la liste facultative ou obligatoire
			IF create_chemin_rec.type_lse in ('X','F') and create_chemin_rec.cod_elp_sup is not null
			then 
				chemin_element := chemin_element || '>' || create_chemin_rec.cod_lse;			
			end if;

			-- ajout de l'element
			chemin_element := chemin_element || '>' || create_chemin_rec.cod_elp;


			count_elp := count_elp + 1;
		end loop;

		first_elp := null;

		-- generation des clés
		CLE_CHC  := COD_IND_VAL || '-'|| ANNEE_VAL ||'-'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL||'-'|| COD_ELP_VAL;
		code_filtre_formation := COD_DIP_VAL ||'-'|| COD_VRS_VDI_VAL||'>'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL;
	
		-- generation du SQL
		LINEBUFFER := 'insert into apprenant_chc(id,code_periode,id_apprenant,code_apprenant,code_formation,code_objet_formation,code_chemin,code_type_objet_maquette,code_structure,type_chc,nombre_credit_formation,nombre_credit_objet_formation,temoin_objet_capitalisable,temoin_objet_conservable,duree_conservation,etat_objet_dispense,operation,type_amenagement,temoin_injection_chc)VALUES(';
				LINEBUFFER := LINEBUFFER || '''' || CLE_CHC||''',';
				LINEBUFFER := LINEBUFFER || '''' || ANNEE_VAL||''',';
				LINEBUFFER := LINEBUFFER || '''' || COD_IND_VAL||''',';
				LINEBUFFER := LINEBUFFER || '''' || COD_ETU_VAL||''',';
				LINEBUFFER := LINEBUFFER || '''' || COD_DIP_VAL||'-' || COD_VRS_VDI_VAL||'>' || COD_ETP_VAL||'-' || COD_VRS_VET_VAL||''',';
				LINEBUFFER := LINEBUFFER || '''' || COD_ELP_VAL||''',';
				LINEBUFFER := LINEBUFFER || '''' || chemin_element||''',';
				LINEBUFFER := LINEBUFFER || 'NULL,';
				LINEBUFFER := LINEBUFFER || '''' || COD_ETB_VAL||''',';
				LINEBUFFER := LINEBUFFER || '''N'',';
				LINEBUFFER := LINEBUFFER || 'NULL,';
				LINEBUFFER := LINEBUFFER || 'NULL,';
				LINEBUFFER := LINEBUFFER || '''O'',';
				LINEBUFFER := LINEBUFFER || '''N'',';
				LINEBUFFER := LINEBUFFER || 'NULL,';
				LINEBUFFER := LINEBUFFER || 'NULL,';
				LINEBUFFER := LINEBUFFER || '''AM'',';
				LINEBUFFER := LINEBUFFER || '''EVAL'',';
				LINEBUFFER := LINEBUFFER || 'false'; 
				LINEBUFFER := LINEBUFFER || ') ON CONFLICT DO NOTHING;';				
				LINEBUFFER := LINEBUFFER;
		LINEBUFFER := LINEBUFFER || 'commit;';

		dbms_output.put_line(LINEBUFFER);




	EXCEPTION
        WHEN OTHERS
		THEN 
		 LINEBUFFER :=  SQLERRM;
		 dbms_output.put_line('Erreur génération :' ||SQLERRM);
		 ROLLBACK;
	END;
	
END;
/
PRINT 
SPOOL OFF
EXIT
FIN_SQL

	
echo "  >>>> Fin Genération de la VAC module COC d'insertion pour la base pivot ">> $FIC_LOG	

echo "  >>>  Genération de la VAC pour module COC d'insertion  pour le pivot :${sql_condition_string}" >> $FIC_LOG
echo "  >>>>   Genération de la VAC module COC d'insertion pour le pivot  " >> $FIC_LOG


$ORACLE_HOME/bin/sqlplus -s <<FIN_SQL 
${STR_CONX}
SPOOL ${DIR_FIC_SORTIE}/${FIC_NAME_PIVOT_INSERT_COC} append
set serveroutput on
SET HEADING OFF
SET FEEDBACK OFF
set linesize 20000 
set pagesize 1
VARIABLE ret_code NUMBER
BEGIN
	DECLARE 
	 	ANNEE_VAL varchar2(4) := '${ANNEE}';
		COD_IND_VAL number(8,0) := '${COD_IND}';	
		COD_ETU_VAL number(8,0) := null;	
		COD_ETP_VAL varchar2(6) := '${COD_ETP}';
		COD_VRS_VET_VAL number(3,0) := '${COD_VRS_VET}';
		COD_ELP_VAL varchar2(20000) := '${COD_ELP}';
		COD_ETB_VAL varchar2(20000) := '${COD_ETB}';
		COD_DIP_VAL varchar2(20000) :=	NULL;
		COD_VRS_VDI_VAL varchar2(20000) := NULL;
		COD_NEL_VAL varchar2(20000) := NULL;
		NOT_VAA_VAL varchar2(20000) := '${NOT_VAA}';
		BAR_NOT_VAA_VAL varchar2(20000) := '${BAR_NOT_VAA}';
		COD_DEP_PAY_VAC varchar2(3) := NULL;
		COD_TYP_DEP_PAY_VAC varchar2(20000) := NULL;
		COD_ETB varchar2(20000) := NULL;
		COD_PRG varchar2(20000) := NULL;
		TEM_SNS_PRG varchar2(20000) := NULL;
		PREFIXON_VAC varchar2(20000) := '${PREFIXON}';
		PREFIX_VET_VAC varchar2(20000) := '${PREFIX_VET}';
		PREFIX_VDI_VAC varchar2(20000) := '${PREFIX_VDI}';
		LINEBUFFER varchar2(20000) := '';
		CLE_CHC varchar2(20000) := '';
		CLE_COC varchar2(20000) := '';
		key_ins varchar2(20000) := '';
		code_filtre_formation varchar2(20000) := '';
		sous_requete varchar2(20000) := '';
		EXCEPTION_PROGRAMME EXCEPTION;
	BEGIN
		 --Récupération des valeurs pour créer les clés et les ordres SQL
					
		 SELECT DISTINCT cod_dip
		 into COD_DIP_VAL
		 from ins_adm_etp
			 where cod_etp = COD_ETP_VAL
			 and cod_vrs_vet = COD_VRS_VET_VAL
			 and cod_anu = ANNEE_VAL
			 and cod_ind = COD_IND_VAL
			  ;

		select DISTINCT cod_vrs_vdi
 		into COD_VRS_VDI_VAL
		from ins_adm_etp
			 where cod_etp = COD_ETP_VAL
			 and cod_vrs_vet = COD_VRS_VET_VAL
			 and cod_anu = ANNEE_VAL
			 and cod_ind = COD_IND_VAL;


		SELECT cod_etu
		into COD_ETU_VAL
		from individu
		where cod_ind  = COD_IND_VAL;


		select cod_nel
		into COD_NEL_VAL
		from element_pedagogi
		where cod_elp = COD_ELP_VAL;

		-- Création de la clé pour les COC et le filtre formation en fonction du préfixage
		IF PREFIXON_VAC = 'Y'
		THEN
			CLE_COC  := COD_IND_VAL || '-'||ANNEE_VAL || '-'||PREFIX_VDI_VAC||'-'|| COD_DIP_VAL ||'-'||COD_VRS_VDI_VAL ||'-'||PREFIX_VET_VAC||'-'||PREFIX_VET_VAC||'-'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL ||'-ELP-'|| COD_ELP_VAL;
			code_filtre_formation := PREFIX_VET_VAC||'-'||COD_ETP_VAL||'-'|| COD_VRS_VET_VAL;
		ELSE
			CLE_COC  := COD_IND_VAL || '-'||ANNEE_VAL || '-'|| COD_DIP_VAL ||'-'||COD_VRS_VDI_VAL||'-'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL ||'-ELP-'|| COD_ELP_VAL;
			code_filtre_formation := COD_DIP_VAL||'-'|| COD_VRS_VDI_VAL;
		END IF;
	
		--  Création de l'ordre d'insertion des coc en fonction des PRC trouvées dans APOGEE
		LINEBUFFER := LINEBUFFER || chr(10) ||'insert into apprenant_coc (id,code_formation,code_objet_formation,code_filtre_formation,code_periode,code_structure,id_apprenant,code_apprenant,type_objet_formation,code_mention,grade_ects,gpa,note_retenue,bareme_note_retenue,point_jury_retenu,note_session1,bareme_note_session1,point_jury_session1,credit_ects_session1,rang_session1,note_session2,bareme_note_session2,point_jury_session2,resultat_final,resultat_session1,resultat_session2,rang_final,credit_ects_final,statut_deliberation_session1,statut_deliberation_session2_final,session_retenue,absence_finale,absence_session1,absence_session2,temoin_concerne_session2,statut_publication_session1,statut_publication_session2,statut_publication_final,temoin_capitalise,temoin_conserve,duree_conservation,note_minimale_conservation,temoin_validation_acquis) values (';
						LINEBUFFER := LINEBUFFER || '''' || CLE_COC||''',';	
						LINEBUFFER := LINEBUFFER || '''' || code_filtre_formation||''',';				
						LINEBUFFER := LINEBUFFER || '''' || COD_ELP_VAL||''',';
						LINEBUFFER := LINEBUFFER || '''' || COD_DIP_VAL||'-' || COD_VRS_VDI_VAL||'>' || COD_ETP_VAL||'-' || COD_VRS_VET_VAL||''',';
						LINEBUFFER := LINEBUFFER || '''' || ANNEE_VAL||''',';
						LINEBUFFER := LINEBUFFER || '''' || COD_ETB_VAL||''',';
						LINEBUFFER := LINEBUFFER || '''' || COD_IND_VAL||''',';
						LINEBUFFER := LINEBUFFER || '''' || COD_ETU_VAL||''',';
						LINEBUFFER := LINEBUFFER || '''' || COD_NEL_VAL||''',';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER ||	NOT_VAA_VAL||',';
						LINEBUFFER := LINEBUFFER || BAR_NOT_VAA_VAL||',';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER || NOT_VAA_VAL||',';
						LINEBUFFER := LINEBUFFER ||BAR_NOT_VAA_VAL||',';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER || 'NULL,';	
						LINEBUFFER := LINEBUFFER ||NOT_VAA_VAL||',';
						LINEBUFFER := LINEBUFFER ||BAR_NOT_VAA_VAL||',';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER || '''ADM'',';
						LINEBUFFER := LINEBUFFER || '''ADM'',';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER || '''T'',';
						LINEBUFFER := LINEBUFFER || '''T'',';
						LINEBUFFER := LINEBUFFER || '2,';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER || '''O'',';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER || '''N'',';
						LINEBUFFER := LINEBUFFER || '''O'',';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER || 'NULL,';
						LINEBUFFER := LINEBUFFER || 'NULL';
						LINEBUFFER := LINEBUFFER ||') ON CONFLICT DO NOTHING; commit;';
		LINEBUFFER := LINEBUFFER || 'commit;';		

		dbms_output.put_line(LINEBUFFER);




	EXCEPTION
        WHEN OTHERS
		THEN 
		 LINEBUFFER :=  SQLERRM;
		 dbms_output.put_line('Erreur génération :' ||SQLERRM);
		 ROLLBACK;
	END;
	
END;
/
PRINT 
SPOOL OFF
EXIT
FIN_SQL

	
echo "  >>>> Fin Genération de la VAC module COC d'insertion pour la base pivot ">> $FIC_LOG	


done

sleep 1


if [ ! -d ${DIR_FIC_TMP} ]; then
  mkdir ${DIR_FIC_TMP}
fi

awk 'NF > 0' ${DIR_FIC_SORTIE}/${FIC_NAME_PIVOT_INSERT_COC}  > ${DIR_FIC_TMP}/fichier_tempo.tmp
awk 'NF > 0' ${DIR_FIC_SORTIE}/${FIC_NAME_PIVOT_INSERT_CHC}  > ${DIR_FIC_TMP}/fichier_tempo_2.tmp
mv ${DIR_FIC_TMP}/fichier_tempo.tmp ${DIR_FIC_SORTIE}/${FIC_NAME_PIVOT_INSERT_COC}
mv ${DIR_FIC_TMP}/fichier_tempo_2.tmp ${DIR_FIC_SORTIE}/${FIC_NAME_PIVOT_INSERT_CHC}
if [ -d ${DIR_FIC_TMP} ]; then
  rmdir ${DIR_FIC_TMP}
fi



echo -e "  >>>   Fin Genération des VACS d'insertion pour la base pivot">> $FIC_LOG
echo -e "  >>>   Fin Genération des VACS d'insertion pour la base pivot"
sleep 1
fi

if [ "$TEM_DELETE" = "Y" ];
then

# parcours du fichier
for sql_condition_string in  $(cat <  ${fic_insert}); do 

echo "  >>>  Genération de la VAC de suppression  pour le pivot :  ${sql_condition_string}"

echo "  >>>  Genération de la VAC de suppression  pour le pivot :${sql_condition_string}" >> $FIC_LOG
echo "  >>>>   Genération de la VAC de suppression  pour le pivot  " >> $FIC_LOG

ANNEE="$(cut -d';' -f1 <<< ${sql_condition_string})"
COD_IND="$(cut -d';'  -f2 <<< ${sql_condition_string})"
COD_ETP="$(cut -d';'  -f3 <<< ${sql_condition_string})" 
COD_VRS_VET="$(cut -d';'  -f4 <<< ${sql_condition_string})"
COD_ELP="$(cut -d';'  -f5 <<< ${sql_condition_string})" 

$ORACLE_HOME/bin/sqlplus -s <<FIN_SQL 
${STR_CONX}
SPOOL ${DIR_FIC_SORTIE}/${FIC_NAME_PIVOT_DELETE} append
set serveroutput on
SET HEADING OFF
SET FEEDBACK OFF
set linesize 20000 
set pagesize 1
VARIABLE ret_code NUMBER
BEGIN
	DECLARE 
	 	ANNEE_VAL varchar2(4) := '${ANNEE}';
		COD_IND_VAL number(8,0) := '${COD_IND}';		
		COD_ETP_VAL varchar2(6) := '${COD_ETP}';
		COD_VRS_VET_VAL number(3,0) := '${COD_VRS_VET}';
		COD_ELP_VAL varchar2(20000) := '${COD_ELP}';
		COD_ETB varchar2(20000) := '${COD_ETB}';
		COD_DIP_VAL varchar2(20000) :=	NULL;
		COD_VRS_VDI_VAL varchar2(20000) := NULL;
		COD_NEL_VAL varchar2(20000) := NULL;
		PREFIXON_VAC varchar2(20000) := '${PREFIXON}';
		PREFIX_VET_VAC varchar2(20000) := '${PREFIX_VET}';
		PREFIX_VDI_VAC varchar2(20000) := '${PREFIX_VDI}';
		LINEBUFFER varchar2(20000) := '';
		CLE_CHC varchar2(20000) := '';
		CLE_COC varchar2(20000) := '';
		EXCEPTION_PROGRAMME EXCEPTION;
	BEGIN

		 --Récupération des valeurs pour créer les clés et les ordres SQL
		 SELECT DISTINCT cod_dip
		 into COD_DIP_VAL
		 from ins_adm_etp
			 where cod_etp = COD_ETP_VAL
			 and cod_vrs_vet = COD_VRS_VET_VAL
			 and cod_anu = ANNEE_VAL
			 and cod_ind = COD_IND_VAL
			  ;

		select DISTINCT cod_vrs_vdi
 		into COD_VRS_VDI_VAL
		from ins_adm_etp
			 where cod_etp = COD_ETP_VAL
			 and cod_vrs_vet = COD_VRS_VET_VAL
			 and cod_anu = ANNEE_VAL
			 and cod_ind = COD_IND_VAL;

		--  generation des clés
		CLE_CHC  := COD_IND_VAL || '-'|| ANNEE_VAL ||'-'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL||'-'|| COD_ELP_VAL;
		
		IF PREFIXON_VAC = 'Y'
		THEN
			CLE_COC  := COD_IND_VAL || '-'||ANNEE_VAL || '-'||PREFIX_VDI_VAC||'-'|| COD_DIP_VAL ||'-'||COD_VRS_VDI_VAL ||'-'||PREFIX_VET_VAC||'-'||PREFIX_VET_VAC||'-'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL ||'-ELP-'|| COD_ELP_VAL;
		ELSE
			CLE_COC  := COD_IND_VAL || '-'||ANNEE_VAL || '-'|| COD_DIP_VAL ||'-'||COD_VRS_VDI_VAL||'-'||COD_ETP_VAL ||'-'|| COD_VRS_VET_VAL ||'-ELP-'|| COD_ELP_VAL;
		END IF;


		--  generation du SQL
		LINEBUFFER := ' DELETE FROM apprenant_chc WHERE id =';
		LINEBUFFER := LINEBUFFER || '''' || CLE_CHC ||''';';
		LINEBUFFER := LINEBUFFER || chr(10);
		LINEBUFFER := LINEBUFFER || 'DELETE FROM apprenant_coc WHERE id =';
		LINEBUFFER := LINEBUFFER || '''' || CLE_COC||''';';

		dbms_output.put_line(LINEBUFFER);




	EXCEPTION
        WHEN OTHERS
		THEN 
		 LINEBUFFER :=  SQLERRM;
		 dbms_output.put_line('Erreur génération :' ||SQLERRM);
		 ROLLBACK;
	END;
	
END;
/
PRINT 
SPOOL OFF
EXIT
FIN_SQL

	
echo "  >>>> Fin Genération de la VAC de suppression pour la base pivot ">> $FIC_LOG	

done

sleep 1

if [ ! -d ${DIR_FIC_TMP} ]; then
  mkdir ${DIR_FIC_TMP}
fi

awk 'NF > 0' ${DIR_FIC_SORTIE}/${FIC_NAME_PIVOT_DELETE} > ${DIR_FIC_TMP}/delete_pivot_tmp.sql

mv ${DIR_FIC_TMP}/delete_pivot_tmp.sql  ${DIR_FIC_SORTIE}/${FIC_NAME_PIVOT_DELETE} 

if [ -d ${DIR_FIC_TMP} ]; then
  rmdir ${DIR_FIC_TMP}
fi





echo -e "  >>>   Fin Genération des VACS de suppression  pour la base pivot">> $FIC_LOG
echo -e "  >>>   Fin Genération des VACS de suppression  pour la base pivot"
fi
sleep 1

# -----------------------------------------
# Fin du programme
# -----------------------------------------
echo "  >   Fin de l'execution du programme" 
echo -e "Fin normale de $0 :\n" >> $FIC_LOG