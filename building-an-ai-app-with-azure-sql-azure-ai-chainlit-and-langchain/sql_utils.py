import pyodbc
import os
from dotenv import load_dotenv

load_dotenv()

def get_matching_products(input_text):
    conn_str = os.getenv("AZURE_SQL_CONNECTION_STRING")
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()

    result = []
    try:
        cursor.execute("DECLARE @result TABLE (ProductID INT, ProductName NVARCHAR(255), Price DECIMAL(10,2), Details NVARCHAR(MAX)); EXEC dbo.GetMatchingProducts @InputText = ?; SELECT * FROM @result;", input_text)
        columns = [column[0] for column in cursor.description]
        for row in cursor.fetchall():
            result.append(dict(zip(columns, row)))
    except Exception as e:
        print(f"Database error: {e}")
    finally:
        cursor.close()
        conn.close()

    return result
