do $$ 
declare 	
	rec_element_fils  record;
	-- cursor de recherche des élements fils
	cur_element_fils cursor for select distinct resultat.id
							from 
								(
										with tab as
										(
											select code_apprenant,
													 code_objet_formation,
													 operation,
													 code_chemin,
													 code_periode,
													 code_formation
											from apprenant_chc ac 
										)
										select tab2.code_apprenant ||'-' || tab2.code_objet_formation || '-' || tab2.code_periode || '-' ||tab2.code_formation id	 
										from tab tab1,
											  tab tab2
										where tab1.code_apprenant = tab2.code_apprenant 
										and tab1.code_objet_formation <> tab2.code_objet_formation 
										and tab1.code_periode = tab2.code_periode
										and tab1.operation = tab2.operation
										and tab1.code_formation = tab2.code_formation 
										and tab1.operation = 'AM' 
										and tab2.code_chemin like  '%' || tab1.code_chemin ||'%'
									) resultat;

	--curseur doublon de chemin sur plusieur vet 

	rec_doublon_am  record;
	cur_doublon_am_cur cursor for select distinct  id
											from apprenant_chc ac 
											where exists 
											(
												select 1
												from apprenant_chc chc where chc.code_periode = ac.code_periode and chc.code_formation <>ac.code_formation  and chc.code_chemin = ac.code_chemin and ac.code_apprenant = chc.code_apprenant  and chc.code_objet_formation = ac.code_objet_formation 
											) and operation <> 'AM';

		
-- resolution du probleme "pere sans chc"
begin
	RAISE NOTICE 'Debut suppression des elements inferieurs ayant une EVAL sous un element pere ayant une EVAL';
	RAISE NOTICE '=============================================';

	open cur_element_fils;
	loop
		fetch cur_element_fils into rec_element_fils;
		RAISE NOTICE '%', rec_element_fils.id;

		IF rec_element_fils.id = NULL 
		THEN
			CONTINUE;
		END IF;
		

		BEGIN

			DELETE FROM apprenant_chc appchc
			WHERE  appchc.code_apprenant ||'-'||appchc.code_objet_formation || '-' || appchc.code_periode || '-' || appchc.code_formation = rec_element_fils.id;	
			RAISE NOTICE ' ---> Suppression CHC';
			
		EXCEPTION
			WHEN OTHERS THEN 				
    			raise notice '% %', SQLERRM, SQLSTATE;

		END;
		-- sortie à la fin de la liste
		exit when not found;

		
	end loop;
	close cur_element_fils;

	RAISE NOTICE 'Debut suppression des chemins doublons presents sur plusieurs vet';
	RAISE NOTICE '=============================================';

	open cur_doublon_am_cur;
	loop
		fetch cur_doublon_am_cur into rec_doublon_am;
		RAISE NOTICE '%', rec_doublon_am.id;

		IF rec_doublon_am.id = NULL 
		THEN
			CONTINUE;
		END IF;
		

		BEGIN

			DELETE FROM apprenant_chc appchc
			WHERE id = rec_doublon_am.id ;	
			RAISE NOTICE ' ---> Suppression CHC';
			
		EXCEPTION
			WHEN OTHERS THEN 				
    			raise notice '% %', SQLERRM, SQLSTATE;

		END;
		-- sortie à la fin de la liste
		exit when not found;

		
	end loop;
	close cur_doublon_am_cur;

RAISE NOTICE '=============================================';
RAISE NOTICE 'Fin';
end;
$$;
