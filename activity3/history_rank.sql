use version1;
drop function if exists win_rate;
drop function if exists see_ranking;
drop function if exists day_win_rate;

delimiter $$
drop procedure if exists history_game $$
create procedure history_game(playname varchar(50))
begin
	select * 
    from game_record  
    where playname in (loser, winner);
END $$

delimiter $
create function see_ranking(playname varchar(50))
returns int
DETERMINISTIC
begin
	declare user_ranking int default 0;
    select ranking into user_ranking from players where name=playname;
    return user_ranking;
END;
$
delimiter ;

delimiter $
create function win_rate(playname varchar(50))
returns Decimal(5,4)
DETERMINISTIC
begin
	declare rate Decimal(5,4) default 0.0;
    declare loses int default 0;
    declare wins int default 0;
    
    select count(*) into loses  from game_record where loser=playname;
    select count(*) into wins  from game_record where winner=playname;
    if(loses + wins <> 0) then set rate = (wins/(wins+loses));
    end if;
    
    return rate;
END;
$
delimiter ;

delimiter $
create function day_win_rate(playname varchar(50), query_date datetime)
returns Decimal(5,4)
DETERMINISTIC
begin
	declare rate Decimal(5,4) default 0.0;
    declare loses int default 0;
    declare wins int default 0;
    
    select count(*) into loses  from game_record where loser=playname and date(time) = date(query_date);
    select count(*) into wins  from game_record where winner=playname and date(time) = date(query_date);
    if(loses + wins <> 0) then set rate = (wins/(wins+loses));
    end if;
    
    return rate;
END;
$
delimiter ;

delimiter $$
drop procedure if exists month_rate $$
create procedure month_rate(play_name varchar(50))
begin
	declare query_date datetime default now();
	select day_win_rate(play_name, query_date),
		day_win_rate(play_name, date_add(query_date,INTERVAL -1 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -2 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -3 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -4 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -5 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -6 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -7 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -8 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -9 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -10 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -11 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -12 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -13 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -14 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -15 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -16 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -17 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -18 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -19 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -20 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -21 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -22 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -23 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -24 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -25 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -26 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -27 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -28 day)),
        day_win_rate(play_name, date_add(query_date,INTERVAL -29 day));
END $$


call month_rate("test");