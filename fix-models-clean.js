const fs = require('fs');
const path = require('path');

const modelsDir = path.join(__dirname, 'real-estate-api', 'src', 'models');

// Get all model files
const modelFiles = fs.readdirSync(modelsDir)
  .filter(file => file.endsWith('.model.js') && file !== 'index.js');

console.log(`Found ${modelFiles.length} model files to process`);

modelFiles.forEach(file => {
  const filePath = path.join(modelsDir, file);
  let content = fs.readFileSync(filePath, 'utf-8');
  
  // Extract model name from filename (e.g., 'user.model.js' -> 'User')
  const modelName = file.replace('.model.js', '');
  const pluralTableName = modelName + 's'; // Simple pluralization
  
  // Check if we need UUIDV4 import
  const needsUUIDV4 = content.includes('UUIDV4') || content.includes('DataTypes.UUIDV4');
  
  // Replace the entire import section to ensure clean imports
  let newImportSection;
  if (needsUUIDV4) {
    newImportSection = `const { DataTypes, UUIDV4 } = require('sequelize');\nconst { sequelize, shouldUseSqlite } = require('../config/database');\n`;
  } else {
    newImportSection = `const { DataTypes } = require('sequelize');\nconst { sequelize, shouldUseSqlite } = require('../config/database');\n`;
  }
  
  // Replace all import sections with our clean version
  content = content.replace(/^const.*require.*\n.*require.*\n/m, newImportSection);
  
  // Add tableName to model definition if not exists
  if (!content.includes('tableName:')) {
    content = content.replace(
      /}, {\s*timestamps: true/,
      `}, {\n  timestamps: true,\n  tableName: '${pluralTableName}' // Explicitly set table name to lowercase for PostgreSQL`
    );
  }
  
  // Write the updated content back to the file
  fs.writeFileSync(filePath, content);
  console.log(`Updated ${file}`);
});

console.log('All model files have been updated with clean imports!');
