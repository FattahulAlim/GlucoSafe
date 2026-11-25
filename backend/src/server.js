
require('dotenv').config();

const cron = require('node-cron');
const app = require('./app');
const { sendWeeklyReminders } = require('./services/notificationService');

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`GlucoSafe API running at http://localhost:${PORT}`);

  // Jadwalkan pengingat skrining setiap hari Senin pukul 08:00 WIB
  cron.schedule(
    '0 8 * * 1',
    () => {
      console.log('[Cron] Mengirim pengingat skrining mingguan...');
      sendWeeklyReminders();
    },
    { timezone: 'Asia/Jakarta' }
  );

  console.log('[Cron] Pengingat mingguan dijadwalkan setiap Senin pukul 08:00 WIB');
});
