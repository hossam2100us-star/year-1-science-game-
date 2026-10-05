import { AttemptLimiter } from './attempt-limiter';

describe('AttemptLimiter (failed sign-ins)', () => {
  let now = 0;
  const limiter = () => new AttemptLimiter(() => now);
  beforeEach(() => {
    now = 1_000_000;
  });

  it('allows four failures, then blocks that account from that address for the rest of the window', () => {
    const l = limiter();
    for (let i = 0; i < 4; i++) l.fail('acct', 'ip1');
    expect(l.retryAfter('acct', 'ip1')).toBe(0);
    l.fail('acct', 'ip1');
    expect(l.retryAfter('acct', 'ip1')).toBe(15 * 60);
    expect(l.retryAfter('acct', 'ip2')).toBe(0);
    expect(l.retryAfter('other', 'ip1')).toBe(0);
    now += 15 * 60 * 1000 + 1;
    expect(l.retryAfter('acct', 'ip1')).toBe(0);
  });

  it('slows down repeated failures', () => {
    const l = limiter();
    expect(l.delayFor('acct', 'ip')).toBe(0);
    for (let i = 0; i < 3; i++) l.fail('acct', 'ip');
    expect(l.delayFor('acct', 'ip')).toBe(1000);
    l.fail('acct', 'ip');
    expect(l.delayFor('acct', 'ip')).toBe(2000);
  });

  it('blocks an address trying many accounts', () => {
    const l = limiter();
    for (let i = 0; i < 30; i++) l.fail(`acct${i}`, 'ip');
    expect(l.retryAfter('fresh', 'ip')).toBeGreaterThan(0);
  });

  it("forgets an account's failures after a successful sign-in", () => {
    const l = limiter();
    for (let i = 0; i < 4; i++) l.fail('acct', 'ip');
    l.succeed('acct', 'ip');
    l.fail('acct', 'ip');
    expect(l.retryAfter('acct', 'ip')).toBe(0);
  });
});
