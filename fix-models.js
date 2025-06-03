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
  const pascalCaseModelName = modelName.charAt(0).toUpperCase() + modelName.slice(1);
  const pluralTableName = modelName + 's'; // Simple pluralization
  
  // Check if DataTypes import exists and fix if needed
  if (!content.includes('const { DataTypes }')) {
    content = content.replace(
      /const { sequelize/,
      'const { DataTypes } = require(\'sequelize\');\nconst { sequelize'
    );
  } else if (content.match(/const { DataTypes }.*\n.*const { DataTypes }/s)) {
    // Fix duplicate DataTypes import
    content = content.replace(
      /const { DataTypes } = require\('sequelize'\);\s*const { DataTypes } = require\('sequelize'\);/,
      'const { DataTypes } = require(\'sequelize\');'
    );
  }
  
  // Add UUIDV4 to import if needed
  if (content.includes('DataTypes.UUIDV4') && !content.includes('UUIDV4')) {
    content = content.replace(
      /const { DataTypes } = require\('sequelize'\);/,
      'const { DataTypes, UUIDV4 } = require(\'sequelize\');'
    );
  } else if (content.includes('DataTypes.UUIDV4') && content.includes('UUIDV4') &&
            content.match(/const { DataTypes, UUIDV4 }.*\n.*const { DataTypes, UUIDV4 }/s)) {
    // Fix duplicate imports with UUIDV4
    content = content.replace(
      /const { DataTypes, UUIDV4 } = require\('sequelize'\);\s*const { DataTypes, UUIDV4 } = require\('sequelize'\);/,
      'const { DataTypes, UUIDV4 } = require(\'sequelize\');'
    );
  }
  
  // Add tableName to model definition
  if (!content.includes('tableName:')) {
    content = content.replace(
      /}, {\s*timestamps: true/,
      `}, {\n  timestamps: true,\n  tableName: '${pluralTableName}' // Explicit lowercase table name for PostgreSQL`
    );
  }
  
  // Write the updated content back to the file
  fs.writeFileSync(filePath, content);
  console.log(`Updated ${file}`);
});

console.log('All model files have been updated!');
