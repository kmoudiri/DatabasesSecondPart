CREATE OR REPLACE VIEW show_diplomas AS                                   --Student with thesis_grade and supervisor
SELECT a.am, a.name, a.surname, a.entry_date, a.diploma_grade AS thesis_grade, p.name AS super_name, p.surname AS super_surname
FROM(
	SELECT *
	FROM "Student" s JOIN "Diploma" d USING (amka)) AS a, "Professor" p
WHERE a.amka_super=p.amka AND a.diploma_grade is not null


SELECT *
FROM  show_diplomas 

---------------------------------------------------------------------------
CREATE TRIGGER propagate_modifications_view       --create trigger for changes to the view
INSTEAD OF INSERT ON show_diplomas 
FOR EACH ROW 
EXECUTE PROCEDURE push_modifications_view();




CREATE OR REPLACE FUNCTION push_modifications_view()
  RETURNS trigger AS $BODY$
BEGIN

IF (TG_OP = 'INSERT') THEN

	IF ( NEW.am IN (SELECT am from "Student" )) THEN
		UPDATE "Student" 
		SET name=random_names(1), father_name = random_male_names(), surname = random_surnames(1), email = null, am= NEW.am,entry_date= null;
	ELSE 
		INSERT INTO "Student" values(am,random_names(1), random_male_names(),random_surnames(1), null, NEW.am, null);
	END IF;
  RETURN NEW;
END IF;
END;
$BODY$
LANGUAGE plpgsql 



