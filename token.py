from flask import Flask, request, jsonify
from google.oauth2 import id_token
from google.auth.transport import requests

app = Flask(__name__)

@app.route('/')  # Endpoint for JavaScript to call
def userinfo():
    print(request.headers)
    token = request.headers.get('X-Goog-IAP-JWT-Assertion')
    token1 = request.headers.get('X-Goog-Authenticated-User-ID')

    try:
        # Specify the audience (who issued the token)
        idinfo = id_token.verify_oauth2_token(token1, requests.Request(), audience='sts.google.com')
        print(f"Decoded token information:\n{idinfo}")
    except ValueError as e:
        print(f"Invalid token: {e}")

    return jsonify([{'token': token},{'token1': token1}])


if __name__ == '__main__':
    app.run(debug=True, port=8080)