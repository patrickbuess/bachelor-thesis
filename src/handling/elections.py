#!/usr/bin/python
from database.commands import insert_list, execute_sql, get_list
import pandas as pd

# Retrieve elections data and insert into database
def retrieveAndInsert():

    # Clear database table before starting
    execute_sql("TRUNCATE raw_elections;")

    # Load xlsx file
    dataframe = pd.read_excel("handling/data/DPI2020.xlsx")
    dataframe = dataframe[['countryname', 'ifs', 'year', 'system', 'yrsoffc', 'reelect', 'percent1', 'percentl', 'execrlc', 'allhouse']]
    dataframe['year'] = pd.to_datetime(dataframe['year'], "%d.%m.%Y")
    
    # Add to db
    payload = [tuple(row) for row in dataframe.itertuples(index=False)]
    insert_list('raw_elections', ['country_name', 'iso_code', 'date', 'system', 'years_inoffice', 'reelectable', 'percent_first_round', 'percent_final_round', 'leaning', 'allhouse'], payload)
    print("Inserted raw data")

# Clean and process elections data
def process():
    
    # Clear processed elections table before starting
    execute_sql("TRUNCATE proc_elections;")

    # Update iso codes
    execute_sql("""
        update raw_elections set iso_code = 'COD' where iso_code = 'ZAR';
        update raw_elections set iso_code = 'RUS' where iso_code = 'SUN';
        update raw_elections set iso_code = 'ROU' where iso_code = 'ROM';
        update raw_elections set iso_code = 'CZE' where iso_code = 'CSK';
        update raw_elections set iso_code = 'YEM' where iso_code = 'YMD';
        update raw_elections set iso_code = 'TLS' where iso_code = 'TMP';
    """)
    # Only eSwatini, DDR, Turkish Cyprus and Yugoslavien remain

    # Change -999 and NaN values to null
    execute_sql("""
        update raw_elections set system = null where system = '-999';
        update raw_elections set years_inoffice = null where years_inoffice = '-999' OR years_inoffice = 'NaN';
        update raw_elections set percent_first_round = null where percent_first_round = '-999' or percent_first_round = 'NaN';
        update raw_elections set percent_final_round = null where percent_final_round = '-999' or percent_final_round = 'NaN';
        update raw_elections set reelectable = null where reelectable = '-999' or reelectable = 'NaN';
        update raw_elections set allhouse = null where allhouse = '-999' or allhouse = 'NaN';
        update raw_elections set leaning = null where leaning = '-999' OR leaning = 'NaN';
    """)

    # remove countries that are not listed in the countris table
    execute_sql("""
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
    """)
    
    # Remove data before 1979
    # execute_sql("""
    #     delete from raw_elections where date < '1979-01-01';
    # """)

    # Load all iso codes
    iso_codes = [x[0] for x in get_list("SELECT DISTINCT iso_code FROM raw_elections;")]
    
    # Iterate over iso codes and process country
    for country in iso_codes:
        print(country)
        
        # Get raw election data per country from db
        data = pd.DataFrame(get_list(f"""
            select
                c.id as country,
                extract(year from date) as year,
                case when leaning = 'Right' then True else False end as right,
                case when leaning NOT IN ('Left', 'Right') then True else False end as center,
                case when leaning = 'Left' then True else False end as left,
                case when leaning = 'Right' then 0 when leaning = 'Left' then 2 else 1 end as leaning,
                coalesce(years_inoffice, 0) as years_inoffice
            from
                raw_elections re
            join countries c on
                c.iso_code = re.iso_code
            where
                re.iso_code = '{country}'
            order by
                date;
        """), columns=["country", 'year', 'right','center', 'left', 'leaning', 'years_inoffice'])

        # Add additional columns
        data['gov_period'] = None # Unique identifier für die Regierungszeit
        data['election'] = False # Jahre in denen Wahlen stattfanden = True
        data['change'] = 0 # Unterschied der politische ausrichtung zur vorderen regierung

        gov_period = 1
        leaning = 0
        change = 0

        # Calculate change, and election T/F values
        for index, row in data.iterrows():
            election = True if row['years_inoffice'] == 1 else False
            
            if election:
                change = abs(leaning - row['leaning'])
                gov_period = gov_period + 1
                data.loc[index, 'election'] = True
            
            leaning = row['leaning']

            data.loc[index, 'gov_period'] = country + str(gov_period).zfill(2)
            data.loc[index, 'change'] = change

        # Add to proc_elections table
        payload = [tuple(row) for row in data[['country', 'year', 'gov_period', 'years_inoffice', 'right', 'center', 'left', 'election', 'change']].itertuples(index=False)]
        insert_list('proc_elections', ['country', 'year', 'gov_period', 'years_inoffice', '\"right\"', 'center', '\"left\"', 'election', 'change'], payload)

    print("Created processed table")
            
            
            
        