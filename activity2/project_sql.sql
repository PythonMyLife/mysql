/*==============================================================*/
/* DBMS name:      MySQL 5.0                                    */
/* Created on:     2019/5/8 19:41:15                            */
/*==============================================================*/


drop table if exists Authorization;

drop table if exists Bill;

drop table if exists Card;

drop table if exists CardGroup;

drop table if exists CardGroupItem;

drop table if exists CardPacket;

drop table if exists CardType;

drop table if exists GameRecord;

drop table if exists PlayerInfo;

drop table if exists User;

drop table if exists forbids;

drop table if exists hasCard;

drop table if exists matchQueue;

drop table if exists packetItem;

drop table if exists playerList;

drop table if exists playingRecord;

drop table if exists role;

/*==============================================================*/
/* Table: Authorization                                         */
/*==============================================================*/
create table Authorization
(
   operation            varchar(10),
   autho_id             varchar(20) not null,
   identity             varchar(10) not null,
   primary key (autho_id)
);

/*==============================================================*/
/* Table: Bill                                                  */
/*==============================================================*/
create table Bill
(
   id                   varchar(20) not null,
   name                 varchar(50),
   date_time            datetime not null,
   amount               int not null,
   description          text,
   primary key (id)
);

/*==============================================================*/
/* Table: Card                                                  */
/*==============================================================*/
create table Card
(
   card_id              varchar(20) not null,
   card_name            varchar(50) not null,
   description          text,
   rarity               int,
   primary key (card_id)
);

/*==============================================================*/
/* Table: CardGroup                                             */
/*==============================================================*/
create table CardGroup
(
   group_id             varchar(20) not null,
   name                 varchar(50),
   primary key (group_id)
);

/*==============================================================*/
/* Table: CardGroupItem                                         */
/*==============================================================*/
create table CardGroupItem
(
   group_id             varchar(20) not null,
   card_id              varchar(20) not null,
   primary key (group_id, card_id)
);

/*==============================================================*/
/* Table: CardPacket                                            */
/*==============================================================*/
create table CardPacket
(
   price                int,
   packet_name          varchar(20) not null,
   primary key (packet_name)
);

/*==============================================================*/
/* Table: CardType                                              */
/*==============================================================*/
create table CardType
(
   type                 varchar(20),
   card_name            varchar(50) not null,
   primary key (card_name)
);

/*==============================================================*/
/* Table: GameRecord                                            */
/*==============================================================*/
create table GameRecord
(
   name                 varchar(50) not null,
   Use_name             varchar(50) not null,
   record_id            varchar(20),
   playTime             datetime,
   winner               varchar(50),
   primary key (name, Use_name)
);

/*==============================================================*/
/* Table: PlayerInfo                                            */
/*==============================================================*/
create table PlayerInfo
(
   name                 varchar(50),
   nickname             varchar(50),
   account              int,
   rank                 varchar(50)
);

/*==============================================================*/
/* Table: User                                                  */
/*==============================================================*/
create table User
(
   name                 varchar(50) not null,
   identity             varchar(10) not null,
   Use_name             varchar(50),
   pla_name             varchar(50),
   phonenumber          varchar(13) not null,
   email                varchar(20) not null,
   password             varchar(50) not null,
   primary key (name)
);

/*==============================================================*/
/* Table: forbids                                               */
/*==============================================================*/
create table forbids
(
   name                 varchar(50) not null,
   Use_name             varchar(50) not null,
   forbidTime           datetime,
   forbitEndTime        datetime,
   primary key (name, Use_name)
);

/*==============================================================*/
/* Table: hasCard                                               */
/*==============================================================*/
create table hasCard
(
   name                 varchar(50) not null,
   card_id              varchar(20) not null,
   has_id               varchar(20),
   primary key (name, card_id)
);

/*==============================================================*/
/* Table: matchQueue                                            */
/*==============================================================*/
create table matchQueue
(
   name                 varchar(50),
   joinTime             datetime
);

/*==============================================================*/
/* Table: packetItem                                            */
/*==============================================================*/
create table packetItem
(
   card_name            varchar(50) not null,
   packet_name          varchar(20) not null,
   primary key (card_name, packet_name)
);

/*==============================================================*/
/* Table: playerList                                            */
/*==============================================================*/
create table playerList
(
   Use_name             varchar(50) not null,
   name                 varchar(50) not null,
   playing_id           varchar(20),
   primary key (Use_name, name)
);

/*==============================================================*/
/* Table: playingRecord                                         */
/*==============================================================*/
create table playingRecord
(
   Use_name             varchar(50),
   name                 varchar(50),
   actor                varchar(50),
   action               varchar(20)
);

/*==============================================================*/
/* Table: role                                                  */
/*==============================================================*/
create table role
(
   identity             varchar(10) not null,
   primary key (identity)
);

alter table Authorization add constraint FK_authorize foreign key (identity)
      references role (identity) on delete restrict on update restrict;

alter table Bill add constraint FK_expense foreign key (name)
      references User (name) on delete restrict on update restrict;

alter table Card add constraint FK_cardType foreign key (card_name)
      references CardType (card_name) on delete restrict on update restrict;

alter table CardGroup add constraint FK_hasGroup foreign key (name)
      references User (name) on delete restrict on update restrict;

alter table CardGroupItem add constraint FK_CardGroupItem foreign key (group_id)
      references CardGroup (group_id) on delete restrict on update restrict;

alter table CardGroupItem add constraint FK_CardGroupItem2 foreign key (card_id)
      references Card (card_id) on delete restrict on update restrict;

alter table GameRecord add constraint FK_GameRecord foreign key (name)
      references User (name) on delete restrict on update restrict;

alter table GameRecord add constraint FK_GameRecord2 foreign key (Use_name)
      references User (name) on delete restrict on update restrict;

alter table PlayerInfo add constraint FK_detail foreign key (name)
      references User (name) on delete restrict on update restrict;

alter table User add constraint FK_player3 foreign key (Use_name, pla_name)
      references playerList (Use_name, name) on delete restrict on update restrict;

alter table User add constraint FK_roleMapping foreign key (identity)
      references role (identity) on delete restrict on update restrict;

alter table forbids add constraint FK_forbids foreign key (name)
      references User (name) on delete restrict on update restrict;

alter table forbids add constraint FK_forbids2 foreign key (Use_name)
      references User (name) on delete restrict on update restrict;

alter table hasCard add constraint FK_hasCard foreign key (name)
      references User (name) on delete restrict on update restrict;

alter table hasCard add constraint FK_hasCard2 foreign key (card_id)
      references Card (card_id) on delete restrict on update restrict;

alter table matchQueue add constraint FK_playing foreign key (name)
      references User (name) on delete restrict on update restrict;

alter table packetItem add constraint FK_packetItem foreign key (card_name)
      references CardType (card_name) on delete restrict on update restrict;

alter table packetItem add constraint FK_packetItem2 foreign key (packet_name)
      references CardPacket (packet_name) on delete restrict on update restrict;

alter table playerList add constraint FK_player1 foreign key (Use_name)
      references User (name) on delete restrict on update restrict;

alter table playerList add constraint FK_player2 foreign key (name)
      references User (name) on delete restrict on update restrict;

alter table playingRecord add constraint FK_records foreign key (Use_name, name)
      references playerList (Use_name, name) on delete restrict on update restrict;

