import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const globalRoot = (process.platform === 'win32'
  ? execFileSync('cmd.exe', ['/d', '/s', '/c', 'npm root -g'], {
      encoding: 'utf8',
      windowsHide: true,
    })
  : execFileSync('npm', ['root', '-g'], {
      encoding: 'utf8',
    })
).trim();
const apiModule = path.join(globalRoot, 'firebase-tools', 'lib', 'apiv2.js');
const authModule = path.join(globalRoot, 'firebase-tools', 'lib', 'auth.js');
const { getAccessToken } = await import(pathToFileURL(apiModule).href);
const auth = await import(pathToFileURL(authModule).href);
const account = auth.getGlobalDefaultAccount();
if (!account) throw new Error('Firebase CLI não possui uma conta ativa.');
auth.setActiveAccount({}, account);
const token = await getAccessToken();
if (!token) throw new Error('Firebase CLI não forneceu credencial administrativa.');
process.stdout.write(token);
