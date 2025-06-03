const fs = require('fs');
const path = require('path');

// Path to models directory
const modelsDir = path.join(__dirname, 'real-estate-api', 'src', 'models');

// Get all model files
const modelFiles = fs.readdirSync(modelsDir)
  .filter(file => file.endsWith('.model.js') && file !== 'index.js');

console.log(`Found ${modelFiles.length} model files to fix...`);

// Process each model file
modelFiles.forEach(file => {
  const filePath = path.join(modelsDir, file);
  let content = fs.readFileSync(filePath, 'utf-8');
  
  // Extract model name and create table name
  const baseName = file.replace('.model.js', '');
  const modelClassName = baseName.charAt(0).toUpperCase() + baseName.slice(1);
  
  // Check if this model needs UUIDV4
  const needsUuidV4 = content.includes('UUIDV4') || content.includes('DataTypes.UUIDV4');
  
  // Simple pluralization for table names
  let tableName = baseName + 's';
  // Special case for special plurals
  if (baseName === 'property') tableName = 'properties';
  
  // Create a completely new model file content with proper structure
  let newContent = '';
  
  // Add imports - always include DataTypes, and conditionally include UUIDV4
  if (needsUuidV4) {
    newContent += `const { DataTypes, UUIDV4 } = require('sequelize');\n`;
  } else {
    newContent += `const { DataTypes } = require('sequelize');\n`;
  }
  newContent += `const { sequelize, shouldUseSqlite } = require('../config/database');\n\n`;
  
  // Extract the model definition properties
  const propertiesMatch = content.match(/sequelize\.define\(['"]\w+['"],\s*\{([\s\S]*?)},\s*\{/);
  const properties = propertiesMatch ? propertiesMatch[1] : '';
  
  // Fix references in properties to use lowercase table names
  let updatedProperties = properties;
  const refRegex = /model:\s*['"]([A-Z]\w+)['"]/g;
  let match;
  
  while ((match = refRegex.exec(properties)) !== null) {
    const originalModelName = match[1];
    const lowercaseName = originalModelName.toLowerCase();
    updatedProperties = updatedProperties.replace(
      `model: '${originalModelName}'`, 
      `model: '${lowercaseName}'`
    );
  }
  
  // Add the model definition with fixed references and explicit tableName
  newContent += `const ${modelClassName} = sequelize.define('${modelClassName}', {${updatedProperties}}, {\n`;
  newContent += `  timestamps: true,\n`;
  newContent += `  tableName: '${tableName}' // Explicitly set table name to lowercase for PostgreSQL\n`;
  newContent += `});\n\n`;
  
  // Add module export
  newContent += `module.exports = ${modelClassName};\n`;
  
  // Write the new content
  fs.writeFileSync(filePath, newContent);
  console.log(`Completely rewritten model file: ${file}`);
});

console.log('All model files have been successfully cleaned up!');
