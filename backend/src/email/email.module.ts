import { Global, Module } from '@nestjs/common';
import { APP_CONFIG, type AppConfig } from '../config/config';
import { EmailService } from './email.service';
import { MAILER, MemoryMailer, SmtpMailer } from './mailer';

@Global()
@Module({
  providers: [
    {
      provide: MAILER,
      inject: [APP_CONFIG],
      useFactory: (config: AppConfig) =>
        config.email.transport === 'memory'
          ? new MemoryMailer()
          : new SmtpMailer(config.email.smtpUrl!, config.email.from),
    },
    EmailService,
  ],
  exports: [EmailService, MAILER],
})
export class EmailModule {}
