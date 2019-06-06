USE version2;

DROP PROCEDURE IF EXISTS test_lottery;
DELIMITER $$
CREATE PROCEDURE test_lottery()
BEGIN
  DECLARE i integer DEFAULT 0;

  WHILE i < 4000 do
    SELECT lottery(100,100);
    SET i = i + 1;
  END WHILE;
END$$