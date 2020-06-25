-- sunarthsh gia to 1.5
CREATE OR REPLACE FUNCTION create_reg_1_5(n integer, entry_d date ,yr_s integer)
RETURNS VOID AS
$$
DECLARE 
   yr integer;    -- dilwsh metavlitis
BEGIN

   yr = EXTRACT(YEAR FROM entry_d); -- pairnw mono to etos apo thn hmerominia eggrafhs tou foithth
	
   INSERT INTO "Register" (amka, serial_number,course_code, exam_grade, final_grade,lab_grade, register_status)
   SELECT CAST(create_amka(yr_s,n1.id) AS integer), 22, present_courses(22), null,null,null, 'proposed' 
   FROM random_names(n) n1 natural join random_surnames(n) s;

END;
$$
LANGUAGE 'plpgsql' VOLATILE; 

select insert_data(2,'2050-01-01',2011,2012,2013)
SELECT create_reg_1_5(2,'2050-01-01',2013)


SELECT *
FROM "Register"
ORDER BY amka DESC


DELETE FROM "Register" WHERE amka = 2013000002







---------------------------------------------------------------
CREATE OR REPLACE FUNCTION present_courses(serial_number INTEGER)
RETURNS TABLE(course_code CHARACTER(7)) AS
$$
BEGIN
   RETURN QUERY
   
   SELECT DISTINCT cr.course_code
   FROM( 
   (SELECT "CourseRun".course_code    -- 6mhniaia mathimata tou trexontos examhnou
   FROM "CourseRun", "Semester"
   WHERE "CourseRun".serial_number = semester_id AND semester_status = 'present'  ) cr
   
   JOIN 
   
   (SELECT "Register".course_code     -- Mathimata prohgoumenwn etwn pou den exoun perasei oi foithtes
    FROM "Register"
    WHERE register_status = 'fail' AND "Register".serial_number <> 22 )  cf 
	
    ON cr.course_code = cf.course_code)
	
	
	JOIN 
	
	(SELECT c.course_code    --Mathimata tou kanonikou eksamhnou spoudwn twn foithtwn
    FROM "Course" c
    WHERE (SELECT real_semester('2020-05-05','2018-06-06')) = (c.typical_year*2) ) cs 
	
	ON cf.course_code = cs.course_code ;
    
   END;
$$
LANGUAGE 'plpgsql' VOLATILE;

SELECT present_courses(22)




-------------------------------------------------------------------------------


CREATE OR REPLACE FUNCTION real_semester(start_date date,entry_date date) --vriskei to kanoniko eksamhno spoudwn tou foithth
RETURNS INTEGER AS
$$
DECLARE yr INTEGER;
BEGIN
  
  yr = (EXTRACT(YEAR FROM start_date) - EXTRACT(YEAR FROM entry_date)); -- find typical year of studies for a student by his entry date
  
  IF (SELECT academic_season FROM "Semester" WHERE semester_status='present') = 'winter' THEN
     RETURN (2*yr)-1;
  ELSE
     RETURN 2*yr;
  END IF;
  
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;


SELECT real_semester('2020-05-05','2013-06-06')



----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
--1.6--
CREATE OR REPLACE FUNCTION insert_courses1_6(id integer)
RETURNS VOID AS
$$
BEGIN


INSERT INTO "CourseRun"(course_code, serial_number, exam_min, lab_min, exam_percentage, labuses, semesterrunsin, amka_prof1, amka_prof2)
SELECT q.course_code, id, q.exam_min, q.lab_min, q.exam_percentage, q.labuses, id, q.amka_prof1, q.amka_prof2
FROM
((SELECT MAX(a.serial_number),a.academic_season, a.course_code, a.exam_min, a.lab_min, a.exam_percentage, a.labuses, a.amka_prof1, a.amka_prof2
FROM(
	SELECT *
	FROM "CourseRun" c, "Semester" s 
	WHERE c.serial_number = s.semester_id ) AS a
	
WHERE	a.semester_status <> 'future'
GROUP BY a.academic_season, a.course_code, a.exam_min, a.lab_min, a.exam_percentage, a.labuses, a.amka_prof1, a.amka_prof2) as q

JOIN

(SELECT se.academic_season
FROM "Semester" se
WHERE se.semester_id=id) as w

on q.academic_season= w.academic_season);


END;
$$
LANGUAGE 'plpgsql' VOLATILE;	

SELECT insert_courses1_6(27);
------------------------------------------------------------------------------------------
--2.10--
CREATE OR REPLACE FUNCTION dependent2_10(course_code_given character(7))
RETURNS TABLE (course_code character(7), course_title character (100)) AS
$$
BEGIN
RETURN QUERY

SELECT c.course_code, c.course_title
FROM "Course" c, (
	SELECT a.anc FROM
	(WITH RECURSIVE Req(anc,des) AS (
		SELECT main as anc,dependent as des          --ola osa sxetizontai amesa
		FROM "Course_depends" 
		WHERE mode='required' or mode='recommended'
		UNION
		SELECT r.anc as anc,d.dependent as des        --ola osa sxetizontai emesa
		FROM Req r, "Course_depends" d
		WHERE r.des = d.main AND (mode='required' or mode = 'recommended')
	) 
	SELECT * FROM Req) AS a
	WHERE des=course_code_given) AS b
WHERE c.course_code = b.anc;

END;
$$
LANGUAGE  'plpgsql' VOLATILE;

SELECT dependent2_10('ΠΛΗ 302')
-------------------------------------------------------------------------------------------
--2.11--
CREATE OR REPLACE FUNCTION students_passed_plh2_11()
RETURNS TABLE(name character(30), surname character(30), am character(10)) AS
$$
BEGIN
RETURN QUERY


SELECT s.name, s.surname, s.am
FROM "Student" s, (
SELECT w.amka
FROM
	(SELECT amka, count(*)  as plh_passed               --posa upoxrewtika PLH exei perasei kathe foititis
	FROM(
	SELECT DISTINCT r.course_code, r.amka
	FROM "Register" r, "Course" c
	WHERE r.course_code LIKE 'ΠΛΗ %' AND r.register_status='pass' AND c.course_code=r.course_code AND obligatory) AS a
GROUP BY amka) AS w
WHERE w.plh_passed=(SELECT count(*)  as plh_obligatory                --arithmos upoxrewtikwn mathimatwn PLH
					FROM "Course" 
					WHERE course_code LIKE 'ΠΛΗ%' AND obligatory) ) as q
					
WHERE q.amka=s.amka;

END;
$$
LANGUAGE  'plpgsql' VOLATILE;


SELECT students_passed_plh2_11()
---------------------------------------------------------------------
--4.1--
CREATE OR REPLACE VIEW showCourse4_1 AS 
SELECT b.course_code, b.course_title, p.name, p.surname
FROM
((SELECT c.course_code, c.course_title, a.amka_prof1, a.amka_prof2
FROM
(SELECT cr.course_code, cr.amka_prof1, cr.amka_prof2
FROM "CourseRun" cr, "Semester" s
WHERE cr.serial_number= s.semester_id AND s.semester_status='present') AS a

JOIN 

"Course" c

ON a.course_code = c.course_code) AS b

JOIN

"Professor" p

ON p.amka=b.amka_prof1 OR p.amka=b.amka_prof2)
ORDER BY course_code
