do $$ 
declare 	
	rec_element_fils  record;
	-- cursor de recherche des élements fils
	cur_element_fils cursor for select distinct code_apprenant ||'-' || code_objet_formation id
										 from apprenant_coc appcoc
										 where not exists (select 1 from apprenant_chc appchc where appchc.code_apprenant = appcoc.code_apprenant and (appcoc.code_objet_formation = appchc.code_objet_formation) and appchc.code_formation = appcoc.code_filtre_formation )
										 and appcoc.code_objet_formation is not null;

	-- modification des temoins de capitalisation ( probleme lors des calculs des MCC)
	rec_mcc_doublon record;

	cur_mcc_element cursor for --- probleme temoin capitalisation
										select requete.code_filtre_formation ,
												 requete.code_objet_formation ,
												 requete.code_periode ,
												 requete.temoin_capitalise_O, 
												 requete.nb_temoin_O , 
												 requete.temoin_capitalise_N ,
												requete.nb_temoin_n
											from (
												
													with tab as (
																	select code_filtre_formation,code_objet_formation,code_periode, temoin_capitalise, count(temoin_capitalise) as nb
																		  from apprenant_coc appcoc										  		  
																		  where temoin_capitalise is not null
																	group by code_filtre_formation,code_objet_formation, code_periode, temoin_capitalise
																	order by appcoc.code_objet_formation,code_objet_formation,code_periode, temoin_capitalise
													)
													select tab1.code_filtre_formation code_filtre_formation ,
															 tab1.code_objet_formation code_objet_formation ,
															 tab1.code_periode code_periode ,
															 tab1.temoin_capitalise temoin_capitalise_O, 
															 tab1.nb nb_temoin_O , 
															 tab2.temoin_capitalise temoin_capitalise_N ,
															 tab2.nb nb_temoin_N
													from tab tab1,
														  tab tab2
													where tab1.code_filtre_formation  = tab2.code_filtre_formation  and tab1.code_objet_formation = tab2.code_objet_formation  and tab1.code_periode =tab2.code_periode 
													and tab2.temoin_capitalise = 'N' and tab1.temoin_capitalise ='O'
												)  as requete
											union 
											--- probleme temoin conserve
											 select requete.code_filtre_formation ,
												 requete.code_objet_formation ,
												 requete.code_periode ,
												 requete.temoin_capitalise_O, 
												 requete.nb_temoin_O , 
												 requete.temoin_capitalise_N,
												requete.nb_temoin_n
											from (
												
													with tab as (
																	select code_filtre_formation,code_objet_formation,code_periode, temoin_conserve, count(case when temoin_conserve is null then 1 else 0 end) as nb
																		  from apprenant_coc appcoc									  		  																	 
																	group by code_filtre_formation,code_objet_formation, code_periode, temoin_conserve
																	order by appcoc.code_objet_formation,code_objet_formation,code_periode, temoin_conserve
													)
													select tab1.code_filtre_formation code_filtre_formation ,
															 tab1.code_objet_formation code_objet_formation ,
															 tab1.code_periode code_periode ,
															 tab1.temoin_conserve temoin_capitalise_O, 
															 tab1.nb nb_temoin_O , 
															 tab2.temoin_conserve temoin_capitalise_N ,
															 tab2.nb nb_temoin_N
													from tab tab1,
														  tab tab2
													where tab1.code_filtre_formation  = tab2.code_filtre_formation  and tab1.code_objet_formation = tab2.code_objet_formation  and tab1.code_periode =tab2.code_periode 
													and (tab2.temoin_conserve is null or tab2.temoin_conserve='N' ) and tab1.temoin_conserve ='O'
												)  as requete;








	DECLARE nombre_temoin_O integer = 0;
	DECLARE nombre_temoin_N integer = 0;

-- resolution du probleme "pere sans chc"
begin
	RAISE NOTICE 'Debut suppression des elements inferieurs ayant une EVAL sous un element pere ayant une EVAL';
	RAISE NOTICE '=============================================';

	open cur_element_fils;
	loop
		fetch cur_element_fils into rec_element_fils;
			-- sortie à la fin de la liste
		exit when not found;
		RAISE NOTICE '%', rec_element_fils.id;

		IF rec_element_fils.id = NULL 
		THEN
			CONTINUE;
		END IF;
		

		BEGIN

			DELETE FROM apprenant_coc appcoc
			WHERE  appcoc.code_apprenant ||'-'||appcoc.code_objet_formation = rec_element_fils.id;	
			RAISE NOTICE ' ---> Suppression COC';
			
		EXCEPTION
			WHEN OTHERS THEN 				
    			raise notice '% %', SQLERRM, SQLSTATE;

		END;
	

		
	end loop;
	close cur_element_fils;



	RAISE NOTICE 'Debut des modification des COC doublons dans le calcul des MCC';
	RAISE NOTICE '=============================================';


	RAISE NOTICE 'Debut pour les temoins capitalisable';
	open cur_mcc_element;
	loop
		fetch cur_mcc_element into rec_mcc_doublon;
		-- sortie à la fin de la liste
		exit when not found;
		RAISE NOTICE '=============================================';
		RAISE NOTICE '%   - > code_filtre_formation', rec_mcc_doublon.code_filtre_formation;
		RAISE NOTICE '%   - > periode  ', rec_mcc_doublon.code_periode;
		RAISE NOTICE '%   - > code_objet_formation ', rec_mcc_doublon.code_objet_formation;
		If rec_mcc_doublon.nb_temoin_N <> 0 and rec_mcc_doublon.nb_temoin_O <> 0
		then
			IF rec_mcc_doublon.nb_temoin_N   < rec_mcc_doublon.nb_temoin_O or rec_mcc_doublon.nb_temoin_O = rec_mcc_doublon.nb_temoin_N 
			then
					RAISE NOTICE '%   --> Temoin O  ', rec_mcc_doublon.nb_temoin_O;
					RAISE NOTICE '%   --> Temoin N ',rec_mcc_doublon.nb_temoin_N   ;
					RAISE NOTICE ' ---> Modification temoin a O';

					BEGIN
						UPDATE apprenant_coc
						set temoin_capitalise = 'O',
							 temoin_conserve = 'O'
						where code_periode = rec_mcc_doublon.code_periode and code_filtre_formation = rec_mcc_doublon.code_filtre_formation and code_objet_formation =  rec_mcc_doublon.code_objet_formation;
					EXCEPTION
					WHEN OTHERS THEN 				
		    			raise notice '% %', SQLERRM, SQLSTATE;
		
				  END;
					
			
					
			end if;
			IF rec_mcc_doublon.nb_temoin_N  > rec_mcc_doublon.nb_temoin_O 
			then
								RAISE NOTICE '%   --> Temoin O  ', rec_mcc_doublon.nb_temoin_O ;
								RAISE NOTICE '%   --> Temoin N ', rec_mcc_doublon.nb_temoin_N  ;
								RAISE NOTICE ' ---> Modidication temoin a N';

								BEGIN
									UPDATE apprenant_coc
									set temoin_capitalise = 'N',
										 temoin_conserve = 'N'					
									where code_periode = rec_mcc_doublon.code_periode and code_filtre_formation = rec_mcc_doublon.code_filtre_formation and code_objet_formation =  rec_mcc_doublon.code_objet_formation;
				
								
									
								EXCEPTION
								WHEN OTHERS THEN 				
					    			raise notice '% %', SQLERRM, SQLSTATE;
					
							  END;

			end if;

		

		end if;
	
		
		
	end loop;
	close cur_mcc_element;

 	RAISE NOTICE ' ---> MAJ duree conservation';
		update apprenant_coc
		set duree_conservation = 99,
			 note_minimale_conservation = 10
		where temoin_conserve = 'O';
RAISE NOTICE '=============================================';
RAISE NOTICE 'Fin';
end;
$$;
