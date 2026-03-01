const express = require('express');
const authRoutes = require('./src/routes/auth.routes.js');

const app = express();
const PORT = 3001;

app.use(express.json());

// Mount auth routes
app.use('/api/auth', authRoutes);

// Basic test route
app.get('/', (req, res) => {
  res.send('Test server running');
});

app.listen(PORT, () => {
  console.log(`Test server running on port ${PORT}`);
  console.log('Auth routes mounted successfully');
});
