from flask import Flask, request, jsonify
from flask_mysqldb import MySQL
import bcrypt

app = Flask(__name__)

# MySQL database configuration
app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = ''  # Update if you have a password
app.config['MYSQL_DB'] = 'my_health+'
app.config['MYSQL_CURSORCLASS'] = 'DictCursor'

mysql = MySQL(app)

# Check database connection
@app.before_request
def check_db_connection():
    try:
        cursor = mysql.connection.cursor()
        cursor.execute('SELECT 1')
        cursor.close()
        print("Database connection successful")
    except Exception as e:
        print(f"Database connection failed: {e}")

# Root route
@app.route('/', methods=['GET'])
def home():
    return "Welcome to the Health App API"

# User Registration API
@app.route('/register', methods=['POST'])
def register_user():
    data = request.json  # Get JSON data from Flutter
    username = data.get('Username')
    email = data.get('Email')
    password = data.get('Password')  # Raw password from user
    phone = data.get('PhoneNo')

    if not all([username, email, password, phone]):
        return jsonify({"error": "All fields are required"}), 400

    try:
        cursor = mysql.connection.cursor()
        
        # Hash password before storing
        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

        query = "INSERT INTO user (Username, Email, Password, PhoneNo) VALUES (%s, %s, %s, %s)"
        cursor.execute(query, (username, email, hashed_password, phone))
        mysql.connection.commit()
        cursor.close()

        return jsonify({"message": "User registered successfully"}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# User Login API
@app.route('/login', methods=['POST'])
def login_user():
    data = request.json
    email = data.get('Email')
    password = data.get('Password')

    if not all([email, password]):
        return jsonify({"error": "Email and password are required"}), 400

    try:
        cursor = mysql.connection.cursor()
        query = "SELECT * FROM user WHERE Email = %s"
        cursor.execute(query, (email,))
        user = cursor.fetchone()
        cursor.close()

        if user and bcrypt.checkpw(password.encode('utf-8'), user['Password'].encode('utf-8')):
            return jsonify({"message": "Login successful", "user": user}), 200
        else:
            return jsonify({"error": "Invalid email or password"}), 401

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
