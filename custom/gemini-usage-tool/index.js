/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */

import {
  Config,
  sessionId,
  AuthType,
  UserAccountManager,
  DEFAULT_GEMINI_MODEL,
  getCodeAssistServer,
} from '@google/gemini-cli-core';
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';

/**
 * Standalone tool for fetching Gemini CLI usage and account data.
 */
async function main() {
  const argv = await yargs(hideBin(process.argv))
    .option('json', {
      type: 'boolean',
      description: 'Output in JSON format',
      default: false,
    })
    .option('auth', {
      type: 'string',
      description: 'Override authentication type',
      choices: Object.values(AuthType),
    })
    .option('short', {
      type: 'boolean',
      alias: 's',
      description: 'Display concise output',
      default: false,
    })
    .help()
    .alias('h', 'help')
    .parse();

  // If JSON or short output is requested, suppress ALL library logs
  if (argv.json || argv.short) {
    const noop = () => {};
    console.log = noop;
    console.info = noop;
    console.debug = noop;
    console.warn = noop;
    // Keep console.error available for actual crashes, but library "info" logs usually use log/debug
  }

  try {
    const userAccountManager = new UserAccountManager();
    const activeAccount = userAccountManager.getCachedGoogleAccount();
    
    const cwd = process.cwd();
    const config = new Config({
      sessionId,
      targetDir: cwd,
      cwd,
      model: DEFAULT_GEMINI_MODEL,
      debugMode: false,
    });

    // Determine auth type
    let authType = argv.auth || AuthType.LOGIN_WITH_GOOGLE;
    if (!argv.auth) {
      try {
        const settings = config.getSettings();
        if (settings?.security?.auth?.selectedType) {
          authType = settings.security.auth.selectedType;
        }
      } catch (e) { /* ignore */ }
    }

    if (!argv.json && !argv.short) {
      console.error('--- Account Information ---');
      console.error(`Active Account: ${activeAccount ?? 'None'}`);
      console.error(`Auth Method:    ${authType}`);
      console.error('\nAuthenticating...');
    }

    await config.refreshAuth(authType);
    
    const codeAssistServer = getCodeAssistServer(config);
    const quota = await config.refreshUserQuota();

    const result = {
      account: {
        active: activeAccount,
        authType,
        projectId: codeAssistServer?.projectId ?? null,
        userTier: codeAssistServer?.userTier ?? null,
        userTierName: codeAssistServer?.userTierName ?? null,
      },
      quota: quota?.buckets?.map(bucket => {
        const resetDate = bucket.resetTime ? new Date(bucket.resetTime) : null;
        let resetsIn = null;
        if (resetDate) {
          const diffMs = resetDate.getTime() - Date.now();
          if (diffMs > 0) {
            const hours = Math.floor(diffMs / (1000 * 60 * 60));
            const mins = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));
            resetsIn = `${hours}h ${mins}m`;
          }
        }
        return {
          modelId: bucket.modelId,
          remainingFraction: bucket.remainingFraction,
          remainingPercent: (bucket.remainingFraction * 100).toFixed(1) + '%',
          resetTime: bucket.resetTime,
          resetsIn,
        };
      }) ?? [],
    };

    if (argv.json) {
      process.stdout.write(JSON.stringify(result, null, 2) + '\n');
    } else if (argv.short) {
      if (!result.quota || result.quota.length === 0) {
        process.stdout.write('No quota information available.\n');
      } else {
        for (const q of result.quota) {
          let line = `${q.modelId}: ${q.remainingPercent}`;
          if (q.resetsIn) {
            line += ` (Reset in ${q.resetsIn})`;
          }
          process.stdout.write(line + '\n');
        }
      }
    } else {
      console.log(`Project ID:     ${result.account.projectId ?? 'Not set'}`);
      console.log(`User Tier:      ${result.account.userTierName ?? 'Unknown'} (${result.account.userTier ?? 'Unknown'})`);

      if (!result.quota || result.quota.length === 0) {
        console.log('\nNo quota information available.');
      } else {
        console.log('\n--- Usage & Quota ---');
        for (const q of result.quota) {
          console.log(`\nModel: ${q.modelId}`);
          console.log(`Usage left: ${q.remainingPercent}`);
          if (q.resetTime) {
            console.log(`Resets at:  ${new Date(q.resetTime).toLocaleString()}`);
            if (q.resetsIn) {
              console.log(`Resets in:  ${q.resetsIn}`);
            }
          }
        }
      }
      console.log('\n----------------------');
    }

  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    if (argv.json) {
      process.stdout.write(JSON.stringify({ error: errorMsg }, null, 2) + '\n');
    } else {
      console.error('Error:', errorMsg);
    }
    process.exit(1);
  }
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});