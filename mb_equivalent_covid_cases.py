# -*- coding: utf-8 -*-
"""
Created on Thu Nov 12 16:38:08 2020

@author: kiern
"""
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.io as pio
import plotly.graph_objects as go
import dash
import dash_core_components as dcc
import dash_html_components as html
from dash.dependencies import Input, Output



pio.renderers.default='browser'
# Getting a clean format chart
def clean_chart_format(fig):
    fig.update_layout(
        paper_bgcolor="white",
        plot_bgcolor="white",
        annotations=[
            go.layout.Annotation(
                x=0.9,
                y=1.02,
                showarrow=False,
                text = 'by kg',
                xref="paper",
                yref="paper",
                textangle=0
            ),
        ],
        font=dict(
            family="Arial, Tahoma, Helvetica",
            size=10,
            color="#404040"
        ),
        margin=dict(
            t=20
        )
    )
    fig.update_traces(marker=dict(line=dict(width=1, color='Navy')),
                      selector=dict(mode='markers'))
    fig.update_coloraxes(
        colorbar=dict(
            thicknessmode="pixels", thickness=15,
            outlinewidth=1,
            outlinecolor='#909090',
            lenmode="pixels", len=300,
            yanchor="top",
            y=1,
        ))
    fig.update_yaxes(showgrid=True, gridwidth=1, tickson='boundaries', gridcolor='LightGray', fixedrange=True)
    fig.update_xaxes(showgrid=True, gridwidth=1, gridcolor='LightGray', fixedrange=True)
    return True

# Options to choose from
Geography = pd.read_excel('list_of_countries.xlsx')
Geography = Geography['Geography'].to_list()

# Getting provincial population data from Stats Can + Cleaning 
province_pop_table = pd.read_html('https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=1710000901')[0]
province_pop_table = province_pop_table.drop(province_pop_table.index[0:2])
province_pop_table['Geography'] = province_pop_table['Geography'].str.split(pat = '(').str[0]
province_pop_table['Geography'] = province_pop_table['Geography'].str.split(pat = '5').str[0]
province_pop_table = province_pop_table[['Geography', 'Q3 2020']]
province_pop_table = province_pop_table.rename( { 'Q3 2020':'Population'}, axis = 'columns')


# Grabbing American states population
states_pop_table = pd.read_html('https://en.wikipedia.org/wiki/List_of_states_and_territories_of_the_United_States_by_population')[0]
states_pop_table = states_pop_table.drop(states_pop_table.index[52:])
states_pop_table = states_pop_table.iloc[:, 2:4 ]
states_pop_table.columns = states_pop_table.columns.droplevel(1)
states_pop_table = states_pop_table.rename(columns = {'State':'Geography', 'Census population':'Population'})

# Grabbing global population
global_pop_table = pd.read_html('https://en.wikipedia.org/wiki/List_of_countries_by_population_(United_Nations)')[3]
global_pop_table = global_pop_table.iloc[:,[0,-2]]
global_pop_table = global_pop_table.rename(columns = {'Country/Territory':'Geography', 'Population(1 July 2019)':'Population'})
global_pop_table['Geography'] = global_pop_table['Geography'].str.split('[').str[0]

# Solving the two Georgias issue
global_pop_table.Geography[global_pop_table.Geography == 'Georgia'] = "Georgia (Country)"

# Appending these datasets
population_table = province_pop_table.append(states_pop_table)
population_table['Population'] = pd.to_numeric(population_table['Population'])
population_table = population_table.append(global_pop_table)
population_table['Population'] = pd.to_numeric(population_table['Population'])



 

app = dash.Dash(__name__)

server = app.server

app.title = 'Manitoba COVID Cases Scaled'
app.layout = html.Div([
    html.Div([
        dcc.Markdown(
            """
            #### Manitoba Cases Scaled to Other Populations

            This page compares Manitoba's daily COVID-19 cases with other regions of the world.
            It is often difficult to conceptualize the numbers in other regions and gauge how we as Manitobans are doing comparatively.
            This tool should help put things in perspective. 

            Use the pulldown to select a region, and choose from Canadian provinces, American states, or OECD countries.


            *Notes*:

            * Australia and the United States as a whole are excluded.
            """
        ),
        html.P([html.Small("the link to my Github is  "), html.A(html.Small("here"), href="https://github.com/kiernang", title="github"), html.Small(".")]),
    ]),
    html.Div([
        dcc.Dropdown(
            id='Region',
            options=[{'label': i, 'value': i} for i in Geography],
            value='Ontario',
            style={'width': '140px'}
        )
    ]),
    dcc.Graph(
        'covid-cases-graph',
        config={'displayModeBar': False}
    )
])


@app.callback(
    Output('covid-cases-graph', 'figure'),
    [Input('Region', 'value')]
)
def update_graph(grpname):
    # Getting data from John Hopkins and cleaning up
    url = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv"
    covid_cases = pd.read_csv(url)
    covid_cases = covid_cases.drop(['Lat', 'Long'], axis = 1)
    covid_cases = covid_cases.drop(covid_cases.index[56:89])
    covid_cases = covid_cases.drop(covid_cases.index[41:43])
    covid_cases = covid_cases.drop(covid_cases.index[8:16])
    covid_cases = covid_cases.reset_index()
    covid_cases = covid_cases.fillna('None')
    covid_cases['Geography'] =np.where(covid_cases['Province/State'] != "None", covid_cases['Province/State'], covid_cases['Country/Region'])
    covid_cases = covid_cases.drop(covid_cases.iloc[:,0:3], axis = 1)
    covid_cases.Geography[covid_cases.Geography == 'Georgia'] = 'Georgia (Country)'
    # We have to transpose the data 
    cols = list(covid_cases.columns)
    cols = [cols[-1]] + cols[:-1]
    covid_cases = covid_cases[cols]
    covid_cases = covid_cases.T
    covid_cases.columns = covid_cases.iloc[0]
    covid_cases = covid_cases.drop(covid_cases.index[0])
    covid_cases = covid_cases.apply(pd.to_numeric)
    covid_cases.index.names = ['Date']
    
    
    # Onto the states
    states_url = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv'
    states_covid_cases = pd.read_csv(states_url)
    states_covid_cases = states_covid_cases.drop(states_covid_cases.iloc[:,0:6], axis = 1)
    states_covid_cases = states_covid_cases.drop(states_covid_cases.iloc[:,1:5], axis = 1)
    states_covid_cases = states_covid_cases.groupby('Province_State').sum()
    states_covid_cases = states_covid_cases.T
    states_covid_cases.index.names = ['Date']
    
    # Combining the two
    covid_cases = pd.merge(covid_cases, states_covid_cases, left_index = True, right_index = True)
    
    
    # Onto daily change 
    covid_cases_daily = covid_cases.diff()
    
    def scaled_graph(country):
        
        scaled_set = pd.DataFrame()
        scaled_set[country] = covid_cases_daily[country]
        scaled_set['Manitoba'] = covid_cases_daily['Manitoba']
        scaled_set['Manitoba Scaled to ' + country + '\'s Population'] = round(covid_cases_daily['Manitoba'] *(population_table[population_table['Geography'] == country]['Population'].iloc[0]/population_table[population_table['Geography'] == 'Manitoba']['Population'].iloc[0])
    , 0)
        scaled_set.index = pd.to_datetime(scaled_set.index)
        fig = px.line(scaled_set, x=scaled_set.index, y=scaled_set.columns,
                  title='Manitoba\'s COVID 19 curve scaled to other populations')
       
        fig.update_layout(legend_title_text='Geography', yaxis_title = 'Daily COVID-19 Cases', xaxis_title = 'Date')
        return fig
    fig = scaled_graph(grpname)
    clean_chart_format(fig)
    return fig


# ===== END - PLOT GRAPH =====

if __name__ == '__main__':
    app.run_server(debug=False)
       