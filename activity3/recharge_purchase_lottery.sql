use version1;
DROP FUNCTION IF EXISTS lottery;

delimiter $
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
    DECLARE total INTEGER;
    set total = ceil(bill/10 + price);
    set probability1 = total/1000;
    if(probability1 >= 1) then set probability2 = 1;
    else set probability2 = probability1 + total/500;
    end if;
    set randnum = rand();
    
    if(randnum < probability1) then set card_rarity = 2;
    else if(randnum < probability2) then set card_rarity = 1;
		end if;
	end if;
    
    select id into card_id
    from cards
    where rarity = card_rarity
    order by rand()
    limit 1;
    
    return card_id;
    
    
END;
$
delimiter ;


/* 用事务保护？ */
delimiter $$
drop procedure if exists recharge $$
create procedure recharge (
	username varchar(50), 
	amount integer)
begin
declare new_account integer;
declare this_time datetime;

/* 更新用户余额 */
select account into new_account
from playerinfo
where name = username;

set new_account = new_account + amount;

update playerinfo
set account = new_account
where name = username;

/* 添加账单记录 */
select now() into this_time;

insert into bill(name, datetime, amount)
values (username, this_time, amount);
end $$

delimiter $$
drop procedure if exists purchase $$
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

/* 更新用户余额 */
select account into new_account
from players
where name = username;

select price into amount
from card_packet
where name = pname;

set new_account = new_account - amount;

update players
set account = new_account
where name = username;

/* 添加账单记录 */
select now() into this_time;

insert into bills(player_name, time, amount,description)
values (username, this_time, -amount,"buy card_packet");

/* 统计该月充值总额 */
select month(this_time) into this_month;

select year(this_time) into this_year;

select sum(amount) into recharge_amount
from bills
where player_name = username 
	and year(time) = this_year 
    and month(time) = this_month;

/* 根据充值总额抽出五张卡 */
/* 添加hascard记录 */
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

end $$

call purchase("test","test");