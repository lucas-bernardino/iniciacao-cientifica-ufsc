import requests
import pandas as pd
from flask import Flask, Response, make_response
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/csv')
def get_csv():
    all_data = requests.get("http://150.162.217.186:3001/receber").json() # http://150.162.217.34:3001/receber

    df = pd.DataFrame(data=all_data)
    df = df.drop(['_id', 'id', 'createdAt', '__v'], axis=1)
    #print(df)
    df.to_csv(index=False)
    
    csv_data = df.to_csv(index=False)
    
    response = make_response(csv_data)

    response.headers["Content-Disposition"] = "attachment; filename=data.csv"
    response.headers["Content-type"] = "text/csv"
    
    print(df)

    return response    

@app.route('/hi')
def hi():
    return 'SALVE SALVE'


    