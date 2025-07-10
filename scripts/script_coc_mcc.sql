
do $$ 
declare 	
	rec_element_fils  record;
	-- cursor de recherche des élements fils
	cur_element_fils cursor for select distinct code_apprenant ||'-' || code_objet_formation ||'-' || code_periode ||'-' || code_filtre_formation id
										 from apprenant_coc appcoc
										 where not exists (select 1 from apprenant_chc appchc where appchc.code_apprenant = appcoc.code_apprenant and (appcoc.code_objet_formation = appchc.code_objet_formation) and appchc.code_formation = appcoc.code_filtre_formation and appcoc.code_periode = appcoc.code_periode)
										 and appcoc.code_objet_formation is not null;

	-- modification des temoins de capitalisation ( probleme lors des calculs des MCC)
	rec_mcc_doublon record;


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
			WHERE   appcoc.code_apprenant ||'-' || appcoc.code_objet_formation ||'-' || appcoc.code_periode ||'-' || appcoc.code_filtre_formation = rec_element_fils.id;	
			RAISE NOTICE ' ---> Suppression COC';
			
		EXCEPTION
			WHEN OTHERS THEN 				
    			raise notice '% %', SQLERRM, SQLSTATE;

		END;
	

		
	end loop;
	close cur_element_fils;


RAISE NOTICE '=============================================';
RAISE NOTICE 'Fin';
end;
$$;