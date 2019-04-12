use University;

DROP FUNCTION IF EXISTS course_radio;

DELIMITER $
CREATE FUNCTION course_radio(dept varchar(20))
RETURNS DECIMAL(6,2)
DETERMINISTIC
BEGIN
	DECLARE course_count int;
    DECLARE stu_count int;
    DECLARE c_cur CURSOR FOR
		SELECT COUNT(*) 
        FROM student NATURAL JOIN takes
        WHERE student.dept_name = dept;
	DECLARE s_cur CURSOR FOR
		SELECT COUNT(*)
		FROM student
        WHERE student.dept_name=dept;
    SET course_count = 0;
    SET stu_count = 0;
    OPEN s_cur;
    FETCH NEXT FROM s_cur INTO stu_count;
	OPEN c_cur;
    FETCH NEXT FROM c_cur INTO course_count;
    CLOSE s_cur;
    CLOSE c_cur;
    RETURN course_count/stu_count;
END$
DELIMITER ;

SELECT dept_name, course_radio(dept_name) from department;

/*
// Second solution
use University;
drop function if exists course_ratio;

delimiter $

create function course_ratio(dept varchar(20))
    returns decimal (4,2)
	deterministic
    begin
    declare c_count integer default 0;
    declare d_count decimal(4,2);
    declare c_std integer default 0;
    declare counted integer default 0;
    declare done bool default false;
    declare cursor1 cursor for select count(course_id)
                                        from student natural join takes
                                        where dept_name=dept
                                        group by student.ID;
    declare continue HANDLER for not found set done = true;
    open cursor1;
    fetch cursor1 into c_std;
        repeat
			set counted = counted +1; 
            set c_count = c_count + c_std;
            fetch cursor1 into c_std;
        until done
        end repeat;
	close cursor1;
	set d_count = c_count / counted;
	return d_count;
    end$
delimiter ;
select dept_name,course_ratio(dept_name)
from department;
*/
