import { createTransport, type Transporter } from 'nodemailer';

export interface OutgoingEmail {
  to: string;
  subject: string;
  text: string;
  html: string;
}

export interface Mailer {
  send(message: OutgoingEmail): Promise<void>;
}

export const MAILER = Symbol('MAILER');

/** Real delivery (Gmail, a provider, or Mailpit in development). */
export class SmtpMailer implements Mailer {
  private readonly transport: Transporter;

  constructor(
    smtpUrl: string,
    private readonly from: string,
  ) {
    this.transport = createTransport(smtpUrl);
  }

  async send(message: OutgoingEmail): Promise<void> {
    await this.transport.sendMail({ from: this.from, ...message });
  }
}

/** Tests only: keeps messages in memory so tests can read the links. */
export class MemoryMailer implements Mailer {
  readonly sent: OutgoingEmail[] = [];

  send(message: OutgoingEmail): Promise<void> {
    this.sent.push(message);
    return Promise.resolve();
  }

  clear(): void {
    this.sent.length = 0;
  }
}
