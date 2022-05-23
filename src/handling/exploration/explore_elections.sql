-- Investiage elections data

-- Are all countries available
select distinct re.iso_code, re.country_name, c.name from raw_elections re
left join countries c on c.iso_code = re.iso_code
where c.name is null
--> Some countries are not available in the data

-- Clean wrong country iso names
--update raw_elections set iso_code = 'COD' where iso_code = 'ZAR';
--update raw_elections set iso_code = 'RUS' where iso_code = 'SUN';
--update raw_elections set iso_code = 'ROU' where iso_code = 'ROM';
--update raw_elections set iso_code = 'CZE' where iso_code = 'CSK';
--update raw_elections set iso_code = 'YEM' where iso_code = 'YMD';
--update raw_elections set iso_code = 'TLS' where iso_code = 'TMP';

--Change -999 and NaN values NULL
--update raw_elections set system = null where system = '-999';
--update raw_elections set years_inoffice = null where years_inoffice = '-999';
--update raw_elections set percent_first_round = null where percent_first_round = '-999' or percent_first_round = 'NaN';
--update raw_elections set percent_final_round = null where percent_final_round = '-999' or percent_final_round = 'NaN';
--update raw_elections set reelectable = null where reelectable = '-999' or reelectable = 'NaN';
--update raw_elections set allhouse = null where allhouse = '-999' or allhouse = 'NaN';
--update raw_elections set leaning = null where leaning = '-999' OR leaning = 'NaN';

-- Remove countries that are not present in the countries tables
delete
from
	raw_elections
where
	iso_code in (
	select
		distinct re.iso_code
	from
		raw_elections re
	left join countries c on
		c.iso_code = re.iso_code
	where
		c.name is null)

-- Is data available for every country from 1979 to 2020
select
	COUNT(distinct extract(year from date)),
	iso_code
from
	raw_elections re
where
	date between '1979-01-01' and '2020-12-31'
	and leaning is not NULL
group by
	iso_code;
	
