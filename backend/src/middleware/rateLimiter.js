// ponytail: in-memory limiter; upgrade to redis when distributed/scaled horizontally.
function createRateLimiter({ windowMs = 15 * 60 * 1000, max = 5, message } = {}) {
  const hits = new Map();

  return function rateLimiter(req, res, next) {
    const ip = req.ip || req.socket?.remoteAddress || '127.0.0.1';
    const now = Date.now();

    if (hits.size > 1000) {
      for (const [k, v] of hits) {
        if (now > v.resetTime) hits.delete(k);
      }
    }

    const record = hits.get(ip);

    if (!record || now > record.resetTime) {
      hits.set(ip, { count: 1, resetTime: now + windowMs });
      return next();
    }

    if (record.count >= max) {
      const retryAfterSeconds = Math.ceil((record.resetTime - now) / 1000);
      res.setHeader('Retry-After', retryAfterSeconds);
      return res.status(429).json({
        success: false,
        message: message || 'Terlalu banyak percobaan. Silakan coba lagi nanti.',
      });
    }

    record.count += 1;
    next();
  };
}

const loginLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: 'Terlalu banyak percobaan login. Silakan coba lagi dalam 15 menit.',
});

module.exports = { createRateLimiter, loginLimiter };
