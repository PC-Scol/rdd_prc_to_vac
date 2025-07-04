
> [!WARNING]
> Ce projet n'a pas encore atteint sa version stable. Il est donc sujet à des
> modifications incompatibles de temps à autres.

# RDD_VAC

## Contenu
Ce programme permet de générer des validations d'acquis d'expérience pour reprendre les PRC des années antérieurs.

    Le principe est d'aller chercher les PRC qui ne sont pas dans la table IND_DISPENSE_ELP afin de genérer des VAC. 
    Ces VAC permettent de garder la PRC dans une maquette applatie. 
    Elle permet de travailler sur une seule année universitaire sans perdre ces PRC qui sont presentes sur une autre année universitaire antérieur pour les diffèrents étudiants. 

## Prérequis
### Installation du client Oracle sqlplus
> [!WARNING]
> Sqlplus doit être installé sur le poste qui utilise ce projet 
> Cela peut être effectué
>   - soit au travers d'une installation "oracle server"
>	- soit au travers d'une installation "oracle client" instant-client. Exemple installation Debian 12 :
>		1. librairies prérequis : sudo apt-get install libaio1 libaio-dev
>		2. Installation du client : https://www.oracle.com/fr/database/technologies/instant-client/linux-x86-64-downloads.html

### Paramétrage du client Oracle sqlplus
> [!WARNING]
> Tous les éléments de connectique réseau Oracle doivent être paramétrés :
> 1. tnsnames.ora déclaré et utilisable par sqlplus
> 2. tnsnames.ora renseigné avec les éléments pour atteindre la PDB renseignée dans rdd_vac.ini (qui primera sur TWO_TASK)

### Paramétrage du répertoire de dépôt
> [!WARNING]
> Une fois connecté à la base Apogée sur laquelle l'outil va s'appuyer, creer un directory pour le dépôt des fichiers générés par l'outil

	CREATE OR REPLACE DIRECTORY my_dir_vac AS '/applications/apogee/apo_6_00/batch/fic/APOTPDB';
	GRANT READ, WRITE ON DIRECTORY my_dir_vac TO apogee;	

## Fichiers générés

Dans un premier temps, le programme génère six fichiers en sortie:

     vets_<code_annee>_<type>_xxx_date.txt : filtres formations traitees (Fichier TXT)

     log_rdd_vac_<code_annee>_<type>_xxx.log : log de rdd_vac.sh  en fonction de l'annee et du type d'execution (Fichier LOG)

     play_log_rdd_vac_<code_annee>_<type>_xxx.log : log de play_rdd_vac.sh  en fonction de l'annee et du type d'execution (Fichier LOG)

     cle_vac_<code_annee>_<type>_<code element>_xxx.dat : Fichier contenant les clés pour les VACS

     insert_CHC_vac_pivot_XXXX_XXXXX.csv : Fichier généré contenant les CHC (VACS) pour la base pivot (Fichier csv)

     insert_COC_vac_pivot_XXXX_XXXXX.csv : Fichier généré contenant les COC (VACS) pour la base pivot (Fichier csv)


## Utilisation
1. le programme fonctionne en utilisant plusieurs critères placés dans le fichier .ini  (ces données sont à remplir obligatoirement) :

        - le critère COD_ANU correspond à l'année universitaire que vous voulez reprendre (elle correspond à l'année de départ que vous voulez reprendre)
 
        - le critère COD_TYP_OBJ correspond aux types de détéction que vous voulez faire
 
            4 types de detections sont disponibles :
 
                - VET : pour une version d'étape (code etape et code version d'etape à renseigner dans le fichier)
				    A renseigner !!! :
					  -> COD_OBJ : sous la forme du filtre_formations de l'outillage de reprise de données pegase "COD_DIP-COD_VRS_VDI->ETP-COD_VRS_ETP
					 
                - CMP : pour toutes les versions d'étapes d'une composante (CONSEIL : -> VERIFIER ESPACE DISQUE)
 
                - VETALL : pour toutes les versions d'étapes qui sont ouvertes lors de l'année universitaire mises en paramètre                
	        
                - LISTES_VET : pour toutes les versions d'étapes presentes dans votre fichier FIC_NAME_FILTRE ( à ajouter dans rdd_vac.ini) 
                

   		- le critère COD_OBJ correspond soit un version d'étape si le critère COD_TYP_OBJ est égale à VET , soit un code composante si le critère COD_TYP_OBJ est égale à CMP


       	- le critère TEM_DELETE (soit Y, soit N) pour interchanger le mode suppression (N) et le mode insertion (Y) 
	   pour passage (script play_rdd_vac.sh) ou pour génération (script create_sql_pivot.sh)

    	 -  le critère COD_ETB: code établissement
	
		 -  le critère PREFIXON (soit Y, soit N) si utilisation d'un prefixe pour les VET et les VDI
	
		 -  le critère PREFIX_VET correspond au préfixe de la VET si utilisation d'un prefixe pour les VET et les VDI
			-> Prefixage automatique avec "-"

		 -  le critère PREFIX_VDI correspond au préfixe de la VDI si utilisation d'un prefixe pour les VET et les VDI
			-> Prefixage automatique avec "-"

		 - le critère PDB correspond à la variable d'environnement
		 	 A renseigner !!! : votre PDB n'est pas renseigner

		 - le critère NB_THREAD correspond au nombre de thread (uniquement pour create_sql_pivot.sh)
  2. Lancer le script rdd_vac pour générer les vacs.


   Si insertion dans APOGEE :

  	3. Lancer le script play_rdd_vac.sh en mode insertion (TEM_DELETE=N) pour inserer les vacs générées.

  	4. Vérifier la présence des VACS pour l'ensemble des étudiants.
     
   	5. Déverser les informations des modules CHC et COC dans la base pivot.

  	6. Vérifier la présence des vacs dans la table apprenant_chc
	
	7. Faire une injection normale 
 
  	 Si vous voulez supprimer les VACS 
		- Relancer le script play_rdd_vac.sh en mode suppression (TEM_DELETE=Y) pour supprimer les vacs générées.

  Soit insertion dans la base pivot :

	3. Déverser les informations des modules CHC et COC dans la base pivot.

	4. Lancer le script create_sql_pivot.sh en mode insertion pour générer les fichiers CSV.
	
	5. Mettre le fichier csv généré pour les CHC et les COC dans la base pivot dans le dossier fichier_sortie_sql avec les commandes ci-dessous

```sql
Commande SQL :

CREATE TABLE public.tmp_table AS SELECT * FROM public.apprenant_chc WITH NO DATA; COPY public.tmp_table FROM 'nom_fichier.csv' WITH (FORMAT csv, delimiter ';' , HEADER true, NULL 'NULL'); INSERT INTO public.apprenant_chc SELECT * FROM tmp_table ON CONFLICT DO NOTHING;DROP TABLE tmp_table;


CREATE TABLE public.tmp_table AS SELECT * FROM public.apprenant_coc WITH NO DATA; COPY public.tmp_table FROM 'nom_fichier.csv' WITH (FORMAT csv, delimiter ';' , HEADER true, NULL 'NULL'); INSERT INTO public.apprenant_coc SELECT * FROM tmp_table ON CONFLICT DO NOTHING;DROP TABLE tmp_table;

```

```docker

Si dans DOCKER

docker cp 'nom_fichier.csv' pivot_postgrestest_1:/tmp

docker exec -i pivot_postgrestest_1  psql -U pcscol -d pivotbdd -c " CREATE TABLE public.tmp_table AS SELECT * FROM public.apprenant_chc WITH NO DATA; COPY public.tmp_table FROM 'nom_fichier.csv' WITH (FORMAT csv, delimiter ';' , HEADER true, NULL 'NULL'); INSERT INTO public.apprenant_chc SELECT * FROM tmp_table ON CONFLICT DO NOTHING;DROP TABLE tmp_table;"

docker cp 'nom_fichier.csv' pivot_postgrestest_1:/tmp

docker exec -i pivot_postgrestest_1  psql -U pcscol -d pivotbdd -c " CREATE TABLE public.tmp_table AS SELECT * FROM public.apprenant_coc WITH NO DATA; COPY public.tmp_table FROM 'nom_fichier.csv' WITH (FORMAT csv, delimiter ';' , HEADER true, NULL 'NULL'); INSERT INTO public.apprenant_coc SELECT * FROM tmp_table ON CONFLICT DO NOTHING;DROP TABLE tmp_table;"

```

	6. Vérifier la présence des VACS pour module CHC et dans le module COC pour l'ensemble des étudiants dans la base pivot (dans la table apprenant_chc).
 
 	7. Passer script script_suppression_chc_superflus.sql pour supprimer les éléments fils sous une EVAL
	   (Problème du à l'injection des CHC après le déversement du module CHC)
  
	8. Passer les audits des modules CHC et COC

	9. Faire une injection normale des CHC

	10. Passer script script_coc_mcc.sql pour eviter probleme conteneur COC et probleme calcul des MCC
		(Problème du à l'injection des COC après le déversement du module COC)
			
    11. Faire le calcul des MCC et les injecter

	12. Faire une injection normale des COC
	   
	
Bonus : Projet de récupération des LCC pour les PRC sh puis, importer .csv généré sur Liens de correspondance pour calcul dans le module CHC
