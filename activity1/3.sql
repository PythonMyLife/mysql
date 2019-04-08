/* finished by Shenglong Zhao */
use University;
/* Drop function that get the average score of a student */
DROP FUNCTION IF EXISTS avg_score;
DROP FUNCTION IF EXISTS num_dept;
DROP PROCEDURE IF EXISTS ins_top20_40;
DROP PROCEDURE IF EXISTS ins_all_credits;
/* Drop the view that get the view of student ranking in department */
DROP VIEW IF EXISTS ranking_stu;

DROP TABLE IF EXISTS credits;

/* Create the function that get average score of student*/
delimiter $
CREATE FUNCTION avg_score(sid varchar(5))
RETURNS DECIMAL(6,1)
DETERMINISTIC
BEGIN
	DECLARE count DECIMAL(3,1) DEFAULT 0.0;
    DECLARE total_sco DECIMAL(6,1) DEFAULT 0.0;
    DECLARE sing_sco DECIMAL(3,1);
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
			WHEN "A+" THEN SET sing_sco = 95.0;
            WHEN "A " THEN SET sing_sco = 90.0;
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
        distinct ID, name, dept_name, avg_score(id) as avg_score
    FROM
        student;

/* Create function which returns the number of students in a deparment */
delimiter $
CREATE FUNCTION num_dept(dept varchar(20))
returns int
deterministic
begin
	DECLARE count int;
    SET count = 0;
	SELECT COUNT(*) INTO count 
    FROM ranking_stu
    where dept_name=dept;
    return count;
end$
delimiter ;

CREATE TABLE credits(
	dept_name 	varchar(20),
    kind 		varchar(1) DEFAULT 'A',
    s_id 		varchar(5),
    s_name 		varchar(20),
    avg_score	DECIMAL(6,1),
    PRIMARY KEY (s_id)
);

/* Create procedure that insert top 20% and top 40% in a department */
delimiter $
CREATE PROCEDURE ins_top20_40(IN dept_name VARCHAR(20))
BEGIN
	DECLARE total INT DEFAULT 1;
    DECLARE top20 INT;
    DECLARE top40 INT;
    DECLARE min_top20 DECIMAL(6,1);
	SET total = num_dept(dept_name);
    SET top20 = ceil(total * 0.2);
    SET top40 = ceil(total * 0.4);
    SET top40 = top40 - top20;
    INSERT INTO credits
		SELECT dept_name, 'A', ID, name, avg_score
		FROM ranking_stu
		WHERE ranking_stu.dept_name = dept_name
		ORDER BY avg_score DESC
		LIMIT top20;
    SELECT min(avg_score) INTO min_top20
    FROM credits
    WHERE credits.dept_name = dept_name;
    INSERT INTO credits
		SELECT dept_name, 'B', ID, name, avg_score
		FROM ranking_stu
		WHERE ranking_stu.dept_name = dept_name 
			AND ranking_stu.avg_score < min_top20
		ORDER BY avg_score DESC
		LIMIT top40;
END$


CREATE PROCEDURE ins_all_credits()
BEGIN
	DECLARE dept VARCHAR(20);
    DECLARE done INT DEFAULT FALSE;
	DECLARE dept_row CURSOR FOR
		SELECT dept_name
		FROM department;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    OPEN dept_row;
    FETCH NEXT FROM dept_row INTO dept;
    WHILE !done DO
		call ins_top20_40(dept);
        FETCH NEXT FROM dept_row INTO dept;
	END WHILE;
    CLOSE dept_row;
END$
delimiter ;
call ins_all_credits();
SELECT *
FROM credits
ORDER BY dept_name, kind, avg_score DESC;