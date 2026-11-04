# Project Deno

Event listings and ticket prices are stored in MySQL. Admin accounts use password hashes; there is no default admin password.

Open the public site at `http://localhost/Project%20Deno/`. The project root serves `index.html` first; admins can use the **Admin** link in the public site footer to open the sign-in page.

## Run from the VS Code terminal

Start **MySQL** in XAMPP, then run this from the project folder in PowerShell:

```powershell
npm.cmd run dev
```

This starts PHP's built-in server at `http://127.0.0.1:8080/`; open that URL for the public page or add `admin.html` for admin sign-in. PHP 8.2+ with `pdo_mysql` must be on `PATH`. For XAMPP's PHP CLI in PowerShell, prepend it with `$env:PATH = "C:\xampp\php;$env:PATH"` before running `npm.cmd run dev`. Press **Ctrl+C** in the terminal to stop it. Use `npm.cmd` in PowerShell because the `npm.ps1` wrapper may be blocked by the machine's script execution policy.

## Create the database with XAMPP

1. Start **Apache** and **MySQL** in the XAMPP Control Panel.
2. Open phpMyAdmin at `http://localhost/phpmyadmin/`.
3. Import [database.sql](database.sql). It creates the `Project Deno` database and its admin, event, ticket, and request tables. If the database already exists, importing it again adds the missing request table without replacing existing rows.
4. Open `C:\xampp\apache\conf\httpd.conf` and add these settings near the other global `SetEnv` lines:

   ```apache
   SetEnv DENO_DB_HOST "127.0.0.1"
   SetEnv DENO_DB_NAME "Project Deno"
   SetEnv DENO_DB_USER "root"
   SetEnv DENO_DB_PASSWORD ""
   SetEnv TELEGRAM_BOT_TOKEN "your-new-telegram-bot-token"
   SetEnv TELEGRAM_CHAT_ID "your-destination-chat-id"
   SetEnv PROJECT_DENO_MAIL_FROM "your-sender@gmail.com"
   ```

   The root account with a blank password is the usual local XAMPP default. For a public site, create a restricted MySQL user and use a strong password instead.

5. Save the Apache configuration and restart Apache.
6. Open `http://localhost/Project%20Deno/setup-admin.html` and create the first admin account. Use a unique password of at least 12 characters. Setup closes after the first admin is created.
7. Sign in through the **Admin** link on the website to add events and ticket types.

Keep database credentials and bot tokens out of the website files. The previously shared Telegram token should be revoked and replaced.

## Configure receipt email in XAMPP

The transfer form attempts to send a receipt immediately after it records a transfer request. The email tells the client their transfer is waiting for ticket availability and confirmation; it does not confirm that a ticket has been issued. PHP's `mail()` needs a working SMTP relay. In this XAMPP setup, PHP is already configured to use Sendmail and the sender address is set, but Sendmail needs a valid SMTP password before it can deliver messages. Until SMTP authentication succeeds, transfer requests are still recorded and the page tells the client that the email could not be sent.

For Gmail SMTP, use a Google App Password instead of your normal account password. Google requires 2-Step Verification to create one. A Google API key cannot authenticate SMTP; sending with the Gmail API requires OAuth authorization. [Google App Password instructions](https://support.google.com/accounts/answer/185833) · [Gmail API sending guide](https://developers.google.com/workspace/gmail/api/guides/sending)

1. In `C:\xampp\php\php.ini`, under `[mail function]`, set:

   ```ini
   sendmail_path = "\"C:\xampp\sendmail\sendmail.exe\" -t"
   ```

2. In `C:\xampp\sendmail\sendmail.ini`, under `[sendmail]`, set:

   ```ini
   smtp_server=smtp.gmail.com
   smtp_port=465
   smtp_ssl=auto
   auth_username=your-sender@gmail.com
   auth_password=your-google-app-password
   force_sender=your-sender@gmail.com
   ```

   Replace both sender-address examples with your own Gmail address and enter the App Password locally. Never put the App Password in the website files or chat. XAMPP documents this Sendmail setup in its [Windows FAQ](https://www.apachefriends.org/faq_windows).

3. Set `PROJECT_DENO_MAIL_FROM` in Apache to the same sender address, then restart Apache.

For another mail provider, use that provider's SMTP host, port, encryption, and authentication settings in `sendmail.ini`.

## Tickets

Add an event title, category, date, venue, and one or more ticket types with KES prices. Client transfer requests are stored in MySQL and appear in the admin dashboard. Telegram is an optional notification; a missing bot token no longer prevents a transfer request from being recorded. Transfer requests do not reserve or purchase tickets; the site has no payment checkout.

The server also attempts to send a receipt email using PHP `mail()`. Configure XAMPP's PHP mail/sendmail settings to use your SMTP provider and set `PROJECT_DENO_MAIL_FROM` to a sender address you control. If the mail server is not configured, the site tells the client that the transfer request was recorded but the confirmation email could not be sent.

After a transfer request is recorded, the page shows a five-minute confirmation countdown and checks for an admin status update. At zero, a still-pending transfer is reported as unconfirmed; an admin can mark it transferred or failed from the transfer list. The countdown is not a payment or transfer processor.

## Deploy to a PHP/MySQL host

GitHub stores the project files; it does not run this PHP application. Use PHP 8.2 or later with `pdo_mysql` and `session` enabled. MySQL/MariaDB is required. cURL is optional and only used for Telegram notifications; `mail()` is optional and requires the host's mail relay.

1. Create a production database and a database user limited to it. The SQL file currently selects the local database name `Project Deno`. On hosting, make a copy and replace both database-name occurrences with the exact name supplied by the host. If the host does not let the database user run `CREATE DATABASE`, remove the `CREATE DATABASE` and `USE` statements from the import copy, select the database in phpMyAdmin, and import the remaining table schema there. The file contains schema only; it does not migrate local ticket records.
2. Set `DENO_DB_HOST`, `DENO_DB_NAME`, `DENO_DB_USER`, and `DENO_DB_PASSWORD` in the hosting control panel using the host's exact credentials. `DENO_DB_PORT` is optional and defaults to `3306`. `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, and `DB_PORT` are accepted aliases. The local `127.0.0.1`/`root`/blank-password defaults are used only when the request host is localhost or a `.test` domain; production requests require explicit database settings. Set `APP_ENV=production` on the host. If a trusted reverse proxy terminates HTTPS, set `DENO_TRUST_PROXY_HTTPS=true` only when direct untrusted access to the origin is blocked.
3. For hosts that only support a config file, copy [.env.example](.env.example) to a private location **outside the public document root**. Set the host environment variable `DENO_CONFIG_FILE` to that file's absolute path. The file is parsed without overriding environment variables. Do not deploy a real `.env` file inside the website directory or commit secrets to GitHub.
4. Set a secure `PROJECT_DENO_SETUP_KEY` with at least 32 random characters. For example, generate one with `openssl rand -hex 32`. After the database is ready, open `setup-admin.html` over HTTPS and enter this one-time key to create the first admin. The setup route locks after the first account exists; remove the key from the host settings afterward. Local localhost setup continues to work without this key.
5. Deploy `index.html`, `admin.html`, `setup-admin.html`, `api/`, `storage/`, and the root `.htaccess` over HTTPS. Set PHP `display_errors=Off` and `log_errors=On` in the hosting panel; do not expose PHP stack traces in browser responses. Do not publish `.git/` or `.vscode/`. The PHP process needs write permission only for `storage/` so it can append `storage/app.log`; use a private log path via `PROJECT_DENO_LOG_FILE` if preferred. PHP's default session storage must also be writable. If it is not, set `DENO_SESSION_SAVE_PATH=storage/sessions`; the app creates the directory, which remains web-blocked. Do not make the whole project writable. `storage/.htaccess` blocks web access on Apache; on Nginx or another server, deny web requests to `storage/` and development directories in that server's configuration.
6. Check `https://your-domain.example/api/admin.php?action=status`. A healthy response has `"databaseReady":true`. Failures include a reference code; look it up in `storage/app.log` or the host's PHP error log. The API returns safe messages and does not expose database credentials or exception details.

API paths in the frontend are relative to the site, so deployments in a subdirectory work without editing localhost URLs. Keep the production database separate from local XAMPP unless you intend to migrate its client records.
