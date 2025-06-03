const fs = require('fs');
const path = require('path');

// Path to models directory
const modelsDir = path.join(__dirname, 'real-estate-api', 'src', 'models');

// Get all model files
const modelFiles = fs.readdirSync(modelsDir)
  .filter(file => file.endsWith('.model.js') && file !== 'index.js');

console.log(`Found ${modelFiles.length} model files to fix references in`);

// Process each model file
modelFiles.forEach(file => {
  const filePath = path.join(modelsDir, file);
  let content = fs.readFileSync(filePath, 'utf-8');
  const originalContent = content;
  
  // 1. Fix imports if DataTypes is missing
  if (!content.includes('const { DataTypes }') && content.includes('DataTypes.')) {
    // Add DataTypes import if it's used but not imported
    if (content.includes('DataTypes.UUIDV4')) {
      content = `const { DataTypes, UUIDV4 } = require('sequelize');\n${content}`;
    } else {
      content = `const { DataTypes } = require('sequelize');\n${content}`;
    }
  }
  
  // 2. Fix references to uppercase table names in model references
  // Common models that should be lowercase
  const modelMappings = {
    'Users': 'users',
    'Properties': 'properties',
    'Units': 'units',
    'Tenants': 'tenants',
    'Leases': 'leases',
    'Invoices': 'invoices',
    'Transactions': 'transactions',
    'Maintenances': 'maintenances',
    'Expenses': 'expenses',
    'Payments': 'payments',
    'MessageTemplates': 'messagetemplates',
    'Messages': 'messages',
    'Settings': 'settings'
  };
  
  // Replace model references
  Object.entries(modelMappings).forEach(([uppercase, lowercase]) => {
    // Replace references in the model option (when using sequelize.define)
    content = content.replace(
      new RegExp(`model: ['"]${uppercase}['"]`, 'g'),
      `model: '${lowercase}'`
    );
  });
  
  // 3. Make sure tableName is set to lowercase
  // Extract model name from the file (e.g., user.model.js -> User)
  const modelName = file.replace('.model.js', '');
  const modelNameCapitalized = modelName.charAt(0).toUpperCase() + modelName.slice(1);
  const tableName = modelName + 's'; // Simple pluralization
  
  // Check if this file already has a tableName configuration
  if (!content.includes('tableName:')) {
    // Find the model definition pattern and add tableName
    content = content.replace(
      /sequelize\.define\(['"](\w+)['"]\s*,\s*\{/,
      (match, name) => `sequelize.define('${name}', {`
    );
    
    // Add tableName option to model options object
    content = content.replace(
      /}\s*\)\s*;/,
      `}, {\n  tableName: '${tableName}',\n  timestamps: true\n});\n`
    );
  }
  
  // Only write file if changes were made
  if (content !== originalContent) {
    fs.writeFileSync(filePath, content);
    console.log(`Updated references in ${file}`);
  } else {
    console.log(`No changes needed for ${file}`);
  }
});

console.log('All model references have been fixed!');
