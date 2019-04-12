use University;
/* Drop function that get the average score of a student */
DROP FUNCTION IF EXISTS avg_score;
DROP FUNCTION IF EXISTS credit_level;
/* Drop the view that get the view of student ranking in department */
DROP VIEW IF EXISTS ranking_stu;
DROP VIEW IF EXISTS ranking_dept;
DROP VIEW IF EXISTS counting_dept;
/* Create the function that get average score of student*/
delimiter $
CREATE FUNCTION avg_score(sid varchar(5))
RETURNS DECIMAL(6,1)
DETERMINISTIC
BEGIN
	DECLARE count DECIMAL(3,1) DEFAULT 0.0;
    DECLARE total_sco DECIMAL(6,1) DEFAULT 0.0;
    DECLARE sing_sco DECIMAL(4,1);
    DECLARE done INT DEFAULT FALSE;
    DECLARE stu_grade VARCHAR(2);
    DECLARE course_row CURSOR FOR
		SELECT grade 
        FROM takes
        WHERE takes.ID = sid;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    OPEN course_row;
    FETCH NEXT FROM course_row INTO stu_grade;
    WHILE !done DO
        CASE stu_grade
			WHEN "A+" THEN SET sing_sco = 100.0;
            WHEN "A " THEN SET sing_sco = 95.0;
            WHEN "A-" THEN SET sing_sco = 90.0;
            WHEN "B+" THEN SET sing_sco = 85.0;
            WHEN "B " THEN SET sing_sco = 80.0;
            WHEN "B-" THEN SET sing_sco = 75.0;
            WHEN "C+" THEN SET sing_sco = 70.0;
            WHEN "C " THEN SET sing_sco = 65.0;
            WHEN "C-" THEN SET sing_sco = 60.0;
		END CASE;
        SET count = count + 1.0;
        SET total_sco = total_sco + sing_sco;
    FETCH NEXT FROM course_row INTO stu_grade;    
    END WHILE;
    CLOSE course_row;
    RETURN total_sco / count;
END;
$
delimiter ;

/* Crete the view that get the student ranking in school */
CREATE VIEW ranking_stu AS
    SELECT 
        DISTINCT ID, name, dept_name, avg_score(id) AS avg_score
    FROM
        student
	ORDER BY dept_name, avg_score DESC;

CREATE VIEW ranking_dept AS
    SELECT *,
        count(*) over (PARTITION BY dept_name) AS total,
        rank() over (PARTITION BY dept_name ORDER BY avg_score DESC )
            AS ranking
    FROM ranking_stu
    ORDER BY dept_name, avg_score DESC;

 
delimiter $
CREATE FUNCTION credit_level(ranking INT, total INT)
RETURNS VARCHAR(1)
DETERMINISTIC
BEGIN
    CASE
		WHEN ranking <= ceil(0.2*total) THEN RETURN 'A';
        WHEN ranking <= ceil(0.4*total) THEN RETURN 'B';
        ELSE RETURN '';
	END CASE;
END$
delimiter ;

/*select * from ranking_dept;*/

SELECT dept_name, credit_level(ranking, total) as level,
    ID as s_id, name as s_name, avg_score
FROM ranking_dept
WHERE ranking <= ceil(0.4*total)
ORDER BY dept_name, avg_score DESC;


