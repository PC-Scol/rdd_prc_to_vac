# 
# Auteurs : j-luc.nizieux@uca.fr
#	     tristan.blanc@uca.fr 
# 
# SPDX-License-Identifier: AGPL-3.0-or-later
# License-Filename: LICENSE


# -----------------------------------------------------------------------------
# create_lcc.sh: Generation des LCC pour les objets
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
echo "    >>>     Code Année universitaire : ${COD_ANU}"		        			
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

     #FICHIER INI (chemin à ajouter)
FIC_INI=${DIR_FIC_ARCH}/rdd_vac.ini

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

#Modification  Directory

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
    # Code element pédagogique
COD_OBJ=`grep "^COD_OBJ" $FIC_INI | cut -d\: -f2`
    # Code version element pédagogique
COD_VRS_OBJ=`grep "^COD_VRS_OBJ" $FIC_INI | cut -d\: -f2`

    # repertoires de depot et d'archive
FIC_NAME_APOGEE=`grep "^FIC_NAME_APOGEE" $FIC_INI | cut -d\: -f2`

    # repertoire depot du filtre de formation pour LISTE_VET
FIC_NAME_FILTRE=`grep "^FIC_NAME_FILTRE" $FIC_INI | cut -d\: -f2`

PDB=`printenv | grep ^TWO_TASK= | cut -d\= -f2`

 # Appel du menu
confirm_menu


#  Vérification existance du dossier log
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


if [[  -z ${PDB} ]]
then
  PDB=FIC_NAME_FILTRE=`grep "^PDB" $FIC_INI | cut -d\: -f2`
  if [[  -z ${PDB} ]]
  then
  	echo "Probleme PDB ou TWO_TASK"
       exit
  fi
fi


    # generation timestamp pour les fichiers
GEN_TIMESTAMP=$(date -I)

    # Fichier de stockage SQL pour requete generation des cles LCC dans APOGEE
FIC_NAME_CLE_LCC_APOGEE=cle_lcc_${COD_ANU}_${COD_TYP_DETECT}_${COD_OBJ}_${GEN_TIMESTAMP}

    # Fichier de stockage SQL pour requete generation des LCC
FIC_NAME_APOGEE_LCC=lcc_${COD_ANU}_${COD_TYP_DETECT}_${COD_OBJ}_${GEN_TIMESTAMP}


    # Fichier de stockage temporaire des VETS
FIC_NAME_TMP=vets.tmp
vet_archive=vets_lcc_${COD_ANU}_${COD_TYP_DETECT}_${COD_OBJ}_${GEN_TIMESTAMP}

 # log du programme
BASE_FIC_LOG=log_lcc_${NOM_BASE}_${COD_TYP_DETECT}_${COD_OBJ}_${GEN_TIMESTAMP}


path_directory=`sqlplus -s ${STR_CONX} <<EOF
set pages 0
set head off
set feed off
SELECT directory_path
	  FROM dba_directories
	 WHERE directory_name = '${DIRECTORY}';
exit
EOF`



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


    #  création du repertoire d'archive des vets
if  ! test -d ${DIR_FIC_IN}
then
  echo "  >>>   Creation du repertoire ${DIR_FIC_IN}"
  echo -e "   >>>   Creation du repertoire ${DIR_FIC_IN}">> $FIC_LOG
  mkdir ${DIR_FIC_IN}
fi


    #  création du repertoire d'archive des vets en sortie
if  ! test -d ${DIR_FIC_SORTIE_IN}
then
  echo "  >>>   Creation du repertoire ${DIR_FIC_SORTIE_IN}"
  echo -e "   >>>   Creation du repertoire ${DIR_FIC_V_IN}">> $FIC_LOG
  mkdir ${DIR_FIC_SORTIE_IN}
fi


    #  création du repertoire de sortie
if  ! test -d ${DIR_FIC_SORTIE}
then
  echo "  >>>   Creation du repertoire ${DIR_FIC_SORTIE}"
  echo -e "  >>>   Creation du repertoire  ${DIR_FIC_SORTIE}">> "$FIC_LOG" 2>&1
  mkdir ${DIR_FIC_SORTIE}
fi


  # création du repertoire de depot des vet si type detection = LISTES_VET
if  ! test -d ${DIR_FIC_VET_IN} && test ${COD_TYP_DETECT} = 'LISTES_VET'
then
  echo "  >>>   ${DIR_FIC_VET_IN} inexistant"
  echo "  >>>   Creation du repertoire ${DIR_FIC_VET_IN}"
  echo -e "  >>>   Creation du repertoire ${DIR_FIC_VET_IN}" >> "$FIC_LOG" 2>&1
  mkdir ${DIR_FIC_VET_IN}
  echo "  >>>   Veuillez ajouter votre filtre formation dans ${DIR_FIC_VET_IN}"
  exit
fi


    # création du repertoire de tmp
if  ! test -d ${DIR_FIC_TMP}
then
  echo "  >>>   ${DIR_FIC_TMP} inexistant"
  echo "  >>>   Creation du repertoire ${DIR_FIC_TMP}"
  echo -e "  >>>   Creation du repertoire ${DIR_FIC_TMP}">> "$FIC_LOG" 2>&1
  mkdir ${DIR_FIC_TMP}
fi


number=`ls ${DIR_FIC_SORTIE} | grep  "${FIC_NAME_CLE_LCC_APOGEE}*" | wc -l`

if [ $number -ne 0 ];
then
  number=$(( ++number ))
  echo "  >>>   Fichier avec masque ${FIC_NAME_CLE_LCC_APOGEE} existant"  
  FIC_NAME_CLE_LCC_APOGEE=${FIC_NAME_CLE_LCC_APOGEE}_${number}.txt
else
  FIC_NAME_CLE_LCC_APOGEE=${FIC_NAME_CLE_LCC_APOGEE}.txt
fi
echo "  >>>   Fichier txt cree  -> ${FIC_NAME_CLE_LCC_APOGEE}"



number=0
number=`ls ${DIR_FIC_SORTIE} | grep  "${FIC_NAME_APOGEE_LCC}*" | wc -l`

if [ $number -ne 0 ];
then
  number=$(( ++number ))
  echo "  >>>   Fichier avec masque ${FIC_NAME_APOGEE_LCC} existant"  
  FIC_NAME_APOGEE_LCC=${FIC_NAME_APOGEE_LCC}_${number}.csv
else
  FIC_NAME_APOGEE_LCC=${FIC_NAME_APOGEE_LCC}.csv
fi
echo "  >>>   Fichier txt cree  -> ${FIC_NAME_APOGEE_LCC}"

sleep 1
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
   
   fi


done



  done

  echo -e "  >>>  Fin du test des codes formations ">> $FIC_LOG
  echo "  >>>   Fin du test des codes formations "
  sleep 1

  echo -e "  >>>   Debut du traitement de la génération des etapes pour LISTES_VET ">> $FIC_LOG
  echo -e "  >>>   Debut du traitement de la génération des etapes pour LISTES_VET  "
  sleep 1


for i in  $(cat < `find ${DIR_FIC_VET_IN} -maxdepth 1 -type f -not -path '*/\.*' | sort`); do 




for line in  ${i//,/ };
do

  # copie du fichier dans le fichier temporaire
  echo ${line} >> ${DIR_FIC_TMP}/${FIC_NAME_TMP}

done
  echo -e "  >>>   Fin du traitement de la génération des etapes pour LISTES_VET ">> $FIC_LOG
  echo "  >>>   Fin du traitement de la génération des etapes pour LISTES_VET  "
  sleep 1
done

fi



# ---------------------------------------------------------------------------
# ETAPE 2.5 (cas CMP, VETALL, VET)  : CHARGEMENT DU FICHIER DES CODES PEGASES
# ---------------------------------------------------------------------------

if test ${COD_TYP_DETECT} = 'CMP' || test ${COD_TYP_DETECT} = 'VETALL' || test ${COD_TYP_DETECT} = 'VET'
then

echo -e "  >>>   Debut du traitement de la génération des etapes pour cmp ou vetall ou vet ">> $FIC_LOG
echo "  >>>   Debut du traitement de la génération des etapes pour cmp ou vetall ou vet "
sleep 1

$ORACLE_HOME/bin/sqlplus -s <<FIN_SQL 
${STR_CONX}
set serveroutput on
SET HEADING OFF
SET FEEDBACK OFF
set pagesize 1
VARIABLE ret_code NUMBER
BEGIN

DECLARE
	linebuffer varchar2(20000) := '';
	cod_anu_in varchar2(200) := '${COD_ANU}';
	cod_cmp_in varchar2(200) := '${COD_OBJ}';
	type_recherche varchar2(200) := '${COD_TYP_DETECT}';
	cod_etp_in  varchar2(200) := '${COD_OBJ}';
	cod_vrs_vet_in  varchar2(200) := '${COD_VRS_OBJ}';
	
	-- utl file config
	repertoire  varchar2(100)  := '${DIRECTORY}';
   	fichier  varchar2(100)     := '${FIC_NAME_TMP}';
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
      		 vet.cod_cmp;

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

	-- curseur de recherche de VET et VDI par VET
      cursor main_vet_in_cur(cod_etp_in in varchar2, cod_vrs_vet_in in varchar2,cod_anu_in in varchar2)
      is
      SELECT  vrl.cod_etp,
      		vrl.cod_vrs_vet,
	       vde.cod_dip,
		vde.cod_vrs_vdi
     	 FROM  version_etape vet,
		VDI_FRACTIONNER_VET vde,
		VET_REGROUPE_LSE vrl
	 WHERE vet.cod_etp = cod_etp_in
          AND vet.cod_vrs_vet = cod_vrs_vet_in
          AND vde.COD_ETP = vet.COD_ETP 
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
		  linebuffer := main_by_cmp_rec.cod_dip || '-' || main_by_cmp_rec.cod_vrs_vdi ||'>' ||main_by_cmp_rec.cod_etp ||'-' ||  main_by_cmp_rec.cod_vrs_vet ||chr(10);
		  fichier_sortie  := utl_file.fopen(repertoire, fichier, 'A');
	    	  utl_file.put_line(fichier_sortie,linebuffer );
	         utl_file.fclose(fichier_sortie);
		end loop;
	end if;
	if type_recherche = 'VETALL' 
	then
	    for main_by_vet_rec in main_by_vet_cur(cod_anu_in)
	    loop
		 linebuffer := main_by_vet_rec.cod_dip || '-' ||main_by_vet_rec.cod_vrs_vdi ||'>' ||   main_by_vet_rec.cod_etp ||'-' || main_by_vet_rec.cod_vrs_vet||chr(10);
		 fichier_sortie  := utl_file.fopen(repertoire, fichier, 'A');
		 utl_file.put_line(fichier_sortie,linebuffer );
		 utl_file.fclose(fichier_sortie);

	    end loop;
	end if;
	if type_recherche = 'VET'
	then
	    for main_vet_in_rec in main_vet_in_cur(cod_etp_in,cod_vrs_vet_in,cod_anu_in)
	    loop
		 linebuffer := linebuffer || main_vet_in_rec.cod_dip || '-' ||main_vet_in_rec.cod_vrs_vdi ||'>' ||  main_vet_in_rec.cod_etp ||'-' || main_vet_in_rec.cod_vrs_vet||chr(10);
	    end loop;
	    fichier_sortie  := utl_file.fopen(repertoire, fichier, 'A');
	    utl_file.put_line(fichier_sortie,linebuffer );
	    utl_file.fclose(fichier_sortie);
	end if;


		
   END;
END;
/
EXIT
FIN_SQL

echo -e "  >>>   Fin du traitement de la génération des etapes pour cmp et vetall ">> $FIC_LOG
echo "  >>>   Fin du traitement de la génération des etapes pour cmp et vetall "

fi

sleep 1
echo "  >>>   Suppression des espaces vides"
# suppresion des espaces vides
awk 'NF > 0'  ${path_directory}/${FIC_NAME_TMP} > ${DIR_FIC_TMP}/temp
rm -f ${path_directory}/${FIC_NAME_TMP} 
cp ${DIR_FIC_TMP}/temp ${DIR_FIC_TMP}/${FIC_NAME_TMP}
rm ${DIR_FIC_TMP}/temp
sleep 1

COUNT_VET=`wc -l < ${DIR_FIC_TMP}/${FIC_NAME_TMP}`
if [ $COUNT_VET -ne 0 ]
then
	
	echo "  >>>   Présence de VET dans le fichier"

else
	echo "  >>>   Pas de VET dans le fichier"
 	exit
fi



# bouclage sur la liste des vets dans le fichier temporaire
while read ligne 
do

ligne_etp=`echo $ligne | cut -f 2 -d ">"`


COD_OBJ_FIC=`echo $ligne_etp | cut -f 1 -d "-"`
COD_VRS_OBJ=`echo $ligne_etp | cut -f 2 -d "-"`

echo -e "  >>>   Debut du traitement pour la code formation pegase :  $ligne  ">> $FIC_LOG
echo  "  >>>     Traitement pour la VET :  ${COD_OBJ_FIC} ${COD_VRS_OBJ} "

## --------------------------------------------
# ETAPE 3 : TRAITEMENT DES VALEURS
# --------------------------------------------

## --------------------------------------------
# ETAPE 3 1  : generation des clés lccs
# --------------------------------------------

echo -e "  >>>   Mise en place de l'entete ">> $FIC_LOG




echo -e "  >>>   Debut du traitement du fichier  clée des LCCs " >> $FIC_LOG

# recherche des clés lcc pour la demande
sqlplus -s <<FIN_SQL 
${STR_CONX}
set serveroutput on
SET HEADING OFF
SET FEEDBACK OFF
set pagesize 1
VARIABLE ret_code NUMBER
BEGIN

DECLARE
	--initialisation des variables
	cod_etp_in varchar2(2000) := '${COD_OBJ_FIC}';
	cod_vrs_vet_in varchar2(2000) := '${COD_VRS_OBJ}';
	cod_anu_in varchar2(2000) :='${COD_ANU}';
	linebuffer varchar2(20000) := '';
	commentaire varchar2(20000) := 'LCC generique';
	isActive varchar2(20000) := 'O';

	-- utl file config
	repertoire  varchar2(100)  := '${DIRECTORY}';
   	fichier  varchar2(100)     := '${FIC_NAME_CLE_LCC_APOGEE}';
	fichier_sortie UTL_FILE.FILE_TYPE;

	
	-- recuperation des lcc
   CURSOR recherche_lcc_cur (cod_etp_in IN varchar2, cod_vrs_vet_in IN varchar2,cod_anu_in IN varchar2)
		IS
		SELECT	ice.cod_lcc_ice
		FROM  element_pedagogi elp,
		 	   ind_contrat_elp ice,
		      vdi_fractionner_vet vde,
		      elp_correspond_elp ece
		WHERE ice.cod_etp = cod_etp_in
		AND ice.cod_vrs_vet = cod_vrs_vet_in
		AND elp.cod_elp = ice.COD_ELP
		AND ice.cod_elp = elp.cod_elp
		AND vde.cod_etp = ice.cod_etp
		AND vde.cod_vrs_vet = ice.cod_vrs_vet
		AND ice.cod_lcc_ice IS NOT null	
		AND ice.cod_anu = cod_anu_in
		AND ece.cod_lcc = ice.cod_lcc_ice
		group BY ice.cod_lcc_ice;

   BEGIN
		
	-- RECHERCHE PAR LCC
	FOR recherche_lcc_rec IN recherche_lcc_cur(cod_etp_in,cod_vrs_vet_in,cod_anu_in)
	LOOP
		linebuffer := recherche_lcc_rec.cod_lcc_ice;	
		fichier_sortie  := utl_file.fopen(repertoire, fichier, 'A');
	       utl_file.put_line(fichier_sortie,linebuffer);
	       utl_file.fclose(fichier_sortie);	
	 				   
	END LOOP;
	
   	
   END;
  	
END;
/
EXIT
FIN_SQL

echo -e "  >>>   Fin du traitement de la génération clé des LCCs" >> $FIC_LOG


 >> $FIC_LOG
done < ${DIR_FIC_TMP}/${FIC_NAME_TMP} | sort -u

sleep 1

echo -e "  >>>   Debut de la suppression des espaces vides dans les fichiers finaux"
echo -e "  >>>   Debut de la suppression des espaces vides dans les fichiers finaux" >> $FIC_LOG

echo -e "  >>>   Debut de la suppression des espaces vides dans le fichier insert"
echo -e "  >>>   Debut de la suppression des espaces vides dans le fichier insert">> $FIC_LOG


awk 'NF > 0' ${path_directory}/${FIC_NAME_CLE_LCC_APOGEE}  > ${DIR_FIC_TMP}/insert_tmp.sql
rm  -f ${path_directory}/${FIC_NAME_CLE_LCC_APOGEE}
echo '' >> ${DIR_FIC_TMP}/insert_tmp.sql

cp ${DIR_FIC_TMP}/insert_tmp.sql  ${DIR_FIC_SORTIE}/${FIC_NAME_CLE_LCC_APOGEE}
awk -i inplace '!seen[$0]++' ${DIR_FIC_SORTIE}/${FIC_NAME_CLE_LCC_APOGEE} >> ${DIR_FIC_SORTIE}/${FIC_NAME_CLE_LCC_APOGEE}
rm ${DIR_FIC_TMP}/insert_tmp.sql

echo 'code objet formation cible;code objet formation source;actif O/N;commentaire (2000 caractÃ¨res max.)' > ${DIR_FIC_SORTIE}/${FIC_NAME_APOGEE_LCC}

while read ligne 
do

ligne_etp=`echo $ligne | cut -f 2 -d ">"`


COD_LCC=`echo $ligne_etp | cut -f 1 -d " "`



if [[ -z "${COD_LCC}" ]]
then
   	continue 
 fi

echo -e "  >>>   Debut du traitement pour la code formation pegase :  $ligne  ">> $FIC_LOG

## --------------------------------------------
# ETAPE 3 : TRAITEMENT DES VALEURS
# --------------------------------------------

## --------------------------------------------
# ETAPE 3 2  : generation des lccs
# --------------------------------------------

echo -e "  >>>   Mise en place de l'entete ">> $FIC_LOG




echo -e "  >>>   Debut du traitement du fichier des LCCs " >> $FIC_LOG





# recherche lcc dans ind_contrat_elp
sqlplus -s <<FIN_SQL 
${STR_CONX}
set serveroutput on
SET HEADING OFF
SET FEEDBACK OFF
set pagesize 1
VARIABLE ret_code NUMBER
BEGIN

DECLARE
	--initialisation des variables
	cod_lcc varchar2(2000) := '${COD_LCC}';
	cod_anu_in varchar2(2000) :='${COD_ANU}';
	linebuffer varchar2(10000) := '';
	commentaire varchar2(1) := NULL;
	isActive varchar2(20000) := 'O';
	
	-- utl file config
	repertoire  varchar2(100)  := '${DIRECTORY}';
   	fichier  varchar2(100)     := '${FIC_NAME_APOGEE_LCC}';
	fichier_sortie UTL_FILE.FILE_TYPE;

	
	-- recuperation des lcc
   CURSOR recherche_lcc_cur (cod_lcc_ice_in in varchar2)
		IS
		SELECT	ece.cod_elp_cible_lcc, ece.cod_elp_s1_lcc, ece.cod_elp_s2_lcc, ece.DAA_FIN_VAL_LCC
		FROM   elp_correspond_elp ece
		WHERE ece.cod_lcc = cod_lcc_ice_in
		group by ece.cod_elp_cible_lcc, ece.cod_elp_s1_lcc, ece.cod_elp_s2_lcc, ece.DAA_FIN_VAL_LCC;

   BEGIN
		
	-- RECHERCHE PAR LCC
	FOR recherche_lcc_rec IN recherche_lcc_cur(cod_lcc)
	LOOP
		IF recherche_lcc_rec.DAA_FIN_VAL_LCC is not null and recherche_lcc_rec.DAA_FIN_VAL_LCC > cod_anu_in
		then 
			isActive := 'N';
		end if;

		IF recherche_lcc_rec.COD_ELP_S1_LCC is not null
		then
			linebuffer := chr(10) || recherche_lcc_rec.cod_elp_cible_lcc ||';'||recherche_lcc_rec.COD_ELP_S1_LCC||';'||isActive||';'||commentaire;
			fichier_sortie  := utl_file.fopen(repertoire, fichier, 'A');
	       	utl_file.put_line(fichier_sortie,linebuffer);
	       	utl_file.fclose(fichier_sortie);

		end if;
		
		IF recherche_lcc_rec.COD_ELP_S2_LCC is not null
		then
			linebuffer := chr(10) || recherche_lcc_rec.cod_elp_cible_lcc ||';'||recherche_lcc_rec.COD_ELP_S2_LCC||';'||isActive||';'||commentaire;
			fichier_sortie  := utl_file.fopen(repertoire, fichier, 'A');
	       	utl_file.put_line(fichier_sortie,linebuffer);
	       	utl_file.fclose(fichier_sortie);
		end if;
			 				   
	END LOOP;
	
   END;
  	
END;
/
EXIT
FIN_SQL

echo -e "  >>>   Fin du traitement de la génération des LCCs" >> $FIC_LOG


 >> $FIC_LOG
done <  ${DIR_FIC_SORTIE}/${FIC_NAME_CLE_LCC_APOGEE} | sort -u






echo -e "  >>>   Fin de la suppression des espaces vides dans le fichier insert"
echo -e "  >>>   Fin de la suppression des espaces vides dans le fichier insert"  >> $FIC_LOG
sleep 1

cat ${path_directory}/${FIC_NAME_APOGEE_LCC}| tr -d "[:blank:]"  > ${DIR_FIC_TMP}/insert_tmp.sql
rm -f ${path_directory}/${FIC_NAME_APOGEE_LCC}


cp ${DIR_FIC_TMP}/insert_tmp.sql  ${DIR_FIC_SORTIE}/${FIC_NAME_APOGEE_LCC}
awk -i inplace '!seen[$0]++' ${DIR_FIC_SORTIE}/${FIC_NAME_APOGEE_LCC} >> ${DIR_FIC_SORTIE}/${FIC_NAME_APOGEE_LCC}
rm ${DIR_FIC_TMP}/insert_tmp.sql

sed -i '/^$/d'  ${DIR_FIC_SORTIE}/${FIC_NAME_APOGEE_LCC}
echo -e "  >>>   Fin de la suppression des espaces vides dans les fichiers finaux"
echo -e "  >>>   Fin de la suppression des espaces vides dans les fichiers finaux" >> $FIC_LOG
sleep 1

echo -e "  >>>   Copie du fichier temporaire dans le dossier archive"
echo -e "  >>>   Copie du fichier temporaire dans le dossier archive" >> $FIC_LOG

number=0
number=`cat ${DIR_FIC_SORTIE}/${FIC_NAME_APOGEE_LCC} | wc -l `

if [ $number -le 1 ];
then
	echo -e "     "
	echo -e "  >>>   Pas de LCC TROUVEE pour ces parametres !!!"
	echo -e "  	   |-> Suppression du fichier ${FIC_NAME_APOGEE_LCC} !!!"
	echo -e "     "
	rm ${DIR_FIC_SORTIE}/${FIC_NAME_APOGEE_LCC}

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
