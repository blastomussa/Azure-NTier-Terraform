# Backend Flask API for AKS deployment
from generator import Generator
from flask import Flask, json, jsonify, request, render_template, redirect, url_for

# initialize flask applications
app = Flask(__name__)

# this is the entry point for wsgi deployment (not appicable for Docker image)
application = app

@app.route('/')
def redirect_to_api():
    response = jsonify({'404 Not Found': 'The api can be found at /api/v1'})
    response.status_code = 404
    return response


@app.route('/api/v1', methods=['GET'])
def generate_pw():
    bad_request = False
    choices = set(('first','last','random'))

    # GET PARAMETERS AND VALIDATE USER INPUT
    max = request.args.get('max', default = 18, type = int)
    min = request.args.get('min', default = 8, type = int)
    if max > 100 or max < min: bad_request = True
    if min < 0 or min > max: bad_request = True

    num_words = request.args.get('num_words', default = 2, type = int)
    if num_words < 0 or num_words > 25: bad_request = True

    caps = request.args.get('caps', default = True, type = bool)
    num_caps = request.args.get('num_caps', default = 1, type = int)
    if num_caps < 0 or num_caps > max: bad_request = True
    loc_caps = request.args.get('loc_caps', default = 'first', type = str).lower()
    if loc_caps not in choices:
        bad_request = True

    ints = request.args.get('ints', default = True, type = bool)
    num_ints = request.args.get('num_ints', default = 2, type = int)
    if num_ints < 0 or num_ints > max: bad_request = True
    loc_ints = request.args.get('loc_ints', default = 'last', type = str).lower()
    if loc_ints not in choices:
        bad_request = True

    specs = request.args.get('specs', default = True, type = bool)
    num_specs = request.args.get('page', default = 1, type = int)
    if num_specs < 0 or num_specs > max: bad_request = True
    loc_specs = request.args.get('loc_specs', default = 'last', type = str).lower()
    if loc_specs not in choices:
        bad_request = True

    gib = request.args.get('gib', default = False, type = bool)

    if bad_request == False:
        # build password from given parameters
        generator = Generator()
        string = generator.get_words(max, min, num_words, num_ints, num_specs)
        if caps: string = generator.add_caps(string, num_caps, loc_caps)
        if string != "No password could be generated with the given parameters":
            if ints: string = generator.add_ints(string, num_ints, loc_ints)
            if specs: string = generator.add_specs(string, num_specs, loc_specs)
            if gib: string = generator.gibberish(string)
        # create response json and status_code
        response = jsonify({'password': string})
        response.status_code = 200
        return response
    else:
        response = jsonify({'Bad request': 'Check that parameters are within acceptable range'})
        response.status_code = 400
        return response


# host='0.0.0.0' required to run inside docker image; port 80 for ease of access
if __name__ == '__main__':
    app.run(host='0.0.0.0',port=80)
