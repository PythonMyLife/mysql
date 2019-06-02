drop function if exists ban_user;
delimiter $
create function ban_user(adminname varchar(50), username varchar(50), this_day int, this_month int, this_year int, forever int)
returns boolean 
DETERMINISTIC
begin
	declare ban boolean default false;
    declare this_time datetime;
    declare ban_time datetime;
    set ban_time = now();
    set this_time = date_add(now(), INTERVAL this_year year);
    set this_time = date_add(this_time, INTERVAL this_month month);
    set this_time = date_add(this_time, INTERVAL this_day day);
    select end into ban_time from forbids where player=username;
    if not exists(select 1 from users where name=username) then return false;
    end if;
     if not exists(select 1 from users where name=adminname and identity=1) then return false;
    end if;
    if forever=1 then 
		delete from forbids where player=username;
        insert into forbids (end, start, admin, player) values ("0000-00-00 00:00:00", now(), adminname, username);
        return true;
	end if;
    if ban_time = "0000-00-00 00:00:00" then return false;
    end if;
    if ban_time < this_time then 
		delete from forbids where player=username;
        insert into forbids(end, start, admin, player) values (this_time, now(), adminname, username);
    else return false;
    end if;
    return true;
END;
$
delimiter ;

drop function if exists login;
delimiter $
create function login(username varchar(50), user_password varchar(100))
returns boolean 
DETERMINISTIC
begin
	declare log boolean default false;
    declare ban_time datetime;
    if not exists(select 1 from users where name=username and password=user_password) then return false;
    end if;
    if not exists(select 1 from forbids where player=username) then return true;
    end if;
    select end into ban_time from forbids where player=username;
    if(ban_time < now() and ban_time <> "0000-00-00 00:00:00") then delete from forbids where player=username;return true;
    end if;
    return false;
END;
$
delimiter ;

/*select ban_user("admin_test", "test",1,1,0,0);*/
select login("aa","");