#!/bin/bash

# This script finds and updates all files that import from AuthContext without extension
# to explicitly use the .jsx extension

# Find all files importing from AuthContext without extension
# Exclude the .js files since we want to focus on .jsx files first
grep -l "import.*from '.*context/AuthContext';" --include="*.jsx" -r /home/chris/realtor_pro/real-estate-dashboard/src | while read -r file; do
  echo "Processing: $file"
  # Replace the import line
  sed -i "s|import { useAuth } from '\\(.*\\)context/AuthContext';|import { useAuth } from '\\1context/AuthContext.jsx'; // Explicitly use the JSX version|g" "$file"
  sed -i "s|import { AuthProvider } from '\\(.*\\)context/AuthContext';|import { AuthProvider } from '\\1context/AuthContext.jsx'; // Explicitly use the JSX version|g" "$file"
  sed -i "s|import { useAuth, AuthProvider } from '\\(.*\\)context/AuthContext';|import { useAuth, AuthProvider } from '\\1context/AuthContext.jsx'; // Explicitly use the JSX version|g" "$file"
done

echo "All .jsx files updated!"
