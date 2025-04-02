from flask import Blueprint, request, jsonify
from database import get_db_connection
from utils.security import hash_password, check_password, generate_token
import random

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.json
    email = data['email']
    phone_number = data['phone_number']
    username = data['username']
    password = hash_password(data['password'])

    db = get_db_connection()
    cursor = db.cursor()
    try:
        cursor.execute("INSERT INTO users (email, phone_number, username, password) VALUES (%s, %s, %s, %s)",
                       (email, phone_number, username, password))
        db.commit()
        return jsonify({"message": "User registered successfully"}), 201
    except MySQLdb.IntegrityError:
        return jsonify({"message": "Email or phone number already exists"}), 400
    finally:
        cursor.close()
        db.close()

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.json
    email = data['email']
    password = data['password']

    db = get_db_connection()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
    user = cursor.fetchone()
    cursor.close()
    db.close()

    if user and check_password(user['password'], password):
        token = generate_token(email)
        return jsonify({"message": "Login successful", "token": token}), 200
    else:
        return jsonify({"message": "Invalid email or password"}), 401

@auth_bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    data = request.json
    email = data.get('email')

    db = get_db_connection()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
    user = cursor.fetchone()

    if user:
        otp = str(random.randint(100000, 999999))  # Generate 6-digit OTP
        cursor.execute("UPDATE users SET otp = %s WHERE email = %s", (otp, email))
        db.commit()
        cursor.close()
        db.close()
        return jsonify({"message": "OTP sent to email", "otp": otp})  # Simulate sending
    else:
        return jsonify({"message": "Email not found"}), 404

@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    data = request.json
    email = data['email']
    otp = data['otp']
    new_password = hash_password(data['new_password'])

    db = get_db_connection()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM users WHERE email = %s AND otp = %s", (email, otp))
    user = cursor.fetchone()

    if user:
        cursor.execute("UPDATE users SET password = %s, otp = NULL WHERE email = %s", (new_password, email))
        db.commit()
        cursor.close()
        db.close()
        return jsonify({"message": "Password reset successful"}), 200
    else:
        return jsonify({"message": "Invalid OTP"}), 400
