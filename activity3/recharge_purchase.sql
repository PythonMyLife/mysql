use cardgame;

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
    DECLARE card_rarity integer DEFAULT 1;
    DECLARE card_id INTEGER;
    DECLARE total INTEGER;
    set total = ceil(bill/10 + price);
    set probability1 = total/1000;
    if(probability1 >= 1) then set probability2 = 1;
    else set probability2 = probability1 + total/500;
    end if;
    set randnum = rand();
    
    if(randnum < probability1) then set card_rarity = 3;
    else if(randnum < probability2) then set card_rarity = 2;
		end if;
	end if;
    
    select id into card_id
    from card
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
declare c1, c2, c3, c4, c5 integer unsigned;
declare num integer unsigned;

/* 更新用户余额 */
select account into new_account
from playerinfo
where name = username;

select price into amount
from cardpacket
where name = pname;

set new_account = new_account - amount;

update playerinfo
set account = new_account
where name = username;

/* 添加账单记录 */
select now() into this_time;

insert into bill(name, datetime, amount)
values (username, this_time, -amount);

/* 统计该月充值总额 */
select month(this_time) into this_month;

select year(this_time) into this_year;

select sum(amount) into recharge_amount
from bill
where name = username 
	and year(datetime) = this_year 
    and month(datetime) = this_month;

/* 根据充值总额抽出五张卡 */
set c1 = lottery(recharge_amount, amount);
set c2 = lottery(recharge_amount, amount);
set c3 = lottery(recharge_amount, amount);
set c4 = lottery(recharge_amount, amount);
set c5 = lottery(recharge_amount, amount);

/* 添加hascard记录 */
set num = 0;
select number into num from hascard where name = username and card_id = c1;
if(num <>0) then update hascard set number= num+1 where name=username and card_id=c1;
else insert into hascard(name, card_id, number) values (username, c1, 1);
end if;

end $$

call purchase("test","packet");