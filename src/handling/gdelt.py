#!/usr/bin/python
from google.cloud import bigquery
from urllib.request import urlopen
from zipfile import ZipFile
from io import BytesIO
from database.commands import insert_list, get_list, execute_sql
import pandas as pd
import datetime

# Insert data into processed gdelt table
def insert(url, all, year, month="", day=""):

        # Download CSV File
        resp = urlopen(url)
        zipfile = ZipFile(BytesIO(resp.read()))
        chunksize = 10 ** 6
        total_rows = 0

        for chunk in pd.read_csv(zipfile.open(zipfile.namelist()[0]), sep="\t", low_memory=False, header=None, chunksize=chunksize):
            
            # Remove unnecessary data
            if all:
                chunk = chunk.iloc[:, [0,1,2,3,6,7,12,16,17,22,25,26,29,31,32,33,34,57]]
                values_list = ['event_id', 'date', 'month', 'year', 'name_1', 'country_1', 'type_1', 'name_2', 'country_2', 'type_2', 'root_event', 'action', 'quad_class', 'num_mentions', 'num_sources', 'num_articles', 'tone', 'source']
            else:
                chunk = chunk.iloc[:, [0,1,2,3,6,7,12,16,17,22,25,26,29,31,32,33,34]]
                values_list = ['event_id', 'date', 'month', 'year', 'name_1', 'country_1', 'type_1', 'name_2', 'country_2', 'type_2', 'root_event', 'action', 'quad_class', 'num_mentions', 'num_sources', 'num_articles', 'tone']
            
            chunk = chunk[chunk[[7,17]].notnull().all(1)]

            total_rows = total_rows + len(chunk)
            print("Retrieved " + str(total_rows) + " rows for year " + str(year) + str(month) + str(day) + ". Inserting ...")
            
            # In Datenbank speichern
            payload = [tuple(row) for row in chunk.itertuples(index=False)]
            
            insert_list('raw_gdelt', values_list, payload)
            
            print("Inserted " + str(total_rows) + " rows for year " + str(year) + str(month) + str(day) +"!")


# Calculate average tone values from a temp table
def calculateAvg(datatype):

    print("Processing...")

    execute_sql("""
    INSERT INTO proc_gdelt (tone, relation_id, year, data_type)
    select
        temp.tone - rat.tone as tone,
            temp.relation_id,
            temp.year,
            temp.data_type
    from
        (
        select
            avg(tg.tone)as tone,
            br.id as relation_id,
            tg.year as year,
            """ + str(datatype) + """ as data_type
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
    ) temp
    join ref_avg_tones rat on
        rat.year = temp.year
        and rat.data_type = """ + str(datatype) + """
    """)

    execute_sql("TRUNCATE temp_gdelt;")
    
    print("Processed and inserted into proc_gdelt")

# Get chunks from raw gdelt table and add to temp table for further processing
def process(datatype=1):

    execute_sql("TRUNCATE temp_gdelt;")  
    
    # Get max year value for data in the database
    max_date = get_list(f"SELECT Max(year) FROM proc_gdelt WHERE data_type = {datatype};")[0][0]
    max_date = 1979 if max_date is None else max_date

    # delete latest year and start from there again
    execute_sql(f"DELETE FROM proc_gdelt WHERE year = {max_date} AND data_type = {datatype}")

    for year in range(max_date, 2023):

        for month in range(1, 13):
            for day in range(1, 32):
                try:
                    datetime.datetime(int(year), int(month), int(day))
                    print("Inserting rows for year " + str(year) + str(month).zfill(2) + str(day).zfill(2) + ". Inserting ...")
                    execute_sql(f"INSERT INTO temp_gdelt SELECT * FROM raw_gdelt WHERE date = {year}{str(month).zfill(2)}{str(day).zfill(2)};")
                except:
                    continue
        
        calculateAvg(datatype)

# Get subset chunks from the raw gdelt table and add to temp table for further processing
def processSubset(datatype=1, categories=[]):

    execute_sql("TRUNCATE temp_gdelt;")  
    
    # Get max year value for data in the database
    max_date = get_list(f"SELECT Max(year) FROM proc_gdelt WHERE data_type = {datatype};")[0][0]
    max_date = 1979 if max_date is None else max_date

    # delete latest year and start from there again
    categories = ["'"+x+"'" for x in categories]
    execute_sql(f"DELETE FROM proc_gdelt WHERE year = {max_date} AND data_type = {datatype}")

    for year in range(max_date, 2023):

        for month in range(1, 13):
            for day in range(1, 32):
                try:
                    datetime.datetime(int(year), int(month), int(day))
                    print("Inserting rows for year " + str(year) + str(month).zfill(2) + str(day).zfill(2) + ". Inserting ...")
                    execute_sql(f"INSERT INTO temp_gdelt SELECT * FROM raw_gdelt WHERE date = {year}{str(month).zfill(2)}{str(day).zfill(2)} AND type_1 IN ({', '.join(categories)}) AND type_2 IN ({', '.join(categories)});")
                except:
                    continue
        
        calculateAvg(datatype)

# Calculate growth rate in proc_gdelt set
def growthRate(datatype=1):

    # retrieve all relations_ids
    relations = [x[0] for x in get_list(f"select distinct relation_id from proc_gdelt WHERE data_type = {datatype} order by relation_id;")]

    # Calculate and interpolate growth rates for all relation_ids
    for rel in relations:
        print("Processing relation "+ str(rel) + "...")

        dataframe = pd.DataFrame(get_list("""
            select
                dates.year,
                gdelt.tone
            from
                (
                select
                    distinct year
                from
                    proc_gdelt
                order by
                    year) dates
            left join (
                select
                    *
                from
                    proc_gdelt
            ) gdelt on
                gdelt.year = dates.year
                and relation_id = """ + str(rel) + """
                and data_type = """ + str(datatype) + """
            order by dates.year
        """), columns=['year','tone'])
        
        if len(dataframe) > 0:

            # If first tone value is null, add the first non-null value instead
            if pd.isnull(dataframe['tone'][0]):
                initial_value = dataframe['tone'].loc[dataframe['tone'].first_valid_index()]
                dataframe['tone'][0] = initial_value

            # Interpolation of missing values
            dataframe = dataframe.interpolate(method ='linear', limit_direction ='forward')
            
            # Add growth rate column, relation_id, data_tyoe
            dataframe['growth_rate'] = dataframe['tone'].diff() / dataframe['tone'].abs().shift()
            dataframe['growth_rate'][0] = 0

            dataframe['relation_id'] = rel
            dataframe['data_type'] = datatype

            # Create Payload and add back to database after first deleting
            payload = [tuple(row) for row in dataframe[['year', 'relation_id', 'tone', 'growth_rate', 'data_type']].itertuples(index=False)]

            execute_sql(f"DELETE FROM proc_gdelt WHERE relation_id = {rel} AND data_type = {datatype};")
            insert_list('proc_gdelt', ['year', 'relation_id', 'tone', 'growth_rate', 'data_type'], payload)

        print("Processed relation "+ str(rel))


# Create helper table for yearly average tones, this can later be used for faster processing in sql
def handleHelperTables(datatype=1, categories=[], min_sources=1):

    categories = ["'"+x+"'" for x in categories]
    
    print("Deleting old entries")
    execute_sql(f"DELETE FROM ref_avg_tones WHERE data_type = {datatype}")
    
    print("Adding new entries")
    if len(categories)>0:
        execute_sql(f"insert into ref_avg_tones (tone, year, data_type) select AVG(tone) as tone, year, {datatype} as data_type from raw_gdelt where year >= 1979 AND type_1 IN ({', '.join(categories)}) AND type_2 IN ({', '.join(categories)}) AND num_sources >= {min_sources} group by year;")
    else:
        execute_sql(f"insert into ref_avg_tones (tone, year, data_type) select AVG(tone) as tone, year, {datatype} as data_type from raw_gdelt where year >= 1979 AND num_sources >= {min_sources} group by year;")

    print("Added new entries")


# Retrieve GDELT files from links directly, process and insert into raw
def retrieveAndInsertManual():

    execute_sql("TRUNCATE temp_gdelt;")
    
    # Get max year and restart script from there
    
    max_date = get_list("SELECT Max(date) FROM raw_gdelt;")[0][0]
    max_date = 19790101 if max_date is None else max_date

    current_date = datetime.datetime.now()

    max_year = int(str(max_date)[:4])
    max_month = int(str(max_date)[4:6])
    max_day = int(str(max_date)[6:8])
    
    if max_date > 19790101:
        print("Max date: " + str(max_date) + " | Starting over from there")

        if max_year <= 2005:
            print("Deleting latest year and retrieving again.")
            execute_sql("DELETE FROM raw_gdelt WHERE year >= 1979")

        elif int(str(max_year) + str(max_month).zfill(2)) < 201304:
            print("Deleting latest year-month and retrieving again.")
            execute_sql("DELETE FROM raw_gdelt WHERE year >= 2006")

        elif int(str(max_year) + str(max_month).zfill(2) + str(max_day).zfill(2)) < int(current_date.strftime("%Y%m%d")):
            print("Deleting latest year-month and retrieving again.")
            execute_sql("DELETE FROM raw_gdelt WHERE month >= 201304")
        
    
    # earlier files are one a yearly basis
    if max_year <= 2005:
        for year in range(1979, 2006):
            max_year = year
            
            # Download and Insert CSV Files
            insert("http://data.gdeltproject.org/events/"+str(year)+".zip", False, year)

    # Files from 2007 to 201304 are on a monthly basis
    if int(str(max_year) + str(max_month).zfill(2)) < 201304:
        for year in range(2006, 2014):
            max_year = year

            end_month = 13 if year < 2013 else 4
            for month in range(1, end_month):
                max_month = month
                
                # Download and Insert CSV Files
                print("http://data.gdeltproject.org/events/"+str(year)+str(month).zfill(2)+".zip")
                insert("http://data.gdeltproject.org/events/"+str(year)+str(month).zfill(2)+".zip", False, year, month)

    # Files from 201305 are on a daily basis
    if int(str(max_year) + str(max_month).zfill(2) + str(max_day).zfill(2)) < int(current_date.strftime("%Y%m%d")):

        for year in range(2013, 2023):
            max_year = year

            start_month = 4 if year == 2013 else 1
            
            for month in range(start_month, 13):
                for day in range (1, 32):
                    try:
                        datetime.datetime(int(year), int(month), int(day))
                        
                        # Download and Insert CSV Files
                        insert("http://data.gdeltproject.org/events/"+str(year)+str(month).zfill(2)+str(day).zfill(2)+".export.CSV.zip", True, year, month, day)
                    except:
                        continue
            

# Use bigquery api client to retrieve sets (not viable because of high costs)
def retrieveAndInsertBigQuery():

    # Construct a BigQuery client object.
    client = bigquery.Client()

    for year in range(1979, 2023):
        for month in range (1, 13):
            print("Gathering data for " + str(year) + "-" + str(month))
            sum_of_rows = 0
            offset = 0

            additional_rows = True
            while additional_rows:

                query = """
                SELECT
                    DISTINCT GLOBALEVENTID as event_id,
                    MonthYear as month,
                    year as year,
                    SQLDATE as date,
                    Actor1CountryCode as country_1,
                    Actor2CountryCode as country_2,
                    Actor1Type1Code as type_1,
                    Actor2Type1Code as type_2,
                    Actor1Name as name_1,
                    Actor2Name as name_2,
                    IsRootEvent as root_event,
                    EventCode as action,
                    QuadClass as quad_class,
                    AvgTone as tone,
                    NumMentions as num_mentions,
                    NumSources as num_sources,
                    NumArticles as num_articles,
                    SOURCEURL as source,
                    2 AS version
                FROM
                    `gdelt-bq.gdeltv2.events`
                WHERE
                    Actor1CountryCode is not NULL
                    AND Actor2CountryCode is not NULL
                    AND MonthYear = """ + str(year) + str(month).zfill(2) + """ 
                UNION ALL
                SELECT
                    DISTINCT GLOBALEVENTID as event_id,
                    MonthYear as month,
                    year as year,
                    SQLDATE as date,
                    Actor1CountryCode as country_1,
                    Actor2CountryCode as country_2,
                    Actor1Type1Code as type_1,
                    Actor2Type1Code as type_2,
                    Actor1Name as name_1,
                    Actor2Name as name_2,
                    IsRootEvent as root_event,
                    EventCode as action,
                    QuadClass as quad_class,
                    AvgTone as tone,
                    NumMentions as num_mentions,
                    NumSources as num_sources,
                    NumArticles as num_articles,
                    SOURCEURL as source,
                    1 AS version
                FROM
                    `gdelt-bq.full.events`
                WHERE
                    Actor1CountryCode is not NULL
                    AND Actor2CountryCode is not NULL
                    AND MonthYear = """ + str(year) + str(month).zfill(2) + """
                    AND GLOBALEVENTID NOT IN (
                        SELECT
                            DISTINCT GLOBALEVENTID
                        FROM
                            `gdelt-bq.gdeltv2.events`
                        WHERE
                            Actor1CountryCode is not NULL
                            AND Actor2CountryCode is not NULL
                            AND MonthYear = """ + str(year) + str(month).zfill(2) + """ 
                    ) 
                ORDER BY event_id LIMIT 250000 OFFSET """ + str(offset) + """;
                """

                dataframe = (
                    client.query(query)
                    .result()
                    .to_dataframe(
                        create_bqstorage_client=True,
                    )
                )

                if len(dataframe) > 0:

                    sum_of_rows = sum_of_rows + len(dataframe)
                    print("   Inserting " + str(sum_of_rows) + " rows" )
                    # print("Offset " + str(offset))

                    payload = dataframe.to_records(index=False)
                    payload = list(payload)
                    
                    insert_list('raw_gdelt_old', ['event_id', 'month', 'year', 'date', 'country_1', 'country_2', 'type_1', 'type_2', 'name_1', 'name_2', 'root_event', 'action', 'quad_class', 'tone', 'num_mentions', 'num_sources', 'num_articles', 'source', 'version'], payload)

                    offset = offset + 250000

                else:
                    additional_rows = False

