from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route("/api/health")
def health():
    return jsonify(status="ok", service="cloudforge-backend")

@app.route("/api/products")
def products():
    return jsonify(products=[
        {"id": 1, "name": "Laptop", "price": 799},
        {"id": 2, "name": "Headphones", "price": 59},
        {"id": 3, "name": "Keyboard", "price": 29},
    ])

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
