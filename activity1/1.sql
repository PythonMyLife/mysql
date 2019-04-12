use University;

DROP VIEW IF EXISTS top_10_instr;
DROP VIEW IF EXISTS course_teaches;
DROP VIEW IF EXISTS ranking_instr;
/* Find the instructor whose salary is top 10%  */
CREATE VIEW ranking_instr
AS
    SELECT id, name, rank() over (ORDER BY salary DESC) as r,
		(SELECT count(*) FROM instructor) as t
    FROM instructor
    ORDER BY salary DESC;
CREATE VIEW top_10_instr
AS
	SELECT id, name
    FROM ranking_instr
    WHERE r <= 0.1*t;

/* Get the course they teach */
CREATE VIEW course_teaches
AS
	SELECT  name as teacher_name,
			title as course_name,
			id as teacher_id,
            course_id
	FROM (top_10_instr NATURAL JOIN teaches) 
			NATURAL JOIN course
;

/* Get the popularity of teachers */
SELECT teacher_name, course_name, count(*) as num_of_stu
FROM course_teaches NATURAL JOIN takes
GROUP BY teacher_name, course_name
;