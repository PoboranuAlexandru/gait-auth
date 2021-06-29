import string
import random
import sys
from flask import Flask, request, jsonify, Response
from flask_cors import CORS
from time import sleep
from threading import Lock
from database import global_db, Users
from cbor2 import dumps, loads
import requests


from twisted.python import log
from twisted.internet import reactor
from twisted.web.server import Site
from twisted.web.wsgi import WSGIResource
from autobahn.twisted.websocket import WebSocketServerFactory, \
    WebSocketServerProtocol
from autobahn.twisted.resource import WebSocketResource, WSGIRootResource


def create_app():
    sleep(5)

    app = Flask(__name__)
    CORS(app)

    app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://licenta:cea_mai_smechera_parola@mysql/users'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['CORS_HEADERS'] = 'Content-Type'
    app.app_context().push()

    db = global_db
    return app, db


app, db = create_app()
db.init_app(app)
db.create_all()


def get_random_string():
    LENGTH = 5

    # choose from all uppercase letter + digits
    letters = string.ascii_uppercase + string.digits
    result = ''.join(random.choice(letters) for _ in range(LENGTH))
    return result


@app.route("/auth/register", methods=["POST"])
def register_user():
    if not request.is_json:
        return Response('Request body is not a json', status=400)

    fields = ['username', 'password']

    payload = request.get_json(silent=True)
    for field in fields:
        if field not in payload:
            return Response(f'{field} is missing', status=400)
        if len(payload[field]) < 8:
            return Response(f'{field} is too short', status=400)
        if len(payload[field]) > 100:
            return Response(f'{field} is too long', status=400)
    
    if Users.query.filter_by(username=payload['username']).first() is not None:
        return Response(f'{payload["username"]} is alredy use', status=400)

    new_token = get_random_string()
    while Users.query.filter_by(user_token=new_token).first() is not None:
        new_token = get_random_string()

    user = Users(user_token=new_token,
                 username=payload['username'], password=payload['password'])

    db.session.add(user)
    db.session.commit()
    return jsonify({'token': new_token}), 201


@app.route("/auth/login", methods=["POST"])
def login_user():
    if not request.is_json:
        return Response(status=403)

    fields = ['username', 'password']

    payload = request.get_json(silent=True)
    for field in fields:
        if field not in payload:
            return Response(status=403)
        if len(payload[field]) < 8:
            return Response(status=403)
        if len(payload[field]) > 100:
            return Response(status=403)

    user = Users.query.filter_by(username=payload['username']).first()

    if user is None:
        return Response(status=403)
    
    if user.password != payload['password']:
        return Response(status=403)

    user.is_logged_in = True
    db.session.add(user)
    db.session.commit()
    return jsonify({'token': user.user_token}), 200


def get_user(request):
    if not request.is_json:
        return Response('Request body is not a json', status=400), False

    field = 'user_token'

    payload = request.get_json(silent=True)
    if field not in payload:
        return Response(f'{field} is missing', status=400), False
    if len(payload[field]) != 5:
        return Response('Invalid token', status=400), False

    # check if the user exist
    user = Users.query.filter_by(user_token=payload[field]).first()
    if user is None:
        return Response('User not found', status=404), False

    return user, True


@app.route("/auth/logout", methods=["POST"])
def logout_user():
    user, isUser = get_user(request)
    if not isUser:
        return user

    user.is_logged_in = False
    db.session.add(user)
    db.session.commit()
    return Response('Logged out successfully', status=200)


@app.route("/auth/request_prediction", methods=["POST"])
def prediction_user():
    user, isUser = get_user(request)
    if not isUser:
        return user

    if user.user_token not in connected:
        return Response('Smartwatch not found', status=404)

    if connected[user.user_token][0].state != WebSocketServerProtocol.STATE_OPEN:
        return Response('Authentication requires to open the smartwatch app', status=404)
    
    connected[user.user_token][0].sendMessage(str.encode('Request data'), False)
    connected[user.user_token][1].acquire()

    pred = connected[user.user_token][2]
    if pred:
        return Response(status=200)
    return Response(status=403)

connected = {}


# WebSocket Server protocol
class SmartwatchServerProtocol(WebSocketServerProtocol):
    def onConnect(self, request):
        print("WebSocket connection request by {}".format(request.peer))

    def onMessage(self, payload, isBinary):
        payload = loads(payload)
        payload['token'] = payload['token'].upper()
        print(payload)

        if payload['closing']:
            del connected[payload['token']]
        elif not payload['data']:
            mutex = Lock()
            mutex.acquire()
            connected[payload['token']] = [self, mutex, False]
        else:
            # sent data to predict
            r = requests.post("http://prediction:5000/", json=payload)

            pred = False
            if r.status_code == 200:
                pred = True

            user = Users.query.filter_by(user_token=payload['token']).first()
            user.are_biometrics_ok = pred
            db.session.add(user)
            db.session.commit()

            connected[payload['token']][2] = pred
            self.sendMessage(str.encode(str(pred)), False)
            connected[payload['token']][1].release()

    
    def onClose(self, was_clean, code, reason):
        print("WebSocket connection closed")


if __name__ == '__main__':
    log.startLogging(sys.stdout)

    # create a Twisted Web resource for our WebSocket server
    wsFactory = WebSocketServerFactory("ws://localhost:5000")
    wsFactory.protocol = SmartwatchServerProtocol
    wsResource = WebSocketResource(wsFactory)

    # create a Twisted Web WSGI resource for our Flask server
    wsgiResource = WSGIResource(reactor, reactor.getThreadPool(), app)

    # create a root resource serving everything via WSGI/Flask, but
    # the path "/ws" served by our WebSocket stuff
    rootResource = WSGIRootResource(wsgiResource, {b'ws': wsResource})

    # create a Twisted Web Site and run everything
    site = Site(rootResource)

    reactor.listenTCP(5000, site)
    reactor.run()