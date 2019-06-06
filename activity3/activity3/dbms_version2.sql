use version2;
drop table if exists bills;
drop table if exists card_packet;
drop table if exists forbids;
drop table if exists game_record;
drop table if exists group_item;
drop table if exists has_card;
drop table if exists card_group;
DROP TABLE IF EXISTS player_status;
drop table if exists players;
drop table if exists cards;
drop table if exists users;
CREATE TABLE bills (
    id BIGINT NOT NULL AUTO_INCREMENT,
    amount INTEGER,
    description VARCHAR(255),
    player_name VARCHAR(50),
    time DATETIME(6),
    PRIMARY KEY (id)
)  ENGINE=INNODB;
CREATE TABLE card_group (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(50),
    player_name VARCHAR(50),
    PRIMARY KEY (id)
)  ENGINE=INNODB;
CREATE TABLE card_packet (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(50),
    price int,
    PRIMARY KEY (id)
)  ENGINE=INNODB;
CREATE TABLE cards (
    id BIGINT NOT NULL AUTO_INCREMENT,
    description VARCHAR(255),
    name VARCHAR(50),
    rarity INTEGER,
    type VARCHAR(50),
    PRIMARY KEY (id)
)  ENGINE=INNODB;
CREATE TABLE forbids (
    id BIGINT NOT NULL AUTO_INCREMENT,
    end DATETIME(6),
    start DATETIME(6),
    admin VARCHAR(50),
    player VARCHAR(50),
    PRIMARY KEY (id)
)  ENGINE=INNODB;
CREATE TABLE game_record (
    id BIGINT NOT NULL AUTO_INCREMENT,
    time DATETIME(6),
    year int,
    month smallint,
    day smallint,
    loser VARCHAR(50) NOT NULL,
    winner VARCHAR(50) NOT NULL,
    PRIMARY KEY (id)
)  ENGINE=INNODB;
CREATE TABLE group_item (
    id BIGINT NOT NULL AUTO_INCREMENT,
    card_id BIGINT NOT NULL,
    card_group_id BIGINT NOT NULL,
    PRIMARY KEY (id)
)  ENGINE=INNODB;
CREATE TABLE players (
    name VARCHAR(50) NOT NULL,
    account BIGINT,
    month_recharge integer,
    nickname VARCHAR(50),
    PRIMARY KEY (name)
)  ENGINE=INNODB;
CREATE TABLE player_status (
    name VARCHAR(50) NOT NULL,
    joining bit,
    playing bit,
    rival varchar(50),
    defeats INTEGER,
    ranking INTEGER,
    match_ranking integer,
    PRIMARY KEY (name)
)  ENGINE=INNODB;
CREATE TABLE users (
    name VARCHAR(50) NOT NULL,
    email VARCHAR(30),
    identity SMALLINT,
    password VARCHAR(100),
    phone_number VARCHAR(15),
    PRIMARY KEY (name)
)  ENGINE=INNODB;
CREATE TABLE has_card (
    player_name VARCHAR(50) NOT NULL,
    card_id BIGINT NOT NULL,
    num int ,
    PRIMARY KEY (player_name , card_id)
)  ENGINE=INNODB;
alter table bills add constraint FK685xndnjpuktk08yafplbybhh foreign key (player_name) references players (name);
alter table card_group add constraint FKg53uwr5ir5kxu0cdo1d3yw88k foreign key (player_name) references players (name);
alter table game_record add constraint FKbbja9bo4bh2ovpueb601o2wpb foreign key (loser) references players (name);
alter table game_record add constraint FKswr9evrdlbxlvc4wv3ipu780s foreign key (winner) references players (name);
alter table forbids add constraint FKcwv4ces6q2lsg0jrv74dyf8jy foreign key (player) references players (name);
alter table forbids add constraint FKcwv4ces6q2lsg0jrv7x24sdwa foreign key (admin) references users (name);
alter table group_item add constraint FKjer5e5787bb1cplttdvndinbq foreign key (card_id) references cards (id);
alter table group_item add constraint FKkkmq7yj9vam5fyux6ego931kp foreign key (card_group_id) references card_group (id);
alter table has_card add constraint FKlk20t54xjm253m88vlq3gcra2 foreign key (card_id) references cards (id);
alter table has_card add constraint FK14bsi56apjg032pk80uk8gtmj foreign key (player_name) references players (name);
alter table players add constraint FK14bsi56apjg032pk80uk8dwdw foreign key (name) references users (name);
alter table player_status add constraint Fkdwadsadfwdaa foreign key (name) references players (name);
alter table player_status add constraint Fkdwadsadfwdadwadwaa foreign key (rival) references players (name);

