import pandas as pd
import numpy as np
from database.commands import get_list
import statsmodels.api as sm

# Create regression dataset based on all data for usa
dataframe = pd.DataFrame(get_list("""
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
"""), columns=[
            'year',
            'tone',
            'right',
            'center',
            'left',
            'years_inoffice',
            'change',
            'election',
            'partner_right',
            'partner_center',
            'partner_left',
            'partner_years_inoffice',
            'partner_change',
            'partner_election',
            ])

X = dataframe[[
            'right',
            'center',
            'left',
            'years_inoffice',
            'change',
            'election',
            'partner_right',
            'partner_center',
            'partner_left',
            'partner_years_inoffice',
            'partner_change',
            'partner_election',
            ]]


Y = dataframe[[
            'tone'
            ]]

# Add constant independent variables
X = sm.add_constant(X)
 
# Create OLS modell
model = sm.OLS(Y, X).fit()
predictions = model.predict(X) 

print_model = model.summary()
print(print_model)


# Create dataset with average values per relation and gov period, to exclude inner periodical variance
dataframe = pd.DataFrame(get_list("""
    select
        distinct temp.*,
        case when pe."right" is true then 1 else 0 end as "right",
        case when pe."center" is true then 1 else 0	end as "center",
        case when pe."left" is true then 1 else 0 end as "left",
        pe.change
    from
        (
        select
            pe.gov_period,
            AVG(pg.tone),
            max(pe.years_inoffice) as years_inoffice,
            pg.relation_id
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
            and pg.data_type = 1
        group by
            pe.gov_period,
            pg.relation_id
    ) temp
    join proc_elections pe on
        pe.gov_period = temp.gov_period
	and pe.country = 221
"""), columns=[
            'gov_period',
            'avg',
            'years_inoffice',
            'relation_id',
            'right',
            'center',
            'left',
            'change'
            ])

X = dataframe[[
            'years_inoffice',
            'right',
            'center',
            'left',
            'change'
            ]]


Y = dataframe[[
            'avg'
            ]]

# Add constant independent variables
X = sm.add_constant(X)
 
# Create OLS modell
model = sm.OLS(Y, X).fit()
predictions = model.predict(X) 

print_model = model.summary()
print(print_model)