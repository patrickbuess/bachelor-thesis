import pandas as pd
import numpy as np
import os
from database.commands import get_list
import statsmodels.api as sm

def regression(datatype=1, name="all"):

    countries = [x[0] for x in get_list(f"select id from countries")]

    result = pd.DataFrame(columns=['country','name', 'coefficient',' tvalue', 'pvalue'])
    rsquared = pd.DataFrame(columns=['country','type', 'value'])

    # Iteriere über sämtliche länder um eine regression durchzuführen
    for country in countries:
        print(country)
        # Erstelle dataframe für regression, basierend auf allen vorhandenen variablen
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
                and (br.country = """ + str(country) +"""
                    or br.partner = """ + str(country) +""")
            join proc_elections pe on
                pe.year = pg."year"
                and pe.country = """ + str(country) +"""
            join proc_elections pe2 on 
                pe2.year = pg."year"
                and (pe2.country = br.country or pe2.country = br.partner)
                and pe2.country != """ + str(country) +"""
            where
                pg.year between 1979 and 2020
                and pg.data_type = """ + str(datatype) +"""
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
        if len(dataframe)>0: 
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

            # Füge Konstante für die Regression hinzu
            X = sm.add_constant(X)
            
            # Erstelle OLS Modell
            model = sm.OLS(Y, X).fit()
            dic = pd.DataFrame.from_dict({
                'country': [country] * len(list(model.params.to_frame().index)),
                'name': list(model.params.to_frame().index),
                'coefficient': list(model.params.to_frame()[0]),
                'tvalue': list(model.tvalues.to_frame()[0]),
                'pvalue': list(model.pvalues.to_frame()[0])
            })
            dicrsquared = pd.DataFrame.from_dict({ 'country': [country] * 2, 'type': ['R-Squared', 'Adjusted R-Squared'], 'value': [model.rsquared, model.rsquared_adj]})

            result = result.append(dic)
            rsquared = rsquared.append(dicrsquared)

    result.to_csv("analysis/statistics/"+name+"_regression_result.csv")
    rsquared.to_csv("analysis/statistics/"+name+"_regression_result_rsquared.csv")
