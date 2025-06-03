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
  const originalContent = fs.readFileSync(filePath, 'utf-8');
  
  // Completely replace the file with a clean version that has proper imports
  let newContent = `const { DataTypes, UUIDV4 } = require('sequelize');\n`;
  newContent += `const { sequelize, shouldUseSqlite } = require('../config/database');\n\n`;
  
  // Extract the model name from the filename (e.g., 'user.model.js' -> 'User')
  const modelName = file.replace('.model.js', '');
  const modelNameCapitalized = modelName.charAt(0).toUpperCase() + modelName.slice(1);
  
  // Extract the model definition (everything between sequelize.define and the module.exports)
  const defineRegex = /sequelize\.define\(['"]\w+['"],\s*\{([\s\S]*?)\}\s*,\s*\{[\s\S]*?\}\s*\);/;
  const match = originalContent.match(defineRegex);
  
  if (match) {
    const modelProperties = match[1];
    
    // Add the model definition
    newContent += `const ${modelNameCapitalized} = sequelize.define('${modelNameCapitalized}', {\n`;
    newContent += modelProperties;
    
    // Get table name - simple pluralization
    let tableName = modelName.toLowerCase() + 's';
    // Special case for properties
    if (modelName === 'property') {
      tableName = 'properties';
    }
    
    // Add model options
    newContent += `}, {\n  timestamps: true,\n  tableName: '${tableName}' // Explicitly set lowercase table name\n});\n\n`;
    
    // Add module export
    newContent += `module.exports = ${modelNameCapitalized};\n`;
    
    // Write the new content to the file
    fs.writeFileSync(filePath, newContent);
    console.log(`Fixed model file: ${file}`);
  } else {
    console.log(`Could not parse model definition in ${file}, skipping...`);
  }
});

console.log('All models have been fixed with proper imports and tableName settings.');
