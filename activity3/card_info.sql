USE version2;
DROP TABLE IF EXISTS card_info;

CREATE TABLE card_info(
  rarity smallint NOT NULL,
  max int NOT NULL,
  min int NOT NULL,
  number int NOT NULL,
  PRIMARY KEY(rarity)
)  ENGINE=INNODB;