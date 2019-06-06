USE version1;
SET SQL_SAFE_UPDATES=0;

DROP TABLE IF EXISTS playing_list;
CREATE TABLE playing_list (
  player1 varchar(50),
  player2 varchar(50)
) ENGINE=MEMORY;

DROP FUNCTION IF EXISTS relative_ranking;
DELIMITER $$
CREATE FUNCTION relative_ranking(player_name VARCHAR(50))
RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE player_rank INT DEFAULT 0;
    DECLARE player_defeats INT DEFAULT 0;
	SELECT ranking, defeats INTO player_rank, player_defeats
    FROM players
    WHERE name = player_name;
    IF player_defeats IS NOT NULL AND player_rank IS NOT NULL
    THEN 
		IF player_defeats >= 5
			THEN SET player_rank = player_rank - 5;
		END IF;
	END IF;
    RETURN player_rank;
END $$
DELIMITER ;

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
  FROM waiting_queue;
  IF queue_len >= 50
    THEN CALL match_game();
  END IF;
END $$
DELIMITER ;

DROP PROCEDURE  IF EXISTS match_game;
DELIMITER $$
CREATE PROCEDURE match_game()
BEGIN
  DECLARE player1 VARCHAR(50);
  DECLARE player2 VARCHAR(50);
  DECLARE player1_rank int;
  DECLARE player2_rank int;
  DECLARE done boolean DEFAULT FALSE;
  DECLARE player_in_queue CURSOR FOR
    SELECT name, ranking
    FROM  waiting_queue;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
  OPEN player_in_queue;
  WHILE !done DO
    FETCH NEXT FROM player_in_queue INTO player1, player1_rank;
    IF !done
      THEN FETCH NEXT FROM player_in_queue INTO player2, player2_rank;
      UPDATE players 
        SET joined=FALSE
        WHERE name = player1 OR name = player2;
      INSERT INTO playing_list
        VALUE(player1, player2);
    END IF;
  END WHILE;
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

DROP FUNCTION IF EXISTS lottery;

DELIMITER $$
CREATE FUNCTION lottery (bill integer, price integer)
RETURNS integer
DETERMINISTIC
BEGIN
  DECLARE probability1 decimal(4, 3) DEFAULT 0.0;
  DECLARE probability2 decimal(4, 3) DEFAULT 0.0;
  DECLARE probability3 decimal(4, 3) DEFAULT 1.0;
  DECLARE randnum decimal(5, 4);
  DECLARE card_rarity integer DEFAULT 1;
  DECLARE card_id integer;
  DECLARE total integer;
  SET total = CEIL(bill / 10 + price);
  SET probability1 = total / 1000;
  IF (probability1 >= 1) THEN
    SET probability2 = 1;
  ELSE
    SET probability2 = probability1 + total / 500;
  END IF;
  SET randnum = RAND();

  IF (randnum < probability1) THEN
    SET card_rarity = 3;
  ELSE
    IF (randnum < probability2) THEN
      SET card_rarity = 2;
    END IF;
  END IF;

  SELECT
    id INTO card_id
  FROM cards
  WHERE rarity = card_rarity
  ORDER BY RAND()
  LIMIT 1;

  RETURN card_id;
END$$
DELIMITER ;
/* Protect with tansaction ?*/

DROP PROCEDURE IF EXISTS recharge;
DELIMITER $$
CREATE PROCEDURE recharge(username varchar(50), amount integer)
BEGIN
  DECLARE new_account integer;
  DECLARE this_time datetime;

  /* update user account */
  SELECT
    account INTO new_account
  FROM players
  WHERE name = username;

  SET new_account = new_account + amount;

  UPDATE players
  SET account = new_account
  WHERE name = username;

  /* add record to bill */
  SELECT
    NOW() INTO this_time;

  INSERT INTO bills (player_name, time, amount)
    VALUES (username, this_time, amount);
END$$

DELIMITER $$
DROP PROCEDURE IF EXISTS purchase $$
CREATE PROCEDURE purchase(username varchar(50), pname varchar(50))
BEGIN
  DECLARE new_account integer;
  DECLARE amount integer;
  DECLARE this_time datetime;
  DECLARE this_month integer;
  DECLARE this_year integer;
  DECLARE recharge_amount integer;
  DECLARE c,
          i integer UNSIGNED;
  DECLARE card_num integer UNSIGNED;

  /* update user account */
  SELECT
    account INTO new_account
  FROM players
  WHERE name = username;

  SELECT
    price INTO amount
  FROM card_packet
  WHERE name = pname;

  SET new_account = new_account - amount;

  UPDATE players
  SET account = new_account
  WHERE name = username;

  /* add record to bill */
  SELECT
    NOW() INTO this_time;

  INSERT INTO bills (player_name, time, amount)
    VALUES (username, this_time, -amount);

  /* compute total consumption this month */
  SELECT
    MONTH(this_time) INTO this_month;

  SELECT
    YEAR(this_time) INTO this_year;

  SELECT
    SUM(amount) INTO recharge_amount
  FROM bills
  WHERE player_name = username
  AND YEAR(time) = this_year
  AND MONTH(time) = this_month;

  /* Fetch 5 cards according to recharge record */
  /* add record to has_card */
  SET i = 0;
  WHILE i < 5 DO
    SET c = lottery(recharge_amount, amount);
    SET card_num = 0;

    SELECT
      num INTO card_num
    FROM has_card
    WHERE player_name = username
    AND card_id = c;

    IF (card_num <> 0) THEN
      UPDATE has_card
      SET num = card_num + 1
      WHERE player_name = username
      AND card_id = c;
    ELSE
      INSERT INTO has_card (player_name, card_id, num)
        VALUES (username, c, 1);
    END IF;
    SET i = i + 1;
  END WHILE;
END$$

DELIMITER ;

DROP FUNCTION IF EXISTS win_rate;
DROP FUNCTION IF EXISTS see_ranking;
DROP FUNCTION IF EXISTS day_win_rate;

/**************************************/
DELIMITER $$
DROP PROCEDURE IF EXISTS history_game$$
CREATE PROCEDURE history_game (playname varchar(50))
BEGIN
  SELECT
    *
  FROM game_record
  WHERE playname=loser OR playname=winner;
END$$

DELIMITER $
CREATE FUNCTION see_ranking (playname varchar(50))
RETURNS int
DETERMINISTIC
BEGIN
  DECLARE user_ranking int DEFAULT 0;
  SELECT
    ranking INTO user_ranking
  FROM players
  WHERE name = playname;
  RETURN user_ranking;
END;
$
DELIMITER ;

DELIMITER $
CREATE FUNCTION win_rate (playname varchar(50))
RETURNS decimal(5, 4)
DETERMINISTIC
BEGIN
  DECLARE rate decimal(5, 4) DEFAULT 0.0;
  DECLARE loses int DEFAULT 0;
  DECLARE wins int DEFAULT 0;

  SELECT
    COUNT(*) INTO loses
  FROM game_record
  WHERE loser = playname;
  SELECT
    COUNT(*) INTO wins
  FROM game_record
  WHERE winner = playname;
  IF (loses + wins <> 0) THEN
    SET rate = (wins / (wins + loses));
  END IF;
  RETURN rate;
END;
$
DELIMITER ;

DELIMITER $
CREATE FUNCTION day_win_rate (playname varchar(50), query_date datetime)
RETURNS decimal(5, 4)
DETERMINISTIC
BEGIN
  DECLARE rate decimal(5, 4) DEFAULT 0.0;
  DECLARE loses int DEFAULT 0;
  DECLARE wins int DEFAULT 0;

  SELECT
    COUNT(*) INTO loses
  FROM game_record
  WHERE loser = playname
  AND date (time) = date (query_date);
  SELECT
    COUNT(*) INTO wins
  FROM game_record
  WHERE winner = playname
  AND date (time) = date (query_date);
  IF (loses + wins <> 0) THEN
    SET rate = (wins / (wins + loses));
  END IF;

  RETURN rate;
END;
$
DELIMITER ;

DELIMITER $$
DROP PROCEDURE IF EXISTS month_rate$$
CREATE PROCEDURE month_rate (play_name varchar(50))
BEGIN
  DECLARE query_date datetime DEFAULT NOW();
  SELECT
    day_win_rate(play_name, query_date),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -1 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -2 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -3 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -4 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -5 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -6 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -7 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -8 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -9 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -10 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -11 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -12 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -13 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -14 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -15 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -16 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -17 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -18 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -19 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -20 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -21 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -22 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -23 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -24 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -25 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -26 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -27 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -28 DAY)),
    day_win_rate(play_name, DATE_ADD(query_date, INTERVAL -29 DAY));
END$$
DELIMITER ;

DELIMITER $$
DROP PROCEDURE IF EXISTS compose_group;
CREATE PROCEDURE compose_group(IN player_name varchar(50))
BEGIN

END $$
DELIMITER ;