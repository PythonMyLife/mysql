drop database cardgame;
create database cardgame;
use cardgame;

/* identity中0表示玩家，1表示管理员 */
CREATE TABLE IF NOT EXISTS user (
    `name` VARCHAR(50) NOT NULL,
    `phonenumber` VARCHAR(13) NOT NULL,
    `email` VARCHAR(20) NOT NULL,
    `password` VARCHAR(50) NOT NULL,
    `identity` INT DEFAULT 0,
    PRIMARY KEY (`name`)
)  ENGINE=INNODB DEFAULT CHARSET=UTF8MB4;

CREATE TABLE IF NOT EXISTS playerinfo (
    `name` VARCHAR(50) NOT NULL,
    `nickname` VARCHAR(50) NOT NULL,
    `level` VARCHAR(50) NOT NULL,
    `account` INT DEFAULT 0,
    PRIMARY KEY (`name`),
    FOREIGN KEY (`name`)
        REFERENCES user (`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
)  ENGINE=INNODB DEFAULT CHARSET=UTF8MB4;

/* amount中正数表示充值金额，负数表示消费金额 */
CREATE TABLE IF NOT EXISTS bill (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `name` VARCHAR(50) NOT NULL,
    `datetime` DATETIME NOT NULL,
    `amount` INT NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`name`)
        REFERENCES user (`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
)  ENGINE=INNODB DEFAULT CHARSET=UTF8MB4;

CREATE TABLE IF NOT EXISTS card (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `description` TEXT NOT NULL,
    `rarity` INT NOT NULL,
    PRIMARY KEY (`id`)
)  ENGINE=INNODB DEFAULT CHARSET=UTF8MB4;

CREATE TABLE IF NOT EXISTS cardtype (
    `id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `type` VARCHAR(20) NOT NULL,
    PRIMARY KEY (`name`),
    FOREIGN KEY (`id`)
        REFERENCES card (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
)  ENGINE=INNODB DEFAULT CHARSET=UTF8MB4;

CREATE TABLE IF NOT EXISTS cardpacket (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `name` VARCHAR(50) NOT NULL,
    `price` int NOT NULL,
    PRIMARY KEY (`id`)
)  ENGINE=INNODB DEFAULT CHARSET=UTF8MB4;

CREATE TABLE IF NOT EXISTS cardpacketitem (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `packet_id` INT UNSIGNED NOT NULL,
    `cardtype_name` VARCHAR(50) NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`packet_id`)
        REFERENCES cardpacket (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`cardtype_name`)
        REFERENCES cardtype (`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
)  ENGINE=INNODB DEFAULT CHARSET=UTF8MB4;

CREATE TABLE IF NOT EXISTS hascard (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `name` VARCHAR(50) NOT NULL,
    `card_id` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`name`)
        REFERENCES user (`name`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`card_id`)
        REFERENCES card (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
)  ENGINE=INNODB DEFAULT CHARSET=UTF8MB4;

CREATE TABLE IF NOT EXISTS cardgroup (
	`id` INT UNSIGNED AUTO_INCREMENT,
    `name` VARCHAR(50) NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`name`)
        REFERENCES user (`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
)  ENGINE=INNODB DEFAULT CHARSET=UTF8MB4;

CREATE TABLE IF NOT EXISTS cardgroupitem (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `group_id` INT UNSIGNED NOT NULL,
    `card_id` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`group_id`)
        REFERENCES cardgroup (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`card_id`)
        REFERENCES card (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
)  ENGINE=INNODB DEFAULT CHARSET=UTF8MB4;

CREATE TABLE IF NOT EXISTS forbids (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `playername` VARCHAR(50) NOT NULL,
    `managername` VARCHAR(50) NOT NULL,
    `begintime` DATETIME NOT NULL,
    `endtime` DATETIME NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`playername`)
        REFERENCES user (`name`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`managername`)
        REFERENCES user (`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
)  ENGINE=INNODB DEFAULT CHARSET=UTF8MB4;

CREATE TABLE IF NOT EXISTS gamerecord (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `player1name` VARCHAR(50) NOT NULL,
    `player2name` VARCHAR(50) NOT NULL,
    `winner` VARCHAR(50) NOT NULL,
    `playtime` DATETIME NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`player1name`)
        REFERENCES user (`name`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`player2name`)
        REFERENCES user (`name`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`winner`)
        REFERENCES user (`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
)  ENGINE=INNODB DEFAULT CHARSET=UTF8MB4;

CREATE TABLE IF NOT EXISTS matchqueue (
    `playername` VARCHAR(50) NOT NULL,
    `jointime` DATETIME NOT NULL,
    PRIMARY KEY (`playername`),
    FOREIGN KEY (`playername`)
        REFERENCES user (`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
)  ENGINE=INNODB DEFAULT CHARSET=UTF8MB4;