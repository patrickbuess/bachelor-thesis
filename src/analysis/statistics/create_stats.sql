-- Minimum und Maximum values pro jahr
SELECT MIN(AvgTone) AS minimum, MAX(AvgTone) AS maximum, Year AS year FROM raw_gdelt GROUP BY year

-- Anzahl events pro Jahr
SELECT COUNT(DISTINCT event_id) AS count, Year as year FROM raw_gdelt GROUP BY year

-- Anzahl events pro Beziehung
select
	temp.number,
	temp.relationship,
	c1.iso_code as country_iso,
	c1."name" as country_name,
	c2.iso_code as partner_iso,
	c2."name" as partner_name
from
	(
	select
		COUNT(distinct rg.event_id) as number,
		br.id as relationship
	from
		raw_gdelt rg
	join countries c1 on
		c1.iso_code = rg.country_1
	join countries c2 on
		c2.iso_code = rg.country_2
	join bil_relationships br on
		(br.country = c1.id
			and br.partner = c2.id)
		or (br.country = c2.id
			and br.partner = c1.id)
	group by
		br.id
) temp
join bil_relationships br on
	temp.relationship = br.id
join countries c1 on
	c1.id = br.country
join countries c2 on
	c2.id = br.partner
order by
	temp.number desc

-- Bez UKR und RUS im detail
	select
		AVG(tone) as tone,
		rg.year
	from
		raw_gdelt rg
	join countries c1 on
		c1.iso_code = rg.country_1
	join countries c2 on
		c2.iso_code = rg.country_2
	INNER join bil_relationships br on
		(br.country = c1.id
			and br.partner = c2.id)
		or (br.country = c2.id
			and br.partner = c1.id)
    WHERE br.id = 25122
	group by
		year
    ORDER BY year ASC

-- Detail beziehungen USA, GER, CHE
select
	temp.tone,
	temp.year,
	temp.id,
	c1.iso_code as country_iso,
	c1."name" as country_name,
	c2.iso_code as partner_iso,
	c2."name" as partner_name
from
	(
	select
		AVG(tone) as tone,
		rg.year,
		br.id
	from
		raw_gdelt rg
	join countries c1 on
		c1.iso_code = rg.country_1
	join countries c2 on
		c2.iso_code = rg.country_2
	join bil_relationships br on
		(br.country = c1.id
			and br.partner = c2.id)
		or (br.country = c2.id
			and br.partner = c1.id)
	where
		year >= 1979
		and br.id in (14751, 14770, 26551)
	group by
		year,
		br.id
) temp
join bil_relationships br on
	temp.id = br.id
join countries c1 on
	c1.id = br.country
join countries c2 on
	c2.id = br.partner
order by
	temp.id asc,
	temp.year asc;

-- Korrigierte Detail bez USA, CHE, GER, UKR, RUS
select
	pg.year,
	pg.tone,
	c1.iso_code as country_iso,
	c1."name" as country_name,
	c2.iso_code as partner_iso,
	c2."name" as partner_name
from
	proc_gdelt pg
join bil_relationships br on
	br.id = pg.relation_id
join countries c1 on
	c1.id = br.country
join countries c2 on
	c2.id = br.partner
where
	pg.relation_id in (14751, 14770, 26551, 25122)
	order by year asc
	

-- Regression daten für USA

    select
        pg.year,
        pg.tone,
        case when pe."right" is true then 1 else 0 end as "right",
        case when pe."center" is true then 1 else 0 end as "center",
        case when pe."left" is true then 1 else 0 end as "left",
        pe.years_inoffice,
        pe.change,
        case when pe."election" is true then 1 else 0 end as "election",
        case when pe2."right" is true then 1 else 0 end as "partner_right",
        case when pe2."center" is true then 1 else 0 end as "partner_center",
        case when pe2."left" is true then 1 else 0 end as "partner_left",
        pe2.years_inoffice as partner_years_inoffice,
        pe2.change as partner_change,
        case when pe2."election" is true then 1 else 0 end as "partner_election"
    from
        proc_gdelt pg
    inner join bil_relationships br on
        br.id = pg.relation_id
        and (br.country = 221
            or br.partner = 221)
    join proc_elections pe on
        pe.year = pg."year"
        and pe.country = 221
    join proc_elections pe2 on 
        pe2.year = pg."year"
        and (pe2.country = br.country or pe2.country = br.partner)
        and pe2.country != 221
    where
        pg.year between 1979 and 2020
        and pg.data_type = 1


-- russland niederlande in detail
select
	pg.year,
	pg.tone,
	c1.iso_code as country_iso,
	c1."name" as country_name,
	c2.iso_code as partner_iso,
	c2."name" as partner_name,
	pg.data_type 
from
	proc_gdelt pg
join bil_relationships br on
	br.id = pg.relation_id
join countries c1 on
	c1.id = br.country
join countries c2 on
	c2.id = br.partner
where
	pg.relation_id in (22871)
	order by year asc

-- USA irak in detail
select
	pg.year,
	pg.tone,
	c1.iso_code as country_iso,
	c1."name" as country_name,
	c2.iso_code as partner_iso,
	c2."name" as partner_name,
	pg.data_type 
from
	proc_gdelt pg
join bil_relationships br on
	br.id = pg.relation_id
join countries c1 on
	c1.id = br.country
join countries c2 on
	c2.id = br.partner
where
	pg.relation_id in (17563)
	order by year asc
