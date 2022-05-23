import psycopg2
from database.config import config

# Retrieve multiple values from db
def get_list(query):
    """ retrieve multiple rows from db """
    conn = None
    sql = query
    try:
        params = config()
        conn = psycopg2.connect(**params)
        cur = conn.cursor()
        cur.execute(sql)
        rows = cur.fetchall()
        cur.close()
        return rows
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()

# Execute arbitrary sql statement
def execute_sql(query):
    """ execute sql statement """
    conn = None
    sql = query
    try:
        params = config()
        conn = psycopg2.connect(**params)
        cur = conn.cursor()
        cur.execute(sql)
        conn.commit()
        cur.close()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()

# Insert multiple values into database
def insert_list(table, values, payload):
    """ insert multiple rows into table  """

    sql = f"INSERT INTO {table}({','.join(values)}) VALUES({', '.join(['%s' for x in values])})"
    conn = None
    try:
        # read database configuration
        params = config()
        # connect to the PostgreSQL database
        conn = psycopg2.connect(**params)
        # create a new cursor
        cur = conn.cursor()
        # execute the INSERT statement
        cur.executemany(sql,payload)
        # commit the changes to the database
        conn.commit()
        # close communication with the database
        cur.close()

    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()