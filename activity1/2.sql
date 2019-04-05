use university;

drop function if exists course_ratio;
delimiter //
create function course_ratio(dept varchar(20))
    returns decimal(3,1)
    reads sql data
	deterministic
    begin
    declare c_count integer default 0;
    declare d_count decimal(3,1);
    declare c_std integer default 0;
    declare counted integer default 0;
    declare done bool default false;
    declare cursor1 cursor for select count(distinct course_id)
                                        from student natural join takes
                                        where dept_name=dept
                                        group by student.ID;
    declare continue HANDLER for not found set done = true;
    open cursor1;
        repeat
            fetch cursor1 into c_std;
			set counted = counted +1; 
            set c_count = c_count + c_std; 
        until done
        end repeat;
	close cursor1;
	set d_count = c_count / counted;
	return d_count;
    end//
delimiter ;
select dept_name,course_ratio(dept_name)
from department;