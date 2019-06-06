USE version2;

DROP PROCEDURE IF EXISTS test_card_packet_index;
DELIMITER $$
CREATE PROCEDURE test_card_packet_index()
BEGIN
  DECLARE i integer DEFAULT 0;

  WHILE i < 800 do
    CALL purchase("Paris9","Matt1971");
    SET i = i + 1;
  END WHILE;
END$$