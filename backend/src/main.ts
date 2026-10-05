import { createApp } from './app.factory';
import { ConfigError, loadConfig } from './config/config';

async function main(): Promise<void> {
  const config = loadConfig();
  const app = await createApp(config);
  await app.listen(config.port, '0.0.0.0');
}

main().catch((error: unknown) => {
  // Configuration errors list variable names only, never values.
  process.stderr.write(
    `${error instanceof ConfigError ? error.message : String((error as Error)?.stack ?? error)}\n`,
  );
  process.exit(1);
});
