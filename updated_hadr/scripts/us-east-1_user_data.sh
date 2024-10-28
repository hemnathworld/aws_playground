#!/bin/bash
# Update and install required packages
sudo apt update -y
sudo apt install -y apache2 s3fs python3-pip awscli

# Start and enable Apache service
sudo systemctl start apache2
sudo systemctl enable apache2

# Install Flask and boto3 for Python
pip3 install flask boto3
pip3 install flask-cors


# Mount the S3 bucket using s3fs
sudo mkdir /var/www/html/app
s3fs hemtestbucket-hadr-us-east-1 /var/www/html/app -o iam_role=ec2_dynamo_s3_access_role -o allow_other
chmod 755 /var/www/html/app/*

# Create a simple Flask API application for DynamoDB access
cat <<EOL > /var/www/html/customer_management.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Customer Management - us-east-1 </title>
    <script>
        async function insertData() {
            const data = {
                customer_id: document.getElementById('customer_id').value,
                name: document.getElementById('name').value,
                address: document.getElementById('address').value,
                phone_number: document.getElementById('phone_number').value
            };

            try {
                const response = await fetch('http://172.31.91.64:5000/insert', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(data)
                });

                const result = await response.json();
                alert(result.message || result.error);
            } catch (error) {
                console.error('Error:', error);
                alert('Failed to insert data.');
            }
        }

        async function fetchData() {
            try {
                const response = await fetch('http://172.31.91.64:5000/read', {
                    method: 'GET',
                    headers: {
                        'Content-Type': 'application/json'
                    }
                });

                const data = await response.json();

                const table = document.getElementById('customerTable');
                table.innerHTML = '<tr><th>Customer ID</th><th>Name</th><th>Address</th><th>Phone Number</th></tr>';

                data.forEach(item => {
                    const row = table.insertRow();
                    row.insertCell(0).innerText = item.customer_id;
                    row.insertCell(1).innerText = item.name;
                    row.insertCell(2).innerText = item.address;
                    row.insertCell(3).innerText = item.phone_number;
                });
            } catch (error) {
                console.error('Error:', error);
                alert('Failed to retrieve data.');
            }
        }
    </script>
</head>
<body>
    <h1>Customer Management - us-east-1</h1>

    <h2>Add Customer</h2>
    <form onsubmit="event.preventDefault(); insertData();">
        <label for="customer_id">Customer ID:</label>
        <input type="text" id="customer_id" required><br><br>

        <label for="name">Name:</label>
        <input type="text" id="name" required><br><br>

        <label for="address">Address:</label>
        <input type="text" id="address" required><br><br>

        <label for="phone_number">Phone Number:</label>
        <input type="text" id="phone_number" required><br><br>

        <button type="submit">Add Customer</button>
    </form>

    <h2>Customer List</h2>
    <button onclick="fetchData()">Retrieve Customers</button>

    <table id="customerTable" border="1" style="margin-top: 20px; width: 100%;">
        <tr><th>Customer ID</th><th>Name</th><th>Address</th><th>Phone Number</th></tr>
    </table>
</body>
</html>
EOL

cat <<EOL > /var/www/html/app.py
from flask import Flask, request, jsonify
from flask_cors import CORS  # Add this import
import boto3
from botocore.exceptions import ClientError

app = Flask(__name__)
CORS(app)  # This will allow CORS for all routes

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')  # Use primary region here
table = dynamodb.Table('hem-dynamodbtable')  # Replace with your table name

@app.route('/insert', methods=['POST'])
def insert_data():
    data = request.get_json()

    if not all(k in data for k in ("customer_id", "name", "address", "phone_number")):
        return jsonify({"error": "Missing required fields"}), 400

    item = {
        'customer_id': data['customer_id'],
        'name': data['name'],
        'address': data['address'],
        'phone_number': data['phone_number']
    }

    try:
        table.put_item(Item=item)
        return jsonify({"message": "Data inserted successfully"}), 200
    except ClientError as e:
        return jsonify({"error": str(e)}), 500

@app.route('/read', methods=['GET'])
def read_data():
    try:
        response = table.scan()  # This retrieves all records in the table
        data = response.get('Items', [])
        return jsonify(data), 200
    except ClientError as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)  # Run on port 5000 for easy access
EOL


# Make the Flask app executable and run it
chmod +x /var/www/html/app.py
nohup python3 /var/www/html/app.py &