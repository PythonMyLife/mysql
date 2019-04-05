use university;
select T.ID,course.title,count(distinct takes.ID)
from (select distinct ID
		  from (select instructor.* ,@num :=@num + 1 as row_num
		            from instructor,(select @num := 0) as b
					order by salary desc) as base
					where base.row_num <= (@num * 0.1)) as T,takes,teaches,course
where teaches.ID = T.ID and takes.course_id = teaches.course_id and takes.course_id = course.course_id
group by T.ID,course.title;