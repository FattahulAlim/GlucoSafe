const test = require('node:test');
const assert = require('node:assert/strict');
const { createRateLimiter } = require('../src/middleware/rateLimiter');

function createMockReqRes(ip = '127.0.0.1') {
  const headers = {};
  const req = { ip, socket: { remoteAddress: ip } };
  const res = {
    statusCode: 200,
    body: null,
    setHeader(name, value) {
      headers[name] = value;
    },
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(data) {
      this.body = data;
      return this;
    },
  };
  return { req, res, headers };
}

test('rateLimiter: mengizinkan request di bawah batas max', () => {
  const limiter = createRateLimiter({ windowMs: 1000, max: 2 });
  let calledNext = false;
  const next = () => { calledNext = true; };

  const { req, res } = createMockReqRes();
  limiter(req, res, next);
  assert.equal(calledNext, true);
  assert.equal(res.statusCode, 200);
});

test('rateLimiter: menolak request melebihi batas max dengan status 429', () => {
  const limiter = createRateLimiter({ windowMs: 5000, max: 2 });
  const next = () => {};

  const ctx1 = createMockReqRes();
  limiter(ctx1.req, ctx1.res, next); // hit 1: OK

  const ctx2 = createMockReqRes();
  limiter(ctx2.req, ctx2.res, next); // hit 2: OK

  const ctx3 = createMockReqRes();
  let nextCalledOnThird = false;
  limiter(ctx3.req, ctx3.res, () => { nextCalledOnThird = true; }); // hit 3: Blocked

  assert.equal(nextCalledOnThird, false);
  assert.equal(ctx3.res.statusCode, 429);
  assert.equal(ctx3.res.body.success, false);
  assert.ok(ctx3.headers['Retry-After'] > 0);
});

test('rateLimiter: membedakan IP klien', () => {
  const limiter = createRateLimiter({ windowMs: 5000, max: 1 });
  const next = () => {};

  const ipA1 = createMockReqRes('1.1.1.1');
  limiter(ipA1.req, ipA1.res, next);

  const ipA2 = createMockReqRes('1.1.1.1');
  limiter(ipA2.req, ipA2.res, next);
  assert.equal(ipA2.res.statusCode, 429);

  // IP berbeda tetap diizinkan
  const ipB = createMockReqRes('2.2.2.2');
  let bCalled = false;
  limiter(ipB.req, ipB.res, () => { bCalled = true; });
  assert.equal(bCalled, true);
  assert.equal(ipB.res.statusCode, 200);
});
