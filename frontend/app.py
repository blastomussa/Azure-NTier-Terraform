import pymongo
import requests
from os import getenv
from datetime import datetime
from flask import Flask, redirect, url_for, request, render_template, jsonify

app = Flask(__name__)
# this is the entry point for wsgi deployment
application = app


# use getenv to get variables set by terraform to constuct CONNECTION_STRING
COSMOS_ACC_NAME = getenv('COSMOS_ACC_NAME')
PRIMARY_KEY = getenv('COSMOS_PRIMARY_KEY')
DB_NAME = getenv('COSMOS_DB_NAME')
COLLECTION_NAME = getenv('COSMOS_COLL_NAME')
CONNECTION_STRING = "mongodb://" + str(COSMOS_ACC_NAME) + ":" + str(PRIMARY_KEY) + "@" + str(COSMOS_ACC_NAME) + ".mongo.cosmos.azure.com:10255/?ssl=true\u0026replicaSet=globaldb\u0026retrywrites=false\u0026maxIdleTimeMS=120000\u0026appName=@" + str(COSMOS_ACC_NAME) + "@"


@app.route('/success')
def success():
    url = 'https://blastomussa.dev/generate/api/v1' #  API URL MIGHT BE FROM ENV VARIABLE TOO; FQDN or Private IP of backend API
    response = requests.get(url)
    pw =response.json()
    p = pw['password']
    return render_template('success.html', shortcode=p)

@app.route('/',methods = ['GET','POST'])
def button():
    if request.method == 'GET':
        return render_template("button.html")
    elif request.method == 'POST':
        user = request.headers.get('User-Agent')
        ip = request.remote_addr
        time = datetime.now()
        user_data = {
            'ip': ip,
            'user': user,
            'time': time
        }
        mongo(user_data)     ######WORKS BUT NEEDS BETTER DATA
        return redirect(url_for('success'))


@app.route("/get_my_ip", methods=["GET"])
def get_my_ip():
    user = request.headers.get('User-Agent')
    ip = request.remote_addr
    t = datetime.now()
    time = t.strftime("%m/%d/%Y %H:%M:%S")
    json = {
        'ip': ip,
        'user': user,
        'time': time
    }
    return jsonify(json),200


def insert_document(collection, data):
    """Insert a sample document and return the contents of its _id field"""
    document_id = collection.insert_one(data).inserted_id
    print("Inserted document with _id {}".format(document_id))
    return document_id


def mongo(data):
    client = pymongo.MongoClient(CONNECTION_STRING)
    try:
        client.server_info() # validate connection string
    except pymongo.errors.ServerSelectionTimeoutError:
        raise TimeoutError("Invalid API for MongoDB connection string or timed out when attempting to connect")

    db = client[DB_NAME]

    collection = db.test_collection  ### how do i use variable after dot(.)
    document_id = insert_document(collection, data)

if __name__ == '__main__':
   app.run(host='0.0.0.0',port=80)
