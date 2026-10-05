import { Inject, Injectable, Logger } from '@nestjs/common';
import { APP_CONFIG, type AppConfig } from '../config/config';
import { MAILER, type Mailer } from './mailer';

/**
 * Account emails, Arabic first then English. Only necessary messages: no
 * marketing. Tokens travel in the URL fragment (`#token=`) so they never
 * reach server logs or Referer headers. Sending happens after the response
 * and failures are logged without the address.
 */
@Injectable()
export class EmailService {
  private readonly log = new Logger('Email');

  constructor(
    @Inject(MAILER) private readonly mailer: Mailer,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  verifyEmail(to: string, token: string): void {
    const link = `${this.config.publicWebUrl}/account/verify-email#token=${token}`;
    this.dispatch(
      to,
      'تأكيد الإيميل • Confirm your email — Science Adventure',
      [
        'أهلًا! اضغط على اللينك ده عشان تأكد إيميلك في Science Adventure:',
        link,
        'اللينك شغال 24 ساعة. لو انت ما عملتش حساب، تجاهل الرسالة دي.',
      ],
      [
        'Hello! Open this link to confirm your email for Science Adventure:',
        link,
        'The link works for 24 hours. If you did not create an account, ignore this message.',
      ],
    );
  }

  accountExists(to: string): void {
    const link = `${this.config.publicWebUrl}/account/forgot-password`;
    this.dispatch(
      to,
      'محاولة تسجيل • Sign-up attempt — Science Adventure',
      [
        'حد حاول يعمل حساب جديد بالإيميل ده، بس الإيميل ده عنده حساب بالفعل.',
        'لو ده انت ونسيت كلمة السر، تقدر تغيّرها من هنا:',
        link,
        'لو مش انت، تجاهل الرسالة دي؛ حسابك ما اتغيرش.',
      ],
      [
        'Someone tried to create an account with this email, but it already has one.',
        'If that was you and you forgot your password, you can reset it here:',
        link,
        'If it was not you, ignore this message; nothing changed.',
      ],
    );
  }

  resetPassword(to: string, token: string): void {
    const link = `${this.config.publicWebUrl}/account/reset-password#token=${token}`;
    this.dispatch(
      to,
      'تغيير كلمة السر • Reset your password — Science Adventure',
      [
        'اضغط على اللينك ده عشان تختار كلمة سر جديدة:',
        link,
        'اللينك شغال 30 دقيقة ومرة واحدة بس. لو انت ما طلبتش ده، تجاهل الرسالة.',
      ],
      [
        'Open this link to choose a new password:',
        link,
        'The link works once, for 30 minutes. If you did not ask for this, ignore this message.',
      ],
    );
  }

  passwordChanged(to: string): void {
    this.dispatch(
      to,
      'كلمة السر اتغيرت • Password changed — Science Adventure',
      [
        'كلمة سر حسابك اتغيرت، وكل الأجهزة التانية اتعمل لها خروج.',
        'لو مش انت اللي غيّرتها، غيّرها فورًا من "نسيت كلمة السر".',
      ],
      [
        'Your password was changed and every other device was signed out.',
        'If this was not you, reset your password straight away with "Forgot password".',
      ],
    );
  }

  securityAlert(to: string): void {
    this.dispatch(
      to,
      'تنبيه أمان • Security alert — Science Adventure',
      [
        'لاحظنا استخدام مفتاح دخول قديم لحسابك، فعملنا خروج للجهاز ده كإجراء أمان.',
        'لو ده غريب عليك، غيّر كلمة السر.',
      ],
      [
        'An old sign-in key for your account was used again, so we signed that device out to be safe.',
        'If this looks unfamiliar, change your password.',
      ],
    );
  }

  deletionScheduled(to: string, when: Date): void {
    const day = when.toISOString().slice(0, 10);
    this.dispatch(
      to,
      'طلب مسح الحساب • Account deletion — Science Adventure',
      [
        `حسابك وكل بيانات الأطفال هيتمسحوا نهائيًا يوم ${day}.`,
        'لو غيّرت رأيك، سجّل دخول قبل الميعاد ده والمسح هيتلغي.',
      ],
      [
        `Your account and all children's data will be erased on ${day}.`,
        'If you change your mind, sign in before then and the deletion is cancelled.',
      ],
    );
  }

  deletionCancelled(to: string): void {
    this.dispatch(
      to,
      'إلغاء مسح الحساب • Deletion cancelled — Science Adventure',
      ['سجّلت دخول، فطلب مسح الحساب اتلغى. بياناتك زي ما هي.'],
      ['You signed in, so the account deletion was cancelled. Your data is unchanged.'],
    );
  }

  private dispatch(to: string, subject: string, ar: string[], en: string[]): void {
    const text = [...ar, '', '—', '', ...en].join('\n');
    const html = [
      '<div dir="rtl" lang="ar" style="font-family:sans-serif">',
      ...ar.map((line) => `<p>${linkify(line)}</p>`),
      '</div><hr>',
      '<div dir="ltr" lang="en" style="font-family:sans-serif">',
      ...en.map((line) => `<p>${linkify(line)}</p>`),
      '</div>',
    ].join('');
    this.mailer.send({ to, subject, text, html }).catch((error: unknown) => {
      this.log.warn({ reason: (error as Error)?.name ?? 'unknown' }, 'Email could not be sent');
    });
  }
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function linkify(line: string): string {
  const escaped = escapeHtml(line);
  return line.startsWith('http') ? `<a href="${escaped}">${escaped}</a>` : escaped;
}
