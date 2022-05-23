-- GDELT LOCAL checks
-- Calculate min and max values per year for raw set
SELECT MIN(AvgTone) AS minimum, MAX(AvgTone) AS maximum, Year AS year FROM raw_gdelt GROUP BY year

select
	c.name,
	c2.name
from
	countries c
cross join countries c2 on
	c.iso_code != c2.iso_code
	
-- Create bil_relationship table
select
	c1.name as country,
	c2.name as partner
from
	countries c1
join
     countries c2
     on
	c1.id < c2.id;


-- Calculcate average values per year and relations
select
	avg(tg.tone) as tone,
	br.id as relation_id,
	tg.year as year,
	1 as data_type
from
	temp_gdelt tg
join countries c1 on
	c1.iso_code = tg.country_1
join countries c2 on
	c2.iso_code = tg.country_2
join bil_relationships br on
	(br.country = c1.id
		and br.partner = c2.id)
	or (br.country = c2.id
		and br.partner = c1.id)
group by
	br.id,
	tg.year

-- Add relation_id to raw_gdelt table to try increase processing speed
alter table raw_gdelt add column relation_id int default null;

-- update to add relation_ids
update
	raw_gdelt
set
	relation_id = br.id
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
	rg.month = 197901
	
	
-- Check if relation ids are stored correctly in bil_relationships table
select c1.name, c2.name, c1.id, br.country, c2.id, br.partner, br.id
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
	rg.month = 197901


-- Create indexes for faster processing
create index index_year_country_1_2 on 
raw_gdelt (year, country_1, country_2)

create index index_country_1_2 on 
raw_gdelt (country_1, country_2)

create index index_date on
raw_gdelt (date)

create index tone_index on
raw_gdelt (tone);

-- Investigate processed gdelt data
 select
	*
from
	proc_gdelt pg
join bil_relationships br on
	br.id = pg.id
join countries c1 on
	c1.id = br.country
join countries c2 on
	c2.id = br.partner
where
br.id = 4000
	(c1.iso_code in ('USA', 'CHN')
		and c2.iso_code in ('USA', 'CHN'))
order by year


-- Count data per year
select
	COUNT(event_id),
	year
from
	raw_gdelt
group by
	year
order by
	year asc



-- Investigate USA CHN data
select 
*
from
	proc_gdelt pg
left join bil_relationships br on
	br.id = pg.relation_id
left join countries c1 on
	c1.id = br.country
left join countries c2 on
	c2.id = br.partner
where 
	(c1.iso_code in ('CHN', 'USA')
		and c2.iso_code in ('CHN', 'USA'))
order by year

-- Select data with shift 1 for growth rate
select
	*
from
	proc_gdelt pg1
left join proc_gdelt pg2 on
	pg2.relation_id = pg1.relation_id
	and pg2.year = pg1.year + 1
where
	pg1.data_type = 1


-- Average absolute change per period
select
	AVG(ABS(growth_rate)),
	pe.gov_period
from
	proc_gdelt pg
inner join bil_relationships br on
	br.id = pg.relation_id
	and (br.country = 221
		or br.partner = 221)
join proc_elections pe on
	pe.year = pg."year"
	and pe.country = 221
where
	pg.year between 1979 and 2020
group by
	pe.gov_period
	
SELECT * FROM raw_gdelt WHERE date < 19800101 AND type_1 IN ('GOV') AND type_2 IN ('GOV');

-- Analysis set
select
	pg.tone,
	pg.growth_rate,
	pg.year,
	pe.gov_period
from
	proc_gdelt pg
inner join bil_relationships br on
	br.id = pg.relation_id
	and (br.country = 221
		or br.partner = 221)
join proc_elections pe on
	pe.year = pg."year"
	and pe.country = 221
where
	pg.relation_id = 8871
and pg.data_type = 2
order by year

-- Check relationship ids
select
	*
from
	bil_relationships br
join countries c1 on
	c1.id = br.country
join countries c2 on
	c2.id = br.partner
where c1.iso_code in ('USA', 'CHN')
and c2.iso_code in ('USA', 'CHN')

-- Retrieve a relation_id
select
	*
from
	bil_relationships br
inner join countries country on
	country.id = br.country
inner join countries partner on
	partner.id = br.partner
where 
	(partner.name in ('United States of America', 'Germany', 'Switzerland'))
	and (country.name in ('United States of America', 'Germany', 'Switzerland'))


-- Latest raw data for country pair and year
select * from raw_gdelt rg
inner join countries country on
	country.iso_code = rg.country_1
inner join countries partner on
	partner.iso_code = rg.country_2
where 
	((partner.name IN ('United States of America') and country.name in ('Afghanistan'))
	or (partner.name IN ('United States of America') and country.name in ('Afghanistan')))
--	and (type_1 in ('GOV') or type_2 in ('GOV'))
	and year between 2001 and 2020
order by tone asc