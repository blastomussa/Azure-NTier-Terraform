import pymongo
import requests
from datetime import datetime
from flask import Flask, redirect, url_for, request, render_template, jsonify

app = Flask(__name__)


### IMPORTANT: Use ENV variables from Terraform to connect to MongoDB <<<<<<<<<<<<<<-----------https://acloudguru.com/blog/engineering/deploy-a-simple-application-in-azure-using-terraform
# this needs to be a secure secret; create new CosmosDB instance to test
CONNECTION_STRING = None
DB_NAME = 'MongoDB-DB'
UNSHARDED_COLLECTION_NAME = 'MongoDB-Collection'

@app.route('/success')
def success():
    url = 'https://blastomussa.dev/generate/api/v1'
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
        ip = request.remote_addr()
        t = datetime.now()
        user_data = {
            'ip': ip,
            'user': user,
            'time': time
        }
        #mongo(user_data)
        return redirect(url_for('success'))


@app.route("/get_my_ip", methods=["GET"])
def get_my_ip():
    user = request.headers.get('User-Agent')
    ip = request.remote_addr()
    t = datetime.now()
    time = t.strftime("%m/%d/%Y %H:%M:%S")
    json = {
        'ip': ip,
        'user': user,
        'time': time
    }

    return jsonify(json),200

def create_database_unsharded_collection(client):
    """Create sample database with shared throughput if it doesn't exist and an unsharded collection"""
    db = client[DB_NAME]

    # Create database if it doesn't exist
    if DB_NAME not in client.list_database_names():
        # Database with 400 RU throughput that can be shared across the DB's collections
        db.command({'customAction': "CreateDatabase", 'offerThroughput': 400})

    # Create collection if it doesn't exist
    if UNSHARDED_COLLECTION_NAME not in db.list_collection_names():
        # Creates a unsharded collection that uses the DBs shared throughput
        db.command({'customAction': "CreateCollection", 'collection': UNSHARDED_COLLECTION_NAME})

    return db.COLLECTION_NAME

def insert_document(collection, data):
    """Insert a sample document and return the contents of its _id field"""
    document_id = collection.insert_one(data).inserted_id
    print("Inserted document with _id {}".format(document_id))
    return document_id

def mongo( data):
    client = pymongo.MongoClient(CONNECTION_STRING)
    try:
        client.server_info() # validate connection string
    except pymongo.errors.ServerSelectionTimeoutError:
        raise TimeoutError("Invalid API for MongoDB connection string or timed out when attempting to connect")

    collection = create_database_unsharded_collection(client)
    document_id = insert_document(collection, data)

if __name__ == '__main__':
   app.run(debug = True)
