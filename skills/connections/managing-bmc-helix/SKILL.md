---
name: managing-bmc-helix
description: |
  BMC Helix ITSM platform management covering incident management, problem management, change management, and CMDB operations. Use when creating or updating incidents with categorization and assignment, managing problem investigation workflows, processing change requests through CAB approval, or querying CMDB for infrastructure configuration items and relationships.
connection_type: bmc-helix
preload: false
---

# BMC Helix ITSM Management Skill

Manage and analyze BMC Helix incidents, problems, changes, and CMDB.

## API Conventions

### Authentication
All API calls use JWT token obtained via `/api/jwt/login`. Token is injected automatically.

### Base URL
`https://{{server}}/api/arsys/v1`

### Core Helper Function

```bash
#!/bin/bash

bmc_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: AR-JWT $BMC_TOKEN" \
            -H "Content-Type: application/json" \
            "${BMC_HELIX_URL}/api/arsys/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: AR-JWT $BMC_TOKEN" \
            -H "Content-Type: application/json" \
            "${BMC_HELIX_URL}/api/arsys/v1${endpoint}"
    fi
}
```

## Common Operations

### Incident Management

```bash
#!/bin/bash
echo "=== Open Incidents by Priority ==="
bmc_api GET "/entry/HPD:IncidentInterface?q='Status'<\"Resolved\"&sort=Priority.asc&limit=25&fields=values(Incident Number,Description,Priority,Status,Assignee)" \
    | jq -r '.entries[] | .values | "\(.["Incident Number"])\t\(.Priority)\t\(.Status)\t\(.Description[0:60])"' \
    | column -t

echo ""
echo "=== Critical Incidents ==="
bmc_api GET "/entry/HPD:IncidentInterface?q='Priority'=\"Critical\" AND 'Status'<\"Resolved\"&limit=10" \
    | jq -r '.entries[] | .values | "\(.["Incident Number"])\t\(.Status)\t\(.Description[0:60])"' \
    | column -t
```

### Problem Management

```bash
#!/bin/bash
echo "=== Open Problems ==="
bmc_api GET "/entry/PBM:ProblemInterface?q='Status'<\"Closed\"&sort=Priority.asc&limit=20&fields=values(Problem Investigation ID,Description,Priority,Status,Assignee)" \
    | jq -r '.entries[] | .values | "\(.["Problem Investigation ID"])\t\(.Priority)\t\(.Status)\t\(.Description[0:50])"' \
    | column -t

echo ""
echo "=== Known Errors ==="
bmc_api GET "/entry/PBM:KnownErrorInterface?q='Status'=\"Known Error\"&limit=15" \
    | jq -r '.entries[] | .values | "\(.["Known Error ID"])\t\(.Description[0:60])"' \
    | column -t
```

### Change Management

```bash
#!/bin/bash
echo "=== Pending Change Requests ==="
bmc_api GET "/entry/CHG:ChangeInterface?q='Change Request Status'<\"Completed\"&sort=Risk Level.desc&limit=20" \
    | jq -r '.entries[] | .values | "\(.["Infrastructure Change Id"])\t\(.["Risk Level"])\t\(.["Change Request Status"])\t\(.Description[0:50])"' \
    | column -t

echo ""
echo "=== Scheduled Changes (next 7 days) ==="
bmc_api GET "/entry/CHG:ChangeInterface?q='Change Request Status'=\"Scheduled\" AND 'Scheduled Start Date'>=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"&limit=15" \
    | jq -r '.entries[] | .values | "\(.["Infrastructure Change Id"])\t\(.["Scheduled Start Date"])\t\(.Description[0:50])"' \
    | column -t
```

### CMDB Operations

```bash
#!/bin/bash
echo "=== Configuration Items ==="
bmc_api GET "/entry/BMC.CORE:BMC_BaseElement?q='DatasetId'=\"BMC.ASSET\"&limit=25&fields=values(Name,ClassId,Category,Item,MarkAsDeleted)" \
    | jq -r '.entries[] | .values | "\(.Name)\t\(.ClassId)\t\(.Category)\t\(.Item)"' \
    | column -t

echo ""
echo "=== CI Relationships ==="
CI_ID="${1:?CI ReconciliationIdentity required}"
bmc_api GET "/entry/BMC.CORE:BMC_BaseRelationship?q='Source.ReconciliationIdentity'=\"${CI_ID}\" OR 'Destination.ReconciliationIdentity'=\"${CI_ID}\"&limit=20" \
    | jq -r '.entries[] | .values | "\(.Name)\t\(.Source.Name) -> \(.Destination.Name)"' \
    | column -t
```

## Common Pitfalls

- **AR-JWT tokens**: Tokens expire — handle 401 responses with re-authentication
- **Qualification syntax**: Uses AR System qualification syntax — strings need double quotes inside single-quoted query
- **Form names**: Use full form names like `HPD:IncidentInterface` — case-sensitive
- **Field names**: Field names are case-sensitive and may contain spaces — always quote with brackets
- **Rate limits**: Configurable per server — check with your admin
- **Pagination**: Use `offset` and `limit` parameters — default limit varies
- **CMDB datasets**: Filter by `DatasetId` to separate asset data from other CI sources
