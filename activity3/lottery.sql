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

select lottery(99,100);

