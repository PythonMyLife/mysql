USE version1;
SET SQL_SAFE_UPDATES=0;

DROP TABLE IF EXISTS playing_list;
CREATE TABLE playing_list (
  player1 varchar(50),
  player2 varchar(50)
) ENGINE=MEMORY;


/* Match queue */
DROP VIEW IF EXISTS waiting_queue;
CREATE VIEW waiting_queue AS
  SELECT *, relative_ranking(p.name) AS match_rank FROM players p
  WHERE p.joined=TRUE
  ORDER BY relative_ranking(p.name);


DROP PROCEDURE IF EXISTS join_game;
DELIMITER $$
CREATE PROCEDURE join_game(IN player_name varchar(50))
BEGIN
  DECLARE queue_len int DEFAULT 1;
  
  UPDATE players p
    SET p.joined=TRUE
  WHERE player_name=p.name;
  
  SELECT COUNT(*) INTO queue_len
  FROM players
  WHERE joined = TRUE;
  IF queue_len >= 50
    THEN CALL match_game();
  END IF;
END $$
DELIMITER ;

DROP PROCEDURE  IF EXISTS match_game;
DELIMITER $$
CREATE PROCEDURE match_game()
BEGIN
  SET @row=0;
  INSERT INTO playing_list 
    WITH queue AS 
      (
        SELECT name, ROW_NUMBER() OVER w AS 'row'
        FROM  players
        WHERE joined = TRUE
        WINDOW w AS (ORDER BY ranking)
      )
    SELECT oq.name AS player1 , (SELECT q.name FROM queue q WHERE q.row=oq.row+1) AS player2
      FROM queue oq
    WHERE oq.row%2 <> 0;
    UPDATE players 
      SET joined=FALSE
    WHERE joined = TRUE;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS finish_game;
DELIMITER $$
CREATE PROCEDURE finish_game(IN player varchar(50), IN rival varchar(50))
BEGIN
  DELETE FROM playing_list
  WHERE player1=player OR player2=player;
  CALL insert_game_record(player, rival, RAND() > 0.5);
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS insert_game_record;
DELIMITER $$
CREATE PROCEDURE insert_game_record(IN player1 VARCHAR(50), IN player2 VARCHAR(50) , IN victory BOOLEAN)
DETERMINISTIC
BEGIN
	DECLARE winner VARCHAR(50);
    DECLARE loser VARCHAR(50);
    SELECT IF(victory=TRUE, player1, player2) 
		INTO winner;
	SELECT IF(victory=FALSE, player1, player2)
		INTO loser;
    INSERT INTO game_record(time, loser, winner)
    VALUES(NOW(), loser, winner);
    UPDATE players 
      SET ranking=ranking + 1,
      defeats = 0
      WHERE name=winner;
    UPDATE players
      SET ranking=IF(ranking=0, 0, ranking - 1),
        defeats = defeats + 1
    WHERE name=loser;   
END $$
DELIMITER ;

/*
 * Function
 */
DROP FUNCTION IF EXISTS ban_user;
DELIMITER $
CREATE FUNCTION ban_user (adminname varchar(50), username varchar(50), this_day int, this_month int, this_year int, forever int)
RETURNS boolean
DETERMINISTIC
BEGIN
  DECLARE ban boolean DEFAULT FALSE;
  DECLARE this_time datetime;
  DECLARE ban_time datetime;
  SET ban_time = NOW();
  SET this_time = DATE_ADD(NOW(), INTERVAL this_year year);
  SET this_time = DATE_ADD(this_time, INTERVAL this_month MONTH);
  SET this_time = DATE_ADD(this_time, INTERVAL this_day DAY);
  SELECT
    end INTO ban_time
  FROM forbids
  WHERE player = username;
  IF NOT EXISTS (SELECT
        1
      FROM users
      WHERE name = username) THEN
    RETURN FALSE;
  END IF;
  IF NOT EXISTS (SELECT
        1
      FROM users
      WHERE name = adminname
      AND identity = 1) THEN
    RETURN FALSE;
  END IF;
  IF forever = 1 THEN
    DELETE
      FROM forbids
    WHERE player = username;
    INSERT INTO forbids (end, start, admin, player)
      VALUES (0, NOW(), adminname, username);
    RETURN TRUE;
  END IF;
  IF ban_time = 0 THEN
    RETURN FALSE;
  END IF;
  IF ban_time < this_time THEN
    DELETE
      FROM forbids
    WHERE player = username;
    INSERT INTO forbids (end, start, admin, player)
      VALUES (this_time, NOW(), adminname, username);
  ELSE
    RETURN FALSE;
  END IF;
  RETURN TRUE;
END;
$
DELIMITER ;

DROP FUNCTION IF EXISTS signin;
DELIMITER $
CREATE FUNCTION signin (username varchar(50), user_password varchar(100))
RETURNS boolean
DETERMINISTIC
BEGIN
  DECLARE log boolean DEFAULT FALSE;
  DECLARE ban_time datetime;
  IF NOT EXISTS (SELECT
        1
      FROM users
      WHERE name = username
      AND password = user_password) THEN
    RETURN FALSE;
  END IF;
  IF NOT EXISTS (SELECT
        1
      FROM forbids
      WHERE player = username) THEN
    RETURN TRUE;
  END IF;
  SELECT
    end INTO ban_time
  FROM forbids
  WHERE player = username;
  IF (ban_time < NOW()
    AND ban_time <> 0) THEN
    DELETE
      FROM forbids
    WHERE player = username;
    RETURN TRUE;
  END IF;
  RETURN FALSE;
END;
$
DELIMITER ;

delimiter $$
drop procedure if exists history_game $$
create procedure history_game(playname varchar(50))
begin
  	select time, winner, loser
    from game_record  
    where playname = loser;

    select time, winner, loser
    from game_record  
    where playname = winner;
END $$

delimiter $
create function day_win_rate(playname varchar(50), query_date datetime)
returns Decimal(5,4)
DETERMINISTIC
begin
	  declare rate Decimal(5,4) default 0.0;
    declare loses int default 0;
    declare wins int default 0;
    DECLARE d date DEFAULT date(query_date);
    
    select count(*) into loses  
    from game_record PARTITION (p2019)
    where loser = playname and time BETWEEN d AND d+1;
    select count(*) into wins  
    from game_record PARTITION (p2019)
    where winner = playname and time BETWEEN d AND d+1;
  
    if(loses + wins <> 0) then 
        set rate = (wins/(wins+loses));
    end if;
    
    return rate;
END;

delimiter $$
drop procedure if exists month_rate $$
DROP TABLE IF EXISTS rate_per_month $$
create procedure month_rate(play_name varchar(50))
begin
  	DECLARE query_date datetime default now();
    /*
    DECLARE query_day int DEFAULT 30;
    DECLARE rate Decimal(5,4) DEFAULT 0;
  */
  
    DROP TABLE IF EXISTS rate_per_month;
    CREATE TEMPORARY TABLE IF NOT EXISTS rate_per_month(
    id int UNSIGNED AUTO_INCREMENT,
    rate Decimal(5,4) NOT NULL,
    PRIMARY KEY(id));
    ALTER TABLE rate_per_month AUTO_INCREMENT = 1;

    /*
    WHILE(query_day > 0)
    DO 
      SELECT day_win_rate(play_name, date_add(query_date,INTERVAL -query_day day)) INTO rate;
      INSERT INTO rate_per_month(rate) VALUES(rate);
      SET query_day = query_day - 1;
    END WHILE;
  */
  
   
    INSERT INTO rate_per_month(rate) VALUES
    (day_win_rate(play_name, query_date)),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -1 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -2 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -3 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -4 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -5 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -6 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -7 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -8 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -9 day)));
    INSERT INTO rate_per_month(rate) VALUES
    (day_win_rate(play_name, date_add(query_date,INTERVAL -10 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -11 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -12 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -13 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -14 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -15 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -16 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -17 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -18 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -19 day)));
    INSERT INTO rate_per_month(rate) VALUES
    (day_win_rate(play_name, date_add(query_date,INTERVAL -20 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -21 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -22 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -23 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -24 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -25 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -26 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -27 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -28 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -29 day))),
    (day_win_rate(play_name, date_add(query_date,INTERVAL -30 day)));
    
END $$

/*
ALTER TABLE game_record DROP PRIMARY KEY , ADD PRIMARY KEY(id,time);
  */
ALTER TABLE game_record DROP FOREIGN KEY FKbbja9bo4bh2ovpueb601o2wpb;
ALTER TABLE game_record DROP FOREIGN KEY FKswr9evrdlbxlvc4wv3ipu780s;
ALTER TABLE game_record PARTITION BY RANGE (year(time))
(
  PARTITION p2009 VALUES LESS THAN (YEAR('2010-01-01')),
  PARTITION p2010 VALUES LESS THAN (YEAR('2011-01-01')),
  PARTITION p2011 VALUES LESS THAN (YEAR('2012-01-01')),
  PARTITION p2012 VALUES LESS THAN (YEAR('2013-01-01')),
  PARTITION p2013 VALUES LESS THAN (YEAR('2014-01-01')),
  PARTITION p2014 VALUES LESS THAN (YEAR('2015-01-01')),
  PARTITION p2015 VALUES LESS THAN (YEAR('2016-01-01')),
  PARTITION p2016 VALUES LESS THAN (YEAR('2017-01-01')),
  PARTITION p2017 VALUES LESS THAN (YEAR('2018-01-01')),
  PARTITION p2018 VALUES LESS THAN (YEAR('2019-01-01')),
  PARTITION p2019 VALUES LESS THAN MAXVALUE
);

ALTER TABLE game_record ADD INDEX (winner, time);
ALTER TABLE game_record ADD INDEX (loser, time);

DROP FUNCTION IF EXISTS lottery;

DELIMITER $$
CREATE FUNCTION lottery(bill integer, price integer)
RETURNS INTEGER
DETERMINISTIC
BEGIN
	DECLARE probability1 DECIMAL(4,3) DEFAULT 0.0;
    DECLARE probability2 DECIMAL(4,3) DEFAULT 0.0;
    DECLARE probability3 DECIMAL(4,3) DEFAULT 1.0;
    DECLARE randnum DECIMAL(5,4);
    DECLARE card_rarity integer DEFAULT 0;
    DECLARE card_id INTEGER;
    DECLARE total integer;
    DECLARE c_max, c_min integer;
    set total = ceil(bill/10 + price);
    IF total > 1000 THEN SET probability1 = 1;
    ELSE set probability1 = total/1000;
    END IF;
    if(probability1 >= 1) then set probability2 = 1;
    else set probability2 = probability1 + total/500;
    end if;
    set randnum = rand();
    
    if(randnum < probability1) then set card_rarity = 2;
    else if(randnum < probability2) then set card_rarity = 1;
		end if;
	end if;
    
    /*select id into card_id
    from cards
    where rarity = card_rarity
    order by rand()
    limit 1;*/

    /*SELECT id INTO card_id
    FROM cards
    WHERE id >= (SELECT floor(RAND() * (SELECT MAX(id) 
      FROM cards 
      WHERE rarity = card_rarity))) AND rarity = card_rarity 
    ORDER BY id
    LIMIT 1;*/

    /*SELECT max, min INTO c_max, c_min
    FROM card_info
    WHERE rarity = card_rarity;*/

    SELECT max, min INTO c_max, c_min
      FROM card_info
      WHERE rarity = card_rarity;
    SELECT id INTO card_id
      FROM cards
      WHERE id >= (RAND()*(c_max - c_min) + c_min)
        AND rarity = card_rarity
      LIMIT 1;

    return card_id;
    
    
END;$$
DELIMITER ;
/* Protect with tansaction ?*/

DROP PROCEDURE IF EXISTS recharge;
DELIMITER $$
CREATE PROCEDURE recharge(username varchar(50), amount integer)
BEGIN
  DECLARE new_account integer;
  DECLARE new_month_recharge integer;
  DECLARE this_time datetime;

  /* update user account */
  SELECT
    account, month_recharge 
    INTO new_account, new_month_recharge
  FROM players
  WHERE name = username;

  SET new_account = new_account + amount;
  SET new_month_recharge = new_month_recharge + amount;

  UPDATE players
  SET account = new_account,month_recharge = new_month_recharge
  WHERE name = username;

  /* add record to bill */
  SET this_time = now();

  INSERT INTO bills (player_name, time, amount,description)
    VALUES (username, this_time, amount,"recharge");
END$$

DELIMITER $$
DROP PROCEDURE IF EXISTS purchase $$
create procedure purchase (
	username varchar(50), 
	pname varchar(50))
begin
declare new_account integer;
declare amount integer;
declare this_time datetime;
declare this_month integer;
declare this_year integer;
declare recharge_amount integer;
declare c, i integer unsigned;
declare number integer unsigned;


select account into new_account
from players
where name = username;

select price into amount
from card_packet
where name = pname;

set new_account = new_account - amount;


IF new_account > 0 THEN 

update players
set account = new_account
where name = username;

select now() into this_time;

insert into bills(player_name, time, amount,description)
values (username, this_time, -amount,"buy card_packet");

select month_recharge into recharge_amount
from players
where name = username;


set i = 0;
while i < 5 do
	set c = lottery(recharge_amount, amount);
	set number = 0;
    
	select num into number 
    from has_card
    where player_name = username and card_id = c;
    
	if(number <>0) then 
		update has_card 
        set num = number+1 
        where player_name = username and card_id = c;
	else 
		insert into has_card(player_name, card_id, num) values (username, c, 1);
	end if;
    set i = i + 1;
end while;
END IF;

end $$

DELIMITER ;