
const express = require('express');
const cors = require('cors');
const userRoutes = require('./routes/userRoutes');
const screeningRoutes = require('./routes/screeningRoutes');
const authRoutes = require('./routes/authRoutes');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'GlucoSafe API is running',
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/screenings', screeningRoutes);
module.exports = app;
 