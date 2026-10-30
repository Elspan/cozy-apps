# vaultwarden

Managed [Vaultwarden](https://github.com/dani-garcia/vaultwarden) password manager, compatible with the official Bitwarden apps, browser extensions and CLI.

Each instance runs one Vaultwarden pod with its SQLite database, attachments and sends on a persistent volume. It is published over HTTPS at `vaultwarden-<name>.<tenant host>`, or at `host` when set, through the tenant's Ingress or Gateway.

## Getting started

Signups are disabled by default. To create the first account:

1. Open the `vaultwarden-<name>-credentials` secret in the dashboard. Copy the `url` and `admin-token` values.
2. Open `<url>/admin` and sign in with the admin token.
3. Under **Users**, invite your email address. Then create the account from the main page with that same address. Without SMTP no invitation email is sent, but the invited address can still register.

Alternatively, set `signupsAllowed: true` or list your email domains in `signupsDomainsWhitelist`.

## Notes

- Settings saved in the admin panel go to `config.json` on the data volume. They **override** the values of this app. Once a setting is saved there, change it in the admin panel, or reset it there to fall back to the app values.
- The admin token is a random 48-character plain-text token. Vaultwarden logs a warning recommending an Argon2 hash; this is expected. Set `adminPanel: false` to turn the panel off when you don't need it.
- Give `smtp.security: "off"` in quotes. Unquoted, YAML parses `off` as a boolean.

## Parameters

### Common parameters

| Name               | Description                                                                                                  | Type       | Value   |
| ------------------ | ------------------------------------------------------------------------------------------------------------ | ---------- | ------- |
| `host`             | Hostname for external access to Vaultwarden (defaults to `vaultwarden-<name>` subdomain of the tenant host). | `string`   | `""`    |
| `size`             | Persistent Volume size for the vault data (SQLite database, attachments and sends).                          | `quantity` | `1Gi`   |
| `storageClass`     | StorageClass used to store the data.                                                                         | `string`   | `""`    |
| `resources`        | CPU and memory for the Vaultwarden container, applied as both requests and limits.                           | `object`   | `{}`    |
| `resources.cpu`    | Number of CPU cores allocated.                                                                               | `quantity` | `500m`  |
| `resources.memory` | Amount of memory allocated.                                                                                  | `quantity` | `256Mi` |


### Account settings

| Name                      | Description                                                                                                                                          | Type       | Value   |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- | ------- |
| `signupsAllowed`          | Allow anyone who can reach the instance to create an account. When disabled, new users are invited from the admin panel or by an organization admin. | `bool`     | `false` |
| `signupsDomainsWhitelist` | Email domains whose users can sign up even when `signupsAllowed` is disabled (e.g. `example.org`).                                                   | `[]string` | `[]`    |
| `invitationsAllowed`      | Allow organization owners and admins to invite new users.                                                                                            | `bool`     | `true`  |
| `adminPanel`              | Enable the `/admin` panel. Its token is stored in the `admin-token` key of the `vaultwarden-<name>-credentials` secret.                              | `bool`     | `true`  |


### SMTP configuration

| Name            | Description                                                                            | Type     | Value      |
| --------------- | -------------------------------------------------------------------------------------- | -------- | ---------- |
| `smtp`          | Outgoing mail, used for invitations, email verification, email 2FA and password hints. | `object` | `{}`       |
| `smtp.host`     | SMTP server hostname. Leave empty to disable email.                                    | `string` | `""`       |
| `smtp.port`     | SMTP server port. Defaults to 587, 465 or 25 depending on `security`.                  | `int`    | `0`        |
| `smtp.security` | Connection security.                                                                   | `string` | `starttls` |
| `smtp.from`     | Sender address. Required when `host` is set.                                           | `string` | `""`       |
| `smtp.username` | SMTP username.                                                                         | `string` | `""`       |
| `smtp.password` | SMTP password.                                                                         | `string` | `""`       |
