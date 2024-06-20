import pandas as pd
import os
import datetime as dt

def parse_timedelta(x):
    y = x.split(':')
    if '.' in y[0]:
        z = y[0].split('.')
        return pd.Timedelta(days=int(z[0]), hours=int(z[1]), minutes=int(y[1]), seconds=int(round(float(y[2]))))
    return pd.Timedelta(hours=int(y[0]), minutes=int(y[1]), seconds=int(round(float(y[2]))))

filenames = [x.split('.')[0] for x in os.listdir(os.path.join(os.pardir(), 'results', 'uts-feit-labsrv-rg'))]
dfs = []
for filename in filenames:
    filepath = os.path.join(os.curdir, "results", "uts-feit-labsrv-rg", f"{filename}.csv")
    df = pd.read_csv(filepath, encoding='utf-16', dtype={'Usage':object}, parse_dates=['Date'], date_format="%y/%m/%d", cache_dates=True)
    df['Usage'] = df['Usage'].apply(parse_timedelta).apply(lambda x: round(x.total_seconds()/3600, 2))
    df['Quota'] = df['Quota'].apply(parse_timedelta).apply(lambda x: round(x.total_seconds()/3600, 2))
    df['Lab'] = filename
    dfs.append(df)
dfcat = pd.concat(dfs)

dfcat['Usage_Change'] = dfcat.groupby('Email')['Usage'].diff()
dfcat = dfcat[dfcat['Date'] >= pd.to_datetime(dt.date.today - dt.timedelta(days=7))]
pivot = dfcat.pivot_table(index=['Email', 'Lab'], columns='Date', values='Usage_Change')
pivot.reset_index(inplace=True)
pivot = pivot.fillna(0)
pivot['Total_Usage_7d'] = pivot.iloc[:, 2:].sum(axis=1)
pivot = pivot[pivot['Total_Usage_7d'] <= 0]

exceptions = [] # add emails of people you don't want included here (as strings)
pivot = pivot[~pivot['Email'].isin(exceptions)] # ~ = negate boolean series

pivot[['Lab', 'Email', 'Total_Usage_7d']].to_csv("names.csv", index=False)