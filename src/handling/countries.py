#!/usr/bin/python
from database.commands import insert_list, execute_sql
import pandas as pd

# Retrieve data from csv and insert into database
def retrieveAndInsert():

    # Clear db table before starting
    execute_sql("TRUNCATE proc_elections, bil_relationships, countries RESTART IDENTITY;")

    # Load csv
    dataframe = pd.read_csv("handling/data/countries.csv")
    dataframe = dataframe[['iso_code', 'name']]
    
    # Add to db
    payload = [tuple(row) for row in dataframe.itertuples(index=False)]
    insert_list('countries', ['iso_code', 'name'], payload)

    print("Created countries table")

# Create country relationship tuples
def process():

    # Clear bil_relationships table before starting
    execute_sql("TRUNCATE bil_relationships RESTART IDENTITY;")

    # Create combos
    execute_sql("""
        INSERT INTO bil_relationships (country, partner)
        select
            c1.id as country,
            c2.id as partner
        from
            countries c1
        join
            countries c2
            on
            c1.id < c2.id;
    """)

    print("Created relationship table")
    

