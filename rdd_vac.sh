# 
# Auteurs : j-luc.nizieux@uca.fr
#	     tristan.blanc@uca.fr 
# 
# SPDX-License-Identifier: AGPL-3.0-or-later
# License-Filename: LICENSE


# -----------------------------------------------------------------------------
# rdd_vac.sh: Generation de VAC pour RDD PEGASE
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
echo "    >>>     Code Ann e universitaire : ${COD_ANU}"		        			
echo "    >>>     Type Detection : ${COD_TYP_DETECT}"		    
echo "    >>>     Code Objet : ${COD_OBJ}"
echo "    >>>     Code Version Objet : ${COD_VRS_OBJ}"
echo "    >>>     Dossier racine : ${DIR_FIC_ARCH}"
echo "    >>>     Identifiant base de donnee : ${LOGIN_APOGEE}"	 
echo "    >>>     Mot de passe base de donnee : ${MDP_APOGEE}"	  
echo "    >>>     PDB : $PDB"      
echo "    >>>     Directory Cree : ${DIRECTORY} "
echo "-------------------------------------------------"
# -----------------------------------------
# Confirmation
# -----------------------------------------

echo "Continuer ? (Ctrl-c pour annuler) :"
read pocpoc
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

     #FICHIER INI (chemin   ajouter)
FIC_INI=${DIR_FIC_ARCH}/${NOM_BASE}.ini

echo "-------------------------------------------------"
echo "Vos identifiants et mot de passe :"

# Modification Identifiant
echo -e "Login APOGEE ?  : \c"
      read LOGIN_APOGEE_SAISI

LOGIN_APOGEE=$LOGIN_APOGEE_SAISI


#Modification  Mot de passe

echo -e "Mot de passe APOGEE ?: \c"
      read MDP_APOGEE_SAISI

MDP_APOGEE=${MDP_APOGEE_SAISI}


#Modification  Mot de passe

echo -e "Nom Directory cree ?: \c"
      read DIRECTORY_SAISI

DIRECTORY=${DIRECTORY_SAISI}



    # chaine de connexion
STR_CONX=${LOGIN_APOGEE}/${MDP_APOGEE}

 # dossier archive
DIR_FIC_IN=${DIR_FIC_ARCH}/archives
   

 # dossier archive sortie
DIR_FIC_SORTIE_IN=${DIR_FIC_IN}/filtre_sortie

   # dossier fic in 
DIR_FIC_VET_IN=${DIR_FIC_ARCH}/filtre_formation_a_deposer

    # fichier de log
DIR_FIC_LOG=`grep "^DIR_FIC_ARCH" $FIC_INI | cut -d\: -f2`logs
    # fichier temp (Recuperation des VETS selon type de detection)
DIR_FIC_TMP=`grep "^DIR_FIC_ARCH" $FIC_INI | cut -d\: -f2`tmp

    # Variables du fichier d'environnement
    # Code annee universitaire
COD_ANU=`grep "^COD_ANU" $FIC_INI | cut -d\: -f2`
    # Code type de detection (CMP, VET, ou l'ensemble des VETS 'VETALL')
COD_TYP_DETECT=`grep "^COD_TYP_OBJ" $FIC_INI | cut -d\: -f2`
    # Code element p dagogique
COD_OBJ=`grep "^COD_OBJ" $FIC_INI | cut -d\: -f2`
    # Code version element p dagogique
COD_VRS_OBJ=`grep "^COD_VRS_OBJ" $FIC_INI | cut -d\: -f2`

    # repertoires de depot et d'archive
FIC_NAME_APOGEE=`grep "^FIC_NAME_APOGEE" $FIC_INI | cut -d\: -f2`

    # repertoire depot du filtre de formation pour LISTE_VET
FIC_NAME_FILTRE=`grep "^FIC_NAME_FILTRE" $FIC_INI | cut -d\: -f2`

PDB=`printenv | grep ^TWO_TASK= | cut -d\= -f2`


 # Appel du menu
confirm_menu


#  Verification existance du dossier log
if  [[ -z ${LOGIN_APOGEE} ]]
then
  echo " Login non existant"
  exit
fi

if  [[  -z ${MDP_APOGEE} ]]
then
  echo "Mot de passe non existant"
  exit
fi

if  [[  -z ${DIRECTORY_SAISI} ]]
then
  echo "Directory non existant"
  exit
fi


if [[  -z ${PDB} ]]
then
  PDB=`grep "^PDB" $FIC_INI | cut -d\: -f2`
  if [[  -z ${PDB} ]]
  then
  	echo "Probleme PDB ou TWO_TASK"
       exit
  fi
fi

    # generation timestamp pour les fichiers
GEN_TIMESTAMP=$(date -I)

    # Fichier de stockage SQL pour requete generation de VAC dans APOGEE
FIC_NAME_APOGEE_INSERT=cle_vac_${COD_ANU}_${COD_TYP_DETECT}_${COD_OBJ}_${GEN_TIMESTAMP}


    # Fichier de stockage temporaire des VETS
FIC_NAME_TMP=vets.tmp
vet_archive=vets_${COD_ANU}_${COD_TYP_DETECT}_${GEN_TIMESTAMP}

 # log du programme
BASE_FIC_LOG=log_${NOM_BASE}_${COD_TYP_DETECT}_${GEN_TIMESTAMP}


echo "  >   Debut de l'execution du programme"  


 # repertoire de log
if  ! test -d ${DIR_FIC_LOG}
then
  echo "  >>>   Creation du repertoire ${DIR_FIC_LOG}"
  mkdir ${DIR_FIC_LOG}
fi

   # fichier ressource (code retour sql)

FIC_SQL_LOG=${DIR_FIC_LOG}/${NOM_BASE}_sql.log

number=0
number=`ls ${DIR_FIC_LOG} | grep  "${BASE_FIC_LOG}*" | wc -l`

if [ $number -ne 0 ];
then
  number=$(( ++number ))
  echo "  >>>   Fichier avec masque ${FIC_LOG} existant"  
  FIC_LOG=${DIR_FIC_LOG}/${BASE_FIC_LOG}_${number}.log
else
  FIC_LOG=${DIR_FIC_LOG}/${BASE_FIC_LOG}.log
fi

echo "  >>>   Fichier LOG SQL cree  -> ${FIC_SQL_LOG}"
echo "  >>>   Fichier LOG cree  -> ${FIC_LOG}"


    #  cr ation du repertoire d'archive des vets
if  ! test -d ${DIR_FIC_IN}
then
  echo "  >>>   Creation du repertoire ${DIR_FIC_IN}"
  echo -e "   >>>   Creation du repertoire ${DIR_FIC_IN}">> $FIC_LOG
  mkdir ${DIR_FIC_IN}
fi


    #  cr ation du repertoire d'archive des vets en sortie
if  ! test -d ${DIR_FIC_SORTIE_IN}
then
  echo "  >>>   Creation du repertoire ${DIR_FIC_SORTIE_IN}"
  echo -e "   >>>   Creation du repertoire ${DIR_FIC_V_IN}">> $FIC_LOG
  mkdir ${DIR_FIC_SORTIE_IN}
fi


    #  cr ation du repertoire de sortie
if  ! test -d ${DIR_FIC_SORTIE}
then
  echo "  >>>   Creation du repertoire ${DIR_FIC_SORTIE}"
  echo -e "  >>>   Creation du repertoire  ${DIR_FIC_SORTIE}">> "$FIC_LOG" 2>&1
  mkdir ${DIR_FIC_SORTIE}
fi


  # cr ation du repertoire de depot des vet si type detection = LISTES_VET
if  ! test -d ${DIR_FIC_VET_IN} && test ${COD_TYP_DETECT} = 'LISTES_VET'
then
  echo "  >>>   ${DIR_FIC_VET_IN} inexistant"
  echo "  >>>   Creation du repertoire ${DIR_FIC_VET_IN}"
  echo -e "  >>>   Creation du repertoire ${DIR_FIC_VET_IN}" >> "$FIC_LOG" 2>&1
  mkdir ${DIR_FIC_VET_IN}
  echo "  >>>   Veuillez ajouter votre filtre formation dans ${DIR_FIC_VET_IN}"
  exit
fi


    # cr ation du repertoire de tmp
if  ! test -d ${DIR_FIC_TMP}
then
  echo "  >>>   ${DIR_FIC_TMP} inexistant"
  echo "  >>>   Creation du repertoire ${DIR_FIC_TMP}"
  echo -e "  >>>   Creation du repertoire ${DIR_FIC_TMP}">> "$FIC_LOG" 2>&1
  mkdir ${DIR_FIC_TMP}
fi


number=0
number=`ls ${DIR_FIC_SORTIE} | grep  "${FIC_NAME_APOGEE_INSERT}*" | wc -l`

if [ $number -ne 0 ];
then
  number=$(( ++number ))
  echo "  >>>   Fichier avec masque ${FIC_NAME_APOGEE_INSERT} existant"  
  FIC_NAME_APOGEE_INSERT=${FIC_NAME_APOGEE_INSERT}_${number}.dat
else
  FIC_NAME_APOGEE_INSERT=${FIC_NAME_APOGEE_INSERT}.dat
fi
echo "  >>>   Fichier DAT cree  -> ${FIC_NAME_APOGEE_INSERT}"

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

# --------------------------------------------
# PURGE DE FICHIERS PRECEDENTS
# --------------------------------------------

test -r $FIC_SQL_LOG && rm $FIC_SQL_LOG

# -----------------------------------------
# initialisation de la log
# (capture erreurs possible)
# -----------------------------------------

echo -e "------------------------------------------------------" > $FIC_LOG
echo -e "Debut de $0 :" >> $FIC_LOG
date '+%d/%m/%Y a %H:%M' >> $FIC_LOG
echo -e "------------------------------------------------------" >> $FIC_LOG

# -----------------------------------------
# droits en ecriture a la log
# -----------------------------------------

echo -e "  >>>   droits en ecriture a la log" >> $FIC_LOG
chmod go+w $FIC_LOG


if  test ${COD_TYP_DETECT} = 'VET'
then

	echo "${COD_OBJ}" > ${DIR_FIC_TMP}/${FIC_NAME_TMP}	
	
       for i in  $(cat < `find ${DIR_FIC_TMP}/${FIC_NAME_TMP} -maxdepth 1 -type f -not -path '*/\.*' | sort`); do 

		for line in  ${i//,/ };
		do
   		   # verification du format des codes pegases
  		   if [[ $line == *">"* ]]; then
     				echo "  >>>   Formation valide: $line" >> $FIC_LOG
    				echo -e "  >>>   Filtre formation valide : $line" 

   		   else

   		      # si erreur
   		      echo "  >>>   Filtre formation invalide : $line" >> $FIC_LOG
   		      echo -e "  >>>   Filtre formation invalide : $line"
		      echo -e "  >>>   Modifiez le filtre !!!!!!"
   		      exit
  		   fi
	done

done


fi


# ---------------------------------------------------------------------
# ETAPE 2.5 (cas LISTES_VET)  : CHARGEMENT DU FICHIER DES CODES PEGASES
# ---------------------------------------------------------------------

if test ${COD_TYP_DETECT} = 'LISTES_VET'
then

number=0
number=`ls ${DIR_FIC_VET_IN} | wc -l` 
if [ $number  -eq  0 ];
then
  echo "  >>>   Pas de filtre dans  ${DIR_FIC_VET_IN}"
  exit
fi


echo -e "  >>>    Debut du test des codes formations ">> $FIC_LOG

echo "  >>>  Debut du test des codes formations "
sleep 1

 echo -e "  >>>   Test de(s) formation(s)" >> $FIC_LOG



for i in  $(cat < `find ${DIR_FIC_VET_IN} -maxdepth 1 -type f -not -path '*/\.*' | sort`); do 

for line in  ${i//,/ };
do
   # verification du format des codes pegases
   if [[ $line == *">"* ]]; then
     echo "  >>>   Formation valide: $line" >> $FIC_LOG
     echo -e "  >>>   Filtre formation valide : $line" 

   else

   # si erreur
    echo "  >>>   Filtre formation invalide : $line" >> $FIC_LOG
    echo -e "  >>>   Filtre formation invalide : $line"
    echo -e "  >>>   Modifiez le filtre !!!!!!"
    exit

   fi


done



  done

  echo -e "  >>>  Fin du test des codes formations ">> $FIC_LOG
  echo "  >>>   Fin du test des codes formations "
  sleep 1

  echo -e "  >>>   Debut du traitement de la g n ration des etapes pour LISTES_VET ">> $FIC_LOG
  echo -e "  >>>   Debut du traitement de la g n ration des etapes pour LISTES_VET  "
  sleep 1


for i in  $(cat < `find ${DIR_FIC_VET_IN} -maxdepth 1 -type f -not -path '*/\.*' | sort`); do 




for line in  ${i//,/ };
do

  # copie du fichier dans le fichier temporaire
  echo ${line} >> ${DIR_FIC_TMP}/${FIC_NAME_TMP}

done
  echo -e "  >>>   Fin du traitement de la g n ration des etapes pour LISTES_VET ">> $FIC_LOG
  echo "  >>>   Fin du traitement de la g n ration des etapes pour LISTES_VET  "
  sleep 1
done

fi


# ---------------------------------------------------------------------------
# ETAPE 2.5 (cas CMP, VETALL, VET)  : CHARGEMENT DU FICHIER DES CODES PEGASES
# ---------------------------------------------------------------------------

if test ${COD_TYP_DETECT} = 'CMP' || test ${COD_TYP_DETECT} = 'VETALL'
then

echo -e "  >>>   Debut du traitement de la g n ration des etapes pour cmp ou vetall ou vet ">> $FIC_LOG
echo "  >>>   Debut du traitement de la g n ration des etapes pour cmp ou vetall ou vet "
sleep 1


sqlplus -s <<FIN_SQL 
${STR_CONX}
set serveroutput on
SET HEADING OFF
SET FEEDBACK OFF
-- linesize :
--    + cod_dip		7
--    + cod_vrs_vdi	3
--    + cod_etp		6
--    + cod_vrs_vet	3
--	  + "-"			2
--	  + ">"			1
--	  ===============
--					22 caractères => 25 par sécurité
set linesize 25
set pagesize 1
VARIABLE ret_code NUMBER
BEGIN

DECLARE
	linebuffer		varchar2(25) := '';
	type_recherche	varchar2(200) := '${COD_TYP_DETECT}';
	cod_cmp_in		varchar2(6) := '${COD_OBJ}';
	cod_anu_in		INS_ADM_ANU.COD_ANU%TYPE := '${COD_ANU}';
	cod_etp_in		ETAPE.COD_ETP%TYPE := '${COD_OBJ}';
	cod_vrs_vet_in	VERSION_ETAPE.COD_VRS_VET%TYPE := '${COD_VRS_OBJ}';
	
	-- utl file config
	repertoire varchar2(100) := '${DIRECTORY}';
   	fichier varchar2(100) := '${FIC_NAME_TMP}';
	fichier_sortie UTL_FILE.FILE_TYPE;

	-- curseur de recherche de VET et VDI par CMP
	cursor main_by_cmp_cur(cod_cmp_in varchar2, cod_anu_in IN varchar2)
       is
       SELECT  vrl.cod_etp,
      		 vrl.cod_vrs_vet,
	       vde.cod_dip,
		vde.cod_vrs_vdi
      	 FROM  version_etape vet,
	       VDI_FRACTIONNER_VET vde,
		VET_REGROUPE_LSE vrl
	 WHERE vde.COD_ETP = vet.COD_ETP 
	   AND vde.cod_vrs_vet = vet.cod_vrs_vet 
	   AND vde.daa_deb_val_vet <= cod_anu_in
	   AND vde.daa_fin_val_vet >= cod_anu_in	
	   AND vrl.COD_ETP = vde.COD_ETP 
	   AND vrl.cod_vrs_vet = vde.COD_VRS_VET 
	   AND vet.cod_cmp = cod_cmp_in
	GROUP BY vrl.cod_etp,
      		 vrl.cod_vrs_vet,
      		 vde.cod_dip,
      		 vde.cod_vrs_vdi,
      		 vet.cod_cmp,
      		 vrl.cod_lse;

      -- curseur de recherche de VET et VDI par annee (toutes les vets)
      cursor main_by_vet_cur(cod_anu_in in varchar2)
      is
      SELECT  vrl.cod_etp,
      		vrl.cod_vrs_vet,
	       vde.cod_dip,
		vde.cod_vrs_vdi
     	 FROM  version_etape vet,
		VDI_FRACTIONNER_VET vde,
		VET_REGROUPE_LSE vrl
	 WHERE vde.COD_ETP = vet.COD_ETP 
	   AND vde.cod_vrs_vet = vet.cod_vrs_vet 
	   AND vde.daa_deb_val_vet <= cod_anu_in
	   AND vde.daa_fin_val_vet >= cod_anu_in	
	   AND vrl.COD_ETP = vde.COD_ETP 
	   AND vrl.cod_vrs_vet = vde.COD_VRS_VET 
	 GROUP BY vrl.cod_etp,
      		 vrl.cod_vrs_vet,
      		 vde.cod_dip,
      		 vde.cod_vrs_vdi;

   BEGIN
 	
	IF type_recherche = 'CMP'
	then
		for main_by_cmp_rec in  main_by_cmp_cur(cod_cmp_in, cod_anu_in)
		loop
		  fichier_sortie  := utl_file.fopen(repertoire, fichier, 'A');
		  linebuffer := main_by_cmp_rec.cod_dip || '-' || main_by_cmp_rec.cod_vrs_vdi ||'>' ||main_by_cmp_rec.cod_etp ||'-' ||  main_by_cmp_rec.cod_vrs_vet ;
		  utl_file.put_line(fichier_sortie,linebuffer);
		  utl_file.fclose(fichier_sortie);
		end loop;
	end if;
	if type_recherche = 'VETALL' 
	then
	    for main_by_vet_rec in main_by_vet_cur(cod_anu_in)
	    loop
		 fichier_sortie  := utl_file.fopen(repertoire, fichier, 'A');
		 linebuffer := main_by_vet_rec.cod_dip || '-' ||main_by_vet_rec.cod_vrs_vdi ||'>' ||   main_by_vet_rec.cod_etp ||'-' || main_by_vet_rec.cod_vrs_vet;
		 utl_file.put_line(fichier_sortie,linebuffer);
		 utl_file.fclose(fichier_sortie);
	    end loop;
	end if;
		
   END;
END;
/
PRINT 
EXIT
FIN_SQL

echo -e "  >>>   Fin du traitement de la g n ration des etapes pour cmp et vetall ">> $FIC_LOG
echo "  >>>   Fin du traitement de la g n ration des etapes pour cmp et vetall "

fi

sleep 1
echo "  >>>   Suppression des espaces vides"
# suppresion des espaces vides
if test ${COD_TYP_DETECT} = 'CMP' || test ${COD_TYP_DETECT} = 'VETALL'
then
 awk 'NF > 0'  ${path_directory}/${FIC_NAME_TMP} > ${DIR_FIC_TMP}/temp
 rm  -f ${path_directory}/${FIC_NAME_TMP} 
 cp ${DIR_FIC_TMP}/temp ${DIR_FIC_TMP}/${FIC_NAME_TMP}
 rm ${DIR_FIC_TMP}/temp
fi
sleep 1

COUNT_VET=`wc -l < ${DIR_FIC_TMP}/${FIC_NAME_TMP}`
if [ $COUNT_VET -ne 0 ]
then
	
	echo "  >>>   Presence de VET dans le fichier"

else
	echo "  >>>   Pas de VET dans le fichier"
 	exit
fi


#récupération de la 1ere ligne du fichier temporaire
# (toutes les VDI seront récupérées au travers du curseur principal)

# bouclage sur la liste des vets dans le fichier temporaire
while read ligne 
do

ligne_etp=`echo $ligne | cut -f 2 -d ">"`


COD_OBJ_FIC=`echo $ligne_etp | cut -f 1 -d "-"`
COD_VRS_OBJ=`echo $ligne_etp | cut -f 2 -d "-"`

echo -e "  >>>   Debut du traitement pour la code formation pegase :  $ligne  ">> $FIC_LOG
echo  "  >>>     Traitement pour la VET :  ${COD_OBJ_FIC} - ${COD_VRS_OBJ} "
## --------------------------------------------
# ETAPE 3 : TRAITEMENT DES VALEURS
# --------------------------------------------

## --------------------------------------------
# ETAPE 3 1  : generation des vacs apogees
# --------------------------------------------

echo -e "  >>>   Debut du traitement de la g n ration des cles vac " >> $FIC_LOG

# recherche des resultats et des prc pour chaque VET pour chaque etudiant inscrit sur cette ann e (iae en cours)
sqlplus -s <<FIN_SQL 
${STR_CONX}
set serveroutput on
SET HEADING OFF
SET FEEDBACK OFF
-- linesize :
--      cod_anu		4
--    + cod_ind		8
--    + cod_etp		6
--    + cod_vrs_vet	3
--    + cod_elp		8
--    +'SYSDATE'	7
--    + cod_cip_vet	4 (valeur la + grande entre taille cod_cip et NULL)=>
--    + note		9 (5chiffres + "," + 3décimales)
--    + bareme		5
--	  + ";"			9
--	  ===============
--					63 caractères => 70 par sécurité
set linesize 70
set pagesize 1
VARIABLE ret_code NUMBER
BEGIN

DECLARE
	--initialisation des variables
	linebuffer		varchar2(70) := '';
	count_ide		number(8,0) := 0;

	cod_etp_in		ETAPE.cod_etp%TYPE := '${COD_OBJ_FIC}';
	cod_vrs_vet_in	VERSION_ETAPE.cod_vrs_vet%TYPE := '${COD_VRS_OBJ}';
	cod_anu_in		INS_ADM_ANU.cod_anu%TYPE :='${COD_ANU}';
	cod_cip_vet 	IND_CONTRAT_ELP.cod_cip%TYPE := '';
	
	-- utl file config
	repertoire  varchar2(100)       := '${DIRECTORY}';
   	fichier varchar2(100)           := '${FIC_NAME_APOGEE_INSERT}';
	fichier_sortie UTL_FILE.FILE_TYPE;
		
	-- recuperation des prc
   CURSOR recherche_prc_cur (cod_etp_in IN varchar2, cod_vrs_vet_in IN varchar2,cod_anu_in IN varchar2)
		IS
		SELECT ice.cod_anu,
				 ice.cod_etp,
				 ice.cod_vrs_vet,
				 ice.cod_ind,
				 ice.cod_elp,
				 vde.cod_dip,
				 vde.cod_vrs_vdi,
				 ice.tem_prc_ice,
				 elp.cod_nel,
				 ice.cod_lcc_ice,
                 to_char(max(relp.not_elp)) note, to_char(max(relp.bar_not_elp)) bareme
		FROM  element_pedagogi elp,
		 	   ind_contrat_elp ice,
		      vdi_fractionner_vet vde,
              resultat_elp relp
		WHERE ice.cod_etp = cod_etp_in
		AND ice.cod_vrs_vet = cod_vrs_vet_in
		AND elp.cod_elp = ice.COD_ELP
		AND ice.cod_elp = elp.cod_elp
		AND vde.cod_etp = ice.cod_etp
		AND vde.cod_vrs_vet = ice.cod_vrs_vet
		AND ice.tem_prc_ice = 'O'
		AND ice.cod_anu = cod_anu_in
        -- exclusion des validation d'acquis
        AND not exists (
            SELECT 1
            FROM ind_dispense_elp ide
            WHERE ide.cod_anu=ice.cod_anu
                AND ide.cod_ind=ice.cod_ind
                AND ide.cod_etp=ice.cod_etp
                AND ide.cod_vrs_vet=ice.cod_vrs_vet
                AND ide.cod_elp=ice.cod_elp
			)
        AND relp.cod_elp = ice.cod_elp
        AND relp.cod_ind =  ice.cod_ind
	    AND relp.cod_anu < ice.cod_anu
	    AND relp.not_elp IS NOT NULL AND relp.bar_not_elp IS NOT null AND relp.cod_adm = 1
		group by ice.cod_anu,
				 ice.cod_etp,
				 ice.cod_vrs_vet,
				 ice.cod_ind,
				 ice.cod_elp,
				 vde.cod_dip,
				 vde.cod_vrs_vdi,
				 ice.tem_prc_ice,
				 elp.cod_nel,
				 ice.cod_lcc_ice ;
						
   BEGIN
	-- recherche du cip de la vet
	SELECT DISTINCT FIRST_VALUE(cod_cip) OVER (ORDER BY COD_ETP) cod_cip
	INTO cod_cip_vet
	FROM vet_cip
	WHERE cod_etp = cod_etp_in
	  AND cod_vrs_vet = cod_vrs_vet_in;
	
	-- RECHERCHE PAR PRC
	FOR recherche_prc_rec IN recherche_prc_cur(cod_etp_in,cod_vrs_vet_in,cod_anu_in)
	LOOP
			fichier_sortie  := utl_file.fopen(repertoire, fichier, 'A');
			linebuffer := ''||REPLACE(cod_anu_in,'',NULL)||';'||REPLACE(recherche_prc_rec.cod_ind,'',NULL)||';'||REPLACE(recherche_prc_rec.cod_etp,'',NULL)||';'||REPLACE(recherche_prc_rec.cod_vrs_vet,'NULL',NULL)||';'||REPLACE(recherche_prc_rec.cod_elp,'','NULL')||';SYSDATE;'||REPLACE(cod_cip_vet,'','NULL')||';' ||recherche_prc_rec.note|| ';' ||recherche_prc_rec.bareme ||';';
			utl_file.put_line(fichier_sortie,linebuffer);
			utl_file.fclose(fichier_sortie);
	END LOOP;
	
   	
   END;
  	
END;
/
EXIT
FIN_SQL

echo -e "  >>>   Fin du traitement de la g n ration des cles vac" >> $FIC_LOG


 >> $FIC_LOG
done < ${DIR_FIC_TMP}/${FIC_NAME_TMP} | sort -u

sleep 1

echo -e "  >>>   Debut de la suppression des espaces vides dans les fichiers finaux"
echo -e "  >>>   Debut de la suppression des espaces vides dans les fichiers finaux" >> $FIC_LOG

echo -e "  >>>   Debut de la suppression des espaces vides dans le fichier insert"
echo -e "  >>>   Debut de la suppression des espaces vides dans le fichier insert">> $FIC_LOG


if [ ! -e ${path_directory}/${FIC_NAME_APOGEE_INSERT} ];
then
	echo -e "  >>>   Erreur fichier"
	echo -e "  >>>   Pas de Vac"
	
	exit

fi

awk 'NF > 0' ${path_directory}/${FIC_NAME_APOGEE_INSERT}  >> ${DIR_FIC_TMP}/cle_tmp.dat
rm -f ${path_directory}/${FIC_NAME_APOGEE_INSERT}
echo '' >> ${DIR_FIC_TMP}/cle_tmp.dat
cp ${DIR_FIC_TMP}/cle_tmp.dat ${DIR_FIC_SORTIE}/${FIC_NAME_APOGEE_INSERT} 
#rm -f ${DIR_FIC_TMP}/cle_tmp.dat

echo -e "  >>>   Fin de la suppression des espaces vides dans le fichier insert"
echo -e "  >>>   Fin de la suppression des espaces vides dans le fichier insert"  >> $FIC_LOG
sleep 1

echo -e "  >>>   Fin de la suppression des espaces vides dans les fichiers finaux"
echo -e "  >>>   Fin de la suppression des espaces vides dans les fichiers finaux" >> $FIC_LOG
sleep 1

echo -e "  >>>   Copie du fichier temporaire dans le dossier archive"
echo -e "  >>>   Copie du fichier temporaire dans le dossier archive" >> $FIC_LOG

number=0
number=`cat ${DIR_FIC_SORTIE}/${FIC_NAME_APOGEE_INSERT} | wc -l` 

if [ $number -le 1 ] ;
then
	echo -e "     "
	echo -e "  >>>   Pas de VAC TROUVEE pour ces parametres !!!"
	echo -e "  	   |-> Suppression du fichier ${FIC_NAME_APOGEE_INSERT} !!!"
	echo -e "     "
	rm ${DIR_FIC_SORTIE}/${FIC_NAME_APOGEE_INSERT}

fi

sleep 1

number=0
number=`ls ${DIR_FIC_IN} | grep  "${vet_archive}*" | wc -l`

if [ $number -ne 0 ];
then
  number=$(( ++number ))
  echo "  >>>   Fichier avec masque ${vet_archive} existant"  
  archive_fic=${DIR_FIC_SORTIE_IN}/${vet_archive}_${number}.txt
else
  archive_fic=${DIR_FIC_SORTIE_IN}/${vet_archive}.txt
fi

echo "  >>>   Fichier des vets cree  -> ${archive_fic}"




cp ${DIR_FIC_TMP}/${FIC_NAME_TMP} ${archive_fic}
sleep 1
echo -e "  >>>   Suppression du dossier tmp"
rm -r  ${DIR_FIC_TMP}

sleep 1

 echo "  >   Fin de l'execution du programme"  

# -----------------------------------------
# Fin du programme
# -----------------------------------------

echo -e "Fin normale de $0 :\n" >> $FIC_LOG
