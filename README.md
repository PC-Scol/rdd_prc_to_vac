
> [!WARNING]
> Ce projet n'a pas encore atteint sa version stable. Il est donc sujet à des
> modifications incompatibles de temps à autres.

# RDD_VAC

## Contenu
Ce programme permet de générer des validations d'acquis d'expérience pour reprendre les PRC des années antérieures au périmètre de RDD.

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

        - COD_ANU : à l'année universitaire au-delà de laquelle il n'y aura pas de RDD dans le passé et pour laquelle des VACs seront générées en lieu et place d'acquis capitalisés.
		  Exemple : si le périmète de RDD va de 2022 à 2025 alors mettre 2022 dans COD_ANU. Les PRCs en 2022 sur des capitalisation ayant eu lieu en 2021 ou avant seront alors remplacés lors de la RDD par des VACs 2022.
 
        - COD_TYP_OBJ : types de détéction que vous voulez faire
 
            4 types de detections sont disponibles :
 
                - VET : pour une version d'étape (code etape et code version d'etape à renseigner dans le fichier)
				    A renseigner !!! :
					  -> COD_OBJ : sous la forme du filtre_formations de l'outillage de reprise de données pegase "COD_DIP-COD_VRS_VDI->ETP-COD_VRS_ETP
					 
                - CMP : pour toutes les versions d'étapes d'une composante (CONSEIL : -> VERIFIER ESPACE DISQUE)
 
                - VETALL : pour toutes les versions d'étapes qui sont ouvertes lors de l'année universitaire mises en paramètre
	        
                - LISTES_VET : pour toutes les versions d'étapes presentes dans votre fichier dans le dossier "filtre_formation_a_deposer"
				1. Lancer en mode LISTES_VET  pour générer le dossier "filtre_formation_a_deposer" (à faire à la première éxécution)
				2. Mettre le filtre formation sous la forme du fichier en exemple
				3. Relancer le programme avec dans ce mode
               
   	    - COD_OBJ : soit une version d'étape si le critère COD_TYP_OBJ est égale à VET , soit un code composante si le critère COD_TYP_OBJ est égale à CMP

        - TEM_DELETE : (Y/N) pour interchanger le mode suppression (N) et le mode insertion (Y) 
	   pour passage (script play_rdd_vac.sh) ou pour génération (script create_sql_pivot.sh)

        - COD_ETB : code établissement
	
        - PREFIXON (Y/N) : si utilisation d'un prefixe pour les VET et les VDI
	
        - PREFIX_VET : préfixe de la VET si utilisation d'un prefixe pour les VET et les VDI
			-> Prefixage automatique avec "-"

        - PREFIX_VDI : préfixe de la VDI si utilisation d'un prefixe pour les VET et les VDI
			-> Prefixage automatique avec "-"

        - PDB : nom de votre PDB Apogee

        - TRANSFORMATION_CONSERVATION_CAPITALISATION (Y/N) : Choix de transformer les conservations en capitalisations (Y) ou pas (N, par défaut) : Pégase ne gère pour l'instant pas la conservation. Par défaut, les PRCs sur objets conservés sont donc exclus. Si vous souhaitez reprendre les notes sur les objets conservés et que vous accéptez que la conservation soit transformée en capitalisation, vous pouvez alors mettre ce parametre à Y

        - le critère NB_THREAD correspond au nombre de thread (uniquement pour create_sql_pivot.sh)
  2. Lancer le script rdd_vac pour générer les vacs.

     PUIS

  * Soit insertion dans APOGEE :

		3. Lancer le script play_rdd_vac.sh en mode insertion (TEM_DELETE=N) pour inserer les vacs générées.

		4. Vérifier la présence des VACS pour l'ensemble des étudiants.
		
		5. Déverser les informations des modules CHC et COC dans la base pivot.

		6. Vérifier la présence des vacs dans la table apprenant_chc
		
		7. Faire une injection normale 

	Si vous voulez supprimer les VACS 
		- Relancer le script play_rdd_vac.sh en mode suppression (TEM_DELETE=Y) pour supprimer les vacs générées.

  * Soit insertion dans la base pivot :

		3. Lancer les flux "classiques" rdd-tools de déversement CHC et COC Apogée en base pivot pour les formations concernées par la simulation des PRC.

		4. Lancer le script create_sql_pivot.sh pour générer les fichiers CSV.
		
		5. Injecter les fichiers csv générés (dossier fichier_sortie_sql) pour CHC et COC dans la base pivot avec les commandes ci-dessous

	```sql
	Commande SQL :

	CREATE TABLE public.tmp_table AS SELECT * FROM public.apprenant_chc WITH NO DATA; COPY public.tmp_table FROM 'nom_fichier_chc.csv' WITH (FORMAT csv, delimiter ';' , HEADER true, NULL 'NULL'); INSERT INTO public.apprenant_chc SELECT * FROM tmp_table ON CONFLICT DO NOTHING;DROP TABLE tmp_table;


	CREATE TABLE public.tmp_table AS SELECT * FROM public.apprenant_coc WITH NO DATA; COPY public.tmp_table FROM 'nom_fichier_coc.csv' WITH (FORMAT csv, delimiter ';' , HEADER true, NULL 'NULL'); INSERT INTO public.apprenant_coc SELECT * FROM tmp_table ON CONFLICT DO NOTHING;DROP TABLE tmp_table;

	```

	```docker

	Si dans DOCKER
	Récupération au préalable du nom du conteneur exécutant la base pivot via la commande : docker ps. Dans la suite du mode opératoire, on considère que le nom du conteneur est pivot_postgrestest_1

	docker cp 'nom_fichier_chc.csv' pivot_postgrestest_1:/tmp

	docker exec -i pivot_postgrestest_1  psql -U pcscol -d pivotbdd -c " CREATE TABLE public.tmp_table AS SELECT * FROM public.apprenant_chc WITH NO DATA; COPY public.tmp_table FROM '/tmp/nom_fichier_chc.csv' WITH (FORMAT csv, delimiter ';' , HEADER true, NULL 'NULL'); INSERT INTO public.apprenant_chc SELECT * FROM tmp_table ON CONFLICT DO NOTHING;DROP TABLE tmp_table;"

	docker cp 'nom_fichier_coc.csv' pivot_postgrestest_1:/tmp

	docker exec -i pivot_postgrestest_1  psql -U pcscol -d pivotbdd -c " CREATE TABLE public.tmp_table AS SELECT * FROM public.apprenant_coc WITH NO DATA; COPY public.tmp_table FROM '/tmp/nom_fichier_coc.csv' WITH (FORMAT csv, delimiter ';' , HEADER true, NULL 'NULL'); INSERT INTO public.apprenant_coc SELECT * FROM tmp_table ON CONFLICT DO NOTHING;DROP TABLE tmp_table;"

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
