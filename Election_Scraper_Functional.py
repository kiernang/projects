# -*- coding: utf-8 -*-

import pandas as pd
import pdfplumber
import os
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import time 
import seaborn as sns
# Before starting, make sure to google the requirements for PDF plumber. You will have to download a couple other packages if you want to use the image preview function
# We're going to keep a list of the ones that didn't work for whatever reason.
didnt_work = []
#Running this takes a bit long. Going to see how long it takes.
timer = time.time()
# This will be useful at the end to see which ones worked / check numbers.
good = 0
no_good = 0
#These are the columns we wish to use
election_data = pd.DataFrame(columns = ['Advertising', 'Candidate', 'Constituency Association Transfers',
       'Party', 'Party Transfers', 'Posters and Pamphlets', 'Riding',
       'Total Spending'] )
# We initiate the loop
for document in os.listdir("C:/Users/kiern/Downloads/Election Data"):
    
    pdf_document = "C:/Users/kiern/Downloads/Election Data/"+document
    pdf = pdfplumber.open(pdf_document)

    try:
        p0 = pdf.pages[0]
    
        #im = p0.to_image()
        #im.reset().debug_tablefinder()
        table = p0.extract_table()
        df_page1 = []
        for sublist in table:
            for item in sublist:
                df_page1.append(item.split('\n')[-1])
        text_page1 = ['Candidate', 'Riding', 'Party']
        #p4 = pdf.pages[3]
        #p4 = p4.crop((0,160,162,577))
        #im = p4.to_image()
        #text_page2 = p4.extract_text()
        #text_page2 = text_page2.split('\n')
        #text_page2 = [text_page2[0], text_page2[1], text_page2[-1]]
        # That was mainly to check. This is probably more useful
        text_page2 = ['Advertising', 'Posters and Pamphlets', 'Total Spending']
        p4 = pdf.pages[3]
        table = p4.extract_table()
        try:
            table = [table[2], table[3],table[21]]
        except IndexError:
            table = [table[1], table[2], table[20]]
        df_page2 = []
        for sublist in table:
            df_page2.append(sublist[-1])
    
        p3 = pdf.pages[2]
        im = p3.to_image()
        text = p3.extract_text()
        text = text.split('\n')
        text = [text[4], text[6]]
        for i in range(2):
            text[i]=text[i].split(' From', 1)[0]
    
        text[0] = text[0].split('association')[1]
        if text[0] != '':
            text[0] = text[0]
        else:
            text[0] = 0
        try:
            text[1] = text[1].split('party')[1]
        except IndexError:
            text[1] = text[1].split('part')[1]
    
        df_page3 = text
    
        text_page3 = ['Constituency Association Transfers', 'Party Transfers']
    
        data = df_page1 + df_page2 + df_page3
        text = text_page1 + text_page2 + text_page3
        df= pd.DataFrame()
        df['Variable'] = text
        df['Value'] = data
        df['Index'] = df['Value'][0]
    
        df = df.pivot(index = 'Index', columns = 'Variable', values = 'Value')
        election_data = election_data.append(df, True)
        good += 1
    except:
        didnt_work.append(document)
        no_good += 1

print('Scraped ' + str(good) + ' documents succesfully. ' + str(no_good) + ' documents were unsuccessful. Check no_good for details.')
# Reordering the columns
cols = election_data.columns.tolist()
cols = cols[-2:-1] + cols[3:4] + cols[1:2] + cols[0:1] + cols[5:-2] + cols[2:3] + cols[4:5] + cols[-1:]
election_data = election_data[cols]
number_columns = cols[3:]

#election_data[number_columns] =election_data[number_columns].fillna(0)
# Convert the string columns that should be numeric to numeric
for col in number_columns:
    election_data[col] = election_data[col].str.replace(',','')
    election_data[col] = pd.to_numeric(election_data[col])
    election_data[col] = election_data[col].fillna(0)


# Onto the results

election_results = pd.read_excel("C:\\Users\\kiern\\Downloads\\Summary_of_Results_GE2019.xls",nrows = 57, header = 0)


# Just need to reshape the data from wide to long 

election_results_long = election_results.melt(id_vars = 'Electoral Division')
election_data_complete = election_data.merge(election_results_long, how = 'left', left_on =['Riding','Party'], right_on = ['Electoral Division', 'variable'])
election_data_complete = election_data_complete.rename(columns = {"value":"Votes"})
election_data_complete = election_data_complete.drop(columns = ['variable', 'Electoral Division'])
# Need the winners too
winners = [1 if name in election_results['Member Elected'].to_list() else 0 for name in election_data['Candidate'].to_list()]
election_data_complete['Elected'] = winners
election_data_complete['Votes'] = pd.to_numeric(election_data_complete['Votes'])
#Manitoba is too big for a map made in Python to be really useful. Will use QGIS instead.

print(time.time() - timer, 'm')
fig, ax = plt.subplots()
sns.scatterplot('Votes','Total Spending',  hue = 'Elected', data = election_data_complete)
plt.title('Candidate Spending vs Votes Received,\n2019 MB Election')
fig, ax = plt.subplots()
election_data_complete.groupby('Riding')['Total Spending'].sum().nlargest(5,'last').plot(kind = 'bar')
plt.title('Top Ridings by Spending\n MB Election 2019')
plt.ylabel('Combined Spending')
plt.tight_layout()

election_data_complete.to_csv('Election_Data_2019.csv')
election_results.nlargest(10,'Declined').plot('Electoral Division', 'Declined', kind = 'bar')
plt.xlabel('Riding')
plt.ylabel('Declined Ballots')
plt.title('Declined Ballots by Riding\nMB Election 2019')
plt.tight_layout()