const { sequelize } = require('./real-estate-api/src/config/database');
const { exec } = require('child_process');

// First sync all tables with force: true to drop and recreate all tables
async function cleanAndSeed() {
  try {
    console.log('Starting database cleanup and reseeding...');
    
    // Step 1: Force sync (drop all tables and recreate)
    console.log('Forcing database sync to drop all tables...');
    await sequelize.sync({ force: true });
    console.log('Database tables dropped and recreated successfully');
    
    // Step 2: Run the seeder script
    console.log('Running seeder script...');
    exec('cd real-estate-api && node src/utils/runSeeder.js', (error, stdout, stderr) => {
      if (error) {
        console.error(`Error running seeder: ${error.message}`);
        return;
      }
      if (stderr) {
        console.error(`Seeder stderr: ${stderr}`);
        return;
      }
      console.log(`Seeder stdout: ${stdout}`);
      console.log('Database cleaned and reseeded successfully!');
    });
    
  } catch (error) {
    console.error('Error during database cleanup and reseeding:', error);
  }
}

// Run the function
cleanAndSeed();
