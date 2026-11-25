const { getMessaging, firebaseInitialized } = require('../config/firebase');
const db = require('../config/database');

/**
 * Mengirim notifikasi pengingat skrining mingguan ke pengguna yang memiliki FCM token
 * dan belum melakukan skrining dalam 7 hari terakhir.
 */
async function sendWeeklyReminders() {
  if (!firebaseInitialized) {
    console.warn('[Notifikasi] Lewati pengiriman: Firebase belum dikonfigurasi.');
    return { sent: 0, failed: 0, skipped: true };
  }

  try {
    const [users] = await db.execute(`
      SELECT u.id, u.name, u.fcm_token
      FROM users u
      WHERE u.fcm_token IS NOT NULL
        AND u.fcm_token != ''
        AND u.id NOT IN (
          SELECT DISTINCT sr.user_id
          FROM screening_results sr
          WHERE sr.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        )
    `);

    if (users.length === 0) {
      console.log('[Notifikasi] Tidak ada user yang perlu diingatkan minggu ini.');
      return { sent: 0, failed: 0 };
    }

    const messages = users.map((user) => ({
      token: user.fcm_token,
      notification: {
        title: 'Waktunya Cek Risiko Diabetes',
        body: `Hai ${user.name}, sudah seminggu sejak pengecekan terakhirmu. Yuk cek risiko diabetes secara rutin!`,
      },
      data: {
        type: 'screening_reminder',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'glucosafe_reminders',
          icon: '@mipmap/launcher_icon',
        },
      },
    }));

    let successCount = 0;
    let failureCount = 0;

    // FCM sendEach mendukung maksimal 500 pesan per batch
    for (let i = 0; i < messages.length; i += 500) {
      const batch = messages.slice(i, i + 500);
      const batchUsers = users.slice(i, i + 500);
      const response = await getMessaging().sendEach(batch);

      successCount += response.successCount;
      failureCount += response.failureCount;

      for (let idx = 0; idx < response.responses.length; idx++) {
        const resp = response.responses[idx];
        if (
          resp.error &&
          (resp.error.code === 'messaging/registration-token-not-registered' ||
            resp.error.code === 'messaging/invalid-registration-token')
        ) {
          await db.execute('UPDATE users SET fcm_token = NULL WHERE id = ?', [
            batchUsers[idx].id,
          ]);
        }
      }
    }

    console.log(`[Notifikasi] Terkirim: ${successCount}, Gagal: ${failureCount}`);
    return { sent: successCount, failed: failureCount };
  } catch (error) {
    console.error('[Notifikasi] Error:', error.message);
    return { sent: 0, failed: 0, error: error.message };
  }
}

module.exports = { sendWeeklyReminders };
