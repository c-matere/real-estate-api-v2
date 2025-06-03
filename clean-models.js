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
  
  // Check content for required imports
  const needsUUIDV4 = content.includes('UUIDV4') || content.includes('DataTypes.UUIDV4');
  
  // Create clean content by extracting just the model definition
  const modelDefinitionMatch = content.match(/const \w+ = sequelize\.define\('.*?',([\s\S]*?)\);[\s\S]*module\.exports/);
  
  if (modelDefinitionMatch) {
    // Extract the model definition part
    const modelPart = modelDefinitionMatch[1];
    
    // Create completely new file content with clean imports and model definition
    let newContent = '';
    
    // Add imports
    if (needsUUIDV4) {
      newContent += `const { DataTypes, UUIDV4 } = require('sequelize');\n`;
    } else {
      newContent += `const { DataTypes } = require('sequelize');\n`;
    }
    
    newContent += `const { sequelize, shouldUseSqlite } = require('../config/database');\n\n`;
    
    // Add model definition with explicit table name
    newContent += `const ${modelName.charAt(0).toUpperCase() + modelName.slice(1)} = sequelize.define('${modelName.charAt(0).toUpperCase() + modelName.slice(1)}', ${modelPart}, {
  timestamps: true,
  tableName: '${pluralTableName}' // Explicitly set table name to lowercase for PostgreSQL
});\n\n`;
    
    // Add export
    newContent += `module.exports = ${modelName.charAt(0).toUpperCase() + modelName.slice(1)};\n`;
    
    // Write the completely rewritten content back to the file
    fs.writeFileSync(filePath, newContent);
    console.log(`Updated ${file} with clean imports and model definition`);
  } else {
    console.log(`Could not parse model definition for ${file}, skipping`);
  }
});

console.log('All model files have been updated with clean imports and definitions!');
