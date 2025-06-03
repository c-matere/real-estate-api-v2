#!/bin/bash

# Test health endpoint
echo "Testing health endpoint:"
curl -s http://localhost:5000/api/health
echo -e "\n\n"

# Test login with test credentials
echo "Testing login endpoint:"
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password"}' \
  -v
