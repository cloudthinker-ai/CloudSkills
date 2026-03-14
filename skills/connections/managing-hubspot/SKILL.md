---
name: managing-hubspot
description: HubSpot CRM management - search and retrieve contacts, companies, deals, tickets, and other CRM objects. Use when working with HubSpot data, analyzing sales pipelines, or querying customer information.
connection_type: hubspot
preload: false
---

# Managing HubSpot

Tools for interacting with HubSpot CRM via the official MCP server.

**Important:** All tools require a parameter object. Pass `{}` for tools with no required parameters.

## Supported CRM Objects

Read-only access to: contacts, companies, deals, tickets, carts, products, orders, line items, invoices, quotes, and subscriptions.

## Tools

### User & Account

| Tool | Description |
|------|-------------|
| `get_user_details({})` | Get authenticated user info, account details, and available objects/tools |

### Contacts

| Tool | Description |
|------|-------------|
| `search_contacts({ query, count?, propertyList? })` | Search contacts by query string |
| `get_contact({ id, properties? })` | Get contact by ID |

### Companies

| Tool | Description |
|------|-------------|
| `search_companies({ query, count?, propertyList? })` | Search companies by query string |
| `get_company({ id, properties? })` | Get company by ID |

### Deals

| Tool | Description |
|------|-------------|
| `search_deals({ query, count?, propertyList? })` | Search deals by query string |
| `get_deal({ id, properties? })` | Get deal by ID |

### Tickets

| Tool | Description |
|------|-------------|
| `search_tickets({ query, count?, propertyList? })` | Search tickets by query string |
| `get_ticket({ id, properties? })` | Get ticket by ID |

### Associations

| Tool | Description |
|------|-------------|
| `list_associations({ objectType, objectId, toObjectType })` | List associations between objects |

## Examples

### Search Contacts

```typescript
import { search_contacts } from '@connections/hubspot';

const contacts = await search_contacts({
  query: 'john@example.com',
  count: 10,
  propertyList: ['email', 'firstname', 'lastname', 'company']
});
```

### Analyze Deal Pipeline

```typescript
import { search_deals } from '@connections/hubspot';

const deals = await search_deals({
  query: 'Decision Maker Bought In',
  propertyList: ['dealname', 'amount', 'dealstage', 'closedate']
});
```

### Get Contact with Company Association

```typescript
import { get_contact, list_associations } from '@connections/hubspot';

const contact = await get_contact({
  id: 'contact-id',
  properties: ['email', 'firstname', 'lastname']
});

const companies = await list_associations({
  objectType: 'contacts',
  objectId: 'contact-id',
  toObjectType: 'companies'
});
```

## Common Errors

| Error | Solution |
|-------|----------|
| Authentication failed | Re-authenticate via OAuth flow |
| Object not found | Verify object ID and permissions |
| Rate limited | Reduce request frequency |
| 422 | Pass `{}` for tools with no required params |
