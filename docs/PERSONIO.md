# Personio Integration — Salesforce Setup Guide

This document describes all the steps required to set up the Salesforce side of the Personio time-tracking integration. The integration syncs attendance data from Personio into Salesforce `Time__c` records and links them to the correct `Contact` and `Package__c`.

## Overview

The integration uses the **OAuth 2.0 JWT Bearer Flow** to authenticate a dedicated technical user against the Salesforce API. It requires:

1. Custom fields on `Contact` and `Time__c` to store Personio identifiers and sync timestamps
2. A Permission Set granting the integration user access to the relevant objects and fields
3. A Connected App configured for JWT authentication
4. A dedicated technical Salesforce user

## Prerequisites

- Salesforce CLI (`sf`) installed
- Admin access to the target Salesforce org
- OpenSSL (for generating the JWT key pair)

---

## Step 1 — Deploy Custom Fields and Permission Set

Four custom fields need to be created across two objects:

### Contact

| Field API Name | Label | Type | Properties |
|----------------|-------|------|------------|
| `PersonioPersonId__c` | PersonioPersonId | Text(255) | External ID, Unique, Case Sensitive |
| `PersonioPersonSyncTimeStamp__c` | PersonioPersonSyncTimeStamp | DateTime | — |

`PersonioPersonId__c` stores the Personio employee ID and is used to link a Salesforce Contact to a Personio person. `PersonioPersonSyncTimeStamp__c` records when the link was last written.

### Time__c

| Field API Name | Label | Type | Properties |
|----------------|-------|------|------------|
| `PersonioImportId__c` | PersonioImportId | Text(255) | External ID, Unique, Case Sensitive |
| `PersonioImportTimeStamp__c` | PersonioImportTimeStamp | DateTime | — |

`PersonioImportId__c` stores the Personio attendance UUID and serves as the upsert key for time entries. `PersonioImportTimeStamp__c` records the UTC timestamp of the sync run.

### Permission Set: `Personio_Integration`

The permission set grants the integration user access to the objects and fields it needs. It is deployed as metadata alongside the custom fields.

**Object-level access:**

| Object | Create | Read | Edit | Delete |
|--------|--------|------|------|--------|
| `Contact` | — | Yes | Yes | — |
| `Package__c` | — | Yes | — | — |
| `Project__c` | — | Yes | — | — |
| `Time__c` | Yes | Yes | Yes | — |

**Field-level access:**

| Field | Readable | Editable |
|-------|----------|----------|
| `Contact.PersonioPersonId__c` | Yes | Yes |
| `Contact.PersonioPersonSyncTimeStamp__c` | Yes | Yes |
| `Package__c.PackageNr__c` | Yes | — |
| `Package__c.PackageType__c` | Yes | — |
| `Time__c.PersonioImportId__c` | Yes | Yes |
| `Time__c.PersonioImportTimeStamp__c` | Yes | Yes |
| `Time__c.Timetracker__c` | Yes | Yes |
| `Time__c.ServiceType__c` | Yes | Yes |
| `Time__c.StartHhMm__c` | Yes | Yes |
| `Time__c.EndHhMm__c` | Yes | Yes |
| `Time__c.DurationHhMm__c` | Yes | Yes |
| `Time__c.DurationHhMmN__c` | Yes | Yes |
| `Time__c.Description__c` | Yes | Yes |
| `User.InternalContactID__c` | Yes | — |

Some fields (e.g. `PackageStatus__c`, `DateFrom__c`, `DateUntil__c`, `Package__c` lookup) are required/non-nillable on the object and are automatically accessible via object-level read permissions — they do not need explicit FLS entries.

### Deployment

All metadata is bundled in `force-app/main/default/package.xml`. To deploy:

```bash
# Dry-run (validate only)
sf project deploy start \
  --manifest force-app/main/default/package.xml \
  --target-org <org-alias> \
  --dry-run

# Actual deployment
sf project deploy start \
  --manifest force-app/main/default/package.xml \
  --target-org <org-alias>
```

---

## Step 2 — Generate the JWT Key Pair

Generate a private key and self-signed certificate for JWT authentication:

```bash
# Generate 2048-bit RSA private key
openssl genrsa -out private_key.pem 2048

# Generate self-signed certificate (valid for 10 years)
openssl req -new -x509 -key private_key.pem -out certificate.crt -days 3650 \
  -subj "/CN=Personio Integration/O=Brand Leadership/C=CH"
```

This produces:
- `private_key.pem` — given to the integration (Michel); used to sign JWT tokens
- `certificate.crt` — uploaded to the Connected App in Salesforce; used to verify JWT tokens

**Keep `private_key.pem` secure.** Do not commit it to version control.

---

## Step 3 — Create the Connected App

This must be done in the Salesforce UI (Setup):

1. Go to **Setup → App Manager → New Connected App**
2. Fill in:
   - **Connected App Name:** `Personio Integration`
   - **API Name:** `Personio_Integration`
   - **Contact Email:** admin email address
3. Under **API (Enable OAuth Settings)**:
   - Check **Enable OAuth Settings**
   - **Callback URL:** `https://login.salesforce.com/services/oauth2/callback`
   - Check **Use digital signatures** and upload `certificate.crt`
   - **Selected OAuth Scopes:**
     - `Manage user data via APIs (api)`
     - `Perform requests at any time (refresh_token, offline_access)`
4. **Save** — note down the **Consumer Key (Client ID)** and **Consumer Secret**
5. Go to **Manage → Edit Policies**:
   - Set **Permitted Users** to `Admin approved users are pre-authorized`
   - Save
6. On the same Manage page, scroll to **Permission Sets**:
   - Click **Manage Permission Sets**
   - Add `Personio Integration`
   - Save

---

## Step 4 — Create the Technical User

Create a dedicated Salesforce user for the integration:

1. **Setup → Users → New User**
   - **First Name:** `Personio`
   - **Last Name:** `Integration`
   - **Email:** shared admin mailbox
   - **Username:** e.g. `personio-integration@brandleadership.ch`
   - **User License:** `Salesforce Integration` (preferred) or `Salesforce`
   - **Profile:** API-enabled profile (e.g. `System Administrator` or a custom integration profile)
2. **Save**
3. **Log in as the new user at least once** (required before JWT works) — use the password reset email sent to the configured email address
4. Assign the permission set:
   - Via UI: User detail page → Permission Set Assignments → add `Personio Integration`
   - Via CLI:
     ```bash
     sf org assign permset --name Personio_Integration --target-org <org-alias>
     ```

---

## Step 5 — Test the JWT Authentication

Verify the full JWT flow works:

```bash
sf org login jwt \
  --client-id <consumer-key> \
  --jwt-key-file private_key.pem \
  --username personio-integration@brandleadership.ch \
  --instance-url https://brandleadership.my.salesforce.com
```

Then test data access:

```bash
# Read packages
sf data query \
  --query "SELECT Id, Name, PackageNr__c, PackageStatus__c, PackageType__c FROM Package__c WHERE PackageType__c = 'Time' AND PackageStatus__c = 'Open' LIMIT 5" \
  --target-org personio-integration@brandleadership.ch

# Read contacts
sf data query \
  --query "SELECT Id, FirstName, LastName, PersonioPersonId__c FROM Contact LIMIT 5" \
  --target-org personio-integration@brandleadership.ch

# Read time entries
sf data query \
  --query "SELECT Id, Name, PersonioImportId__c, PersonioImportTimeStamp__c FROM Time__c LIMIT 5" \
  --target-org personio-integration@brandleadership.ch

# Read user → contact mapping
sf data query \
  --query "SELECT Id, Email, InternalContactID__c FROM User LIMIT 5" \
  --target-org personio-integration@brandleadership.ch
```

---

## Step 6 — Hand Over Credentials

Provide the following to the integration developer:

| Item | Source |
|------|--------|
| **Client ID** | Connected App → Consumer Key |
| **Client Secret** | Connected App → Consumer Secret |
| **Private Key File** | `private_key.pem` (generated in Step 2) |
| **Instance URL** | `https://brandleadership.my.salesforce.com` |
| **Username** | `personio-integration@brandleadership.ch` |

---

## Troubleshooting

### `user hasn't approved this consumer`
The permission set is not linked to the Connected App, or the user doesn't have it assigned. Check both:
- Connected App → Manage → Permission Sets → `Personio Integration` must be listed
- User detail → Permission Set Assignments → `Personio Integration` must be assigned

### `External client app is not installed in this org`
The Connected App's **Permitted Users** policy is not set to `Admin approved users are pre-authorized`. Go to Manage → Edit Policies and change it.

### `user is not admin approved to access this app`
The specific user trying to authenticate does not have the permission set that is linked to the Connected App. Assign the `Personio Integration` permission set to that user.

### `expired access/refresh token` on `sf org list`
The web-based auth session expired. Re-authorize:
```bash
sf org login web --alias blc-prod --instance-url https://brandleadership.my.salesforce.com
```

---

## Data Model Reference

### Objects Used by the Integration

#### `Package__c` (read-only)

| Field | Type | Notes |
|-------|------|-------|
| `Id` | ID | Salesforce record ID |
| `Name` | Text | Package name |
| `PackageNr__c` | Text | Cross-system key (e.g. `PA-158284`); upsert key in Personio |
| `PackageStatus__c` | Picklist | Filtered on `'Open'` for initial sync |
| `PackageType__c` | Picklist | Only `'Time'` packages are synced |
| `LastModifiedDate` | DateTime | Watermark for incremental sync |
| `ProjectName__r.Name` | Text | Parent project name (relationship) |
| `ProjectName__r.ContractPartner__r.Name` | Text | Client / contract partner (nested relationship) |

#### `Time__c` (read-write, upsert)

| Field | Type | Notes |
|-------|------|-------|
| `PersonioImportId__c` | Text (External ID) | Upsert key — Personio attendance UUID |
| `PersonioImportTimeStamp__c` | DateTime | UTC timestamp of the sync run |
| `Timetracker__c` | Lookup → Contact | Employee |
| `Package__c` | Lookup → Package__c | Package the time entry belongs to |
| `ServiceType__c` | Picklist | Always `'WorkTime'` |
| `DateFrom__c` | Date | Start date (Europe/Zurich local) |
| `DateUntil__c` | Date | End date (Europe/Zurich local) |
| `StartHhMm__c` | Text | Start time `HH:MM` (Europe/Zurich local) |
| `EndHhMm__c` | Text | End time `HH:MM` (Europe/Zurich local) |
| `DurationHhMm__c` | Text | Duration as `H:MM` |
| `DurationHhMmN__c` | Number | Duration as decimal hours (e.g. `1.5`) |
| `Description__c` | Text (Long) | Comment from Personio |

#### `User` (read-only)

| Field | Type | Notes |
|-------|------|-------|
| `Email` | Email | Looked up by Personio employee email |
| `InternalContactID__c` | Text | Linked Contact ID for time-entry lookups |

#### `Contact` (read-write)

| Field | Type | Notes |
|-------|------|-------|
| `Id` | ID | Salesforce record ID |
| `PersonioPersonId__c` | Text (External ID) | Personio employee ID; used to find already-linked contacts |
| `PersonioPersonSyncTimeStamp__c` | DateTime | Timestamp of when the link was last written |

---

## Deployed Orgs

| Org | Alias | Instance URL | Status |
|-----|-------|-------------|--------|
| BLC Production | `blc-prod` | `https://brandleadership.my.salesforce.com` | Deployed 2026-05-28 |
| BLC Nextgen | `blc-nextgen` | `https://victorhotzag.my.salesforce.com` | Deployed 2026-05-28 |
