import MySQLdb

def get_db_connection():
    return MySQLdb.connect(
        host="localhost",
        user="root",
        passwd="",  # Keep empty if no password is set
        db="`my_health+`",  # Enclose database name in backticks
        charset="utf8mb4",
        use_unicode=True
    )
