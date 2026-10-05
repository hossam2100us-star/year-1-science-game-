/**
 * Failed sign-in tracking (§9): per account+IP and per IP, in a sliding
 * window, with a growing delay after a few failures. Kept in memory: the
 * trial runs one API container. A shared store is needed before running
 * several (see docs/SECURITY_HARDENING.md). Provided by a factory (the clock
 * is a constructor argument so tests can move time).
 */
export class AttemptLimiter {
  static readonly WINDOW_MS = 15 * 60 * 1000;
  static readonly MAX_PER_ACCOUNT_IP = 5;
  static readonly MAX_PER_IP = 30;

  private readonly failures = new Map<string, number[]>();

  constructor(private readonly now: () => number = Date.now) {}

  /** Seconds to wait before another try is allowed, or 0. */
  retryAfter(accountKey: string, ip: string): number {
    const byAccount = this.recent(`a:${accountKey}|${ip}`);
    const byIp = this.recent(`i:${ip}`);
    const waits: number[] = [];
    if (byAccount.length >= AttemptLimiter.MAX_PER_ACCOUNT_IP) {
      waits.push(this.until(byAccount, AttemptLimiter.MAX_PER_ACCOUNT_IP));
    }
    if (byIp.length >= AttemptLimiter.MAX_PER_IP) {
      waits.push(this.until(byIp, AttemptLimiter.MAX_PER_IP));
    }
    return waits.length ? Math.max(...waits) : 0;
  }

  /** Extra delay (ms) for the next answer: 0, 0, 0, 1 s, 2 s, 4 s ... */
  delayFor(accountKey: string, ip: string): number {
    const n = this.recent(`a:${accountKey}|${ip}`).length;
    return n < 3 ? 0 : Math.min(8000, 1000 * 2 ** (n - 3));
  }

  fail(accountKey: string, ip: string): void {
    for (const key of [`a:${accountKey}|${ip}`, `i:${ip}`]) {
      const list = this.recent(key);
      list.push(this.now());
      this.failures.set(key, list);
    }
  }

  /** Tests only. */
  clear(): void {
    this.failures.clear();
  }

  succeed(accountKey: string, ip: string): void {
    this.failures.delete(`a:${accountKey}|${ip}`);
  }

  private recent(key: string): number[] {
    const cutoff = this.now() - AttemptLimiter.WINDOW_MS;
    const list = (this.failures.get(key) ?? []).filter((t) => t > cutoff);
    if (list.length) this.failures.set(key, list);
    else this.failures.delete(key);
    return list;
  }

  private until(list: number[], max: number): number {
    const oldestCounted = list[list.length - max]!;
    return Math.ceil((oldestCounted + AttemptLimiter.WINDOW_MS - this.now()) / 1000);
  }
}
