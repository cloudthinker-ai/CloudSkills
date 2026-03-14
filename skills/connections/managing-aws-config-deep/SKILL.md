---
name: managing-aws-config-deep
description: |
  AWS Config deep rule and compliance management. Covers Config rules, conformance packs, aggregators, advanced queries, remediation actions, configuration history, and multi-account compliance dashboards. Use when auditing AWS resource compliance, managing Config rules, reviewing conformance pack results, or querying resource configurations across accounts.
connection_type: aws-config
preload: false
---

# AWS Config Deep Management Skill

Deep management of AWS Config rules, conformance packs, aggregators, and compliance queries.

## MANDATORY: Discovery-First Pattern

**Always inspect Config recorder status and rule compliance before changes.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Config Recorder Status ==="
aws configservice describe-configuration-recorder-status --query 'ConfigurationRecordersStatus[*].{Name:name,Recording:recording,LastStatus:lastStatus}' --output table 2>/dev/null

echo ""
echo "=== Delivery Channel ==="
aws configservice describe-delivery-channels --query 'DeliveryChannels[*].{Name:name,S3Bucket:s3BucketName,SNSTopic:snsTopicARN}' --output table 2>/dev/null

echo ""
echo "=== Config Rules Summary ==="
aws configservice describe-compliance-by-config-rule --query 'ComplianceByConfigRules[*].{Rule:ConfigRuleName,Compliance:Compliance.ComplianceType}' --output table 2>/dev/null | head -20

echo ""
echo "=== Conformance Packs ==="
aws configservice describe-conformance-packs --query 'ConformancePackDetails[*].{Name:ConformancePackName,Status:ConformancePackState}' --output table 2>/dev/null | head -10

echo ""
echo "=== Aggregators ==="
aws configservice describe-configuration-aggregators --query 'ConfigurationAggregators[*].{Name:ConfigurationAggregatorName,Type:AccountAggregationSources[0].AllAwsRegions}' --output table 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
RULE="${1:-}"

echo "=== Non-Compliant Resources ==="
if [ -n "$RULE" ]; then
  aws configservice get-compliance-details-by-config-rule --config-rule-name "$RULE" --compliance-types NON_COMPLIANT --query 'EvaluationResults[*].{Resource:EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId,Type:EvaluationResultIdentifier.EvaluationResultQualifier.ResourceType,Time:ResultRecordedTime}' --output table 2>/dev/null | head -15
else
  aws configservice describe-compliance-by-resource --compliance-types NON_COMPLIANT --query 'ComplianceByResources[*].{Type:ResourceType,Id:ResourceId,Compliance:Compliance.ComplianceType}' --output table 2>/dev/null | head -15
fi

echo ""
echo "=== Advanced Query ==="
aws configservice select-resource-config --expression "SELECT resourceId, resourceType, configuration.instanceType WHERE resourceType = 'AWS::EC2::Instance'" --query 'Results' --output text 2>/dev/null | head -10

echo ""
echo "=== Remediation Status ==="
aws configservice describe-remediation-execution-status --config-rule-name "${RULE:-*}" --query 'RemediationExecutionStatuses[*].{Resource:ResourceKey.resourceId,State:State,StepDetails:StepDetails[0].Name}' --output table 2>/dev/null | head -10

echo ""
echo "=== Conformance Pack Compliance ==="
aws configservice get-conformance-pack-compliance-summary --query 'ConformancePackComplianceSummaryList[*].{Pack:ConformancePackName,Compliant:ConformancePackComplianceStatus}' --output table 2>/dev/null | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Show compliance summaries, not individual evaluation details
- Use advanced queries for targeted resource inspection
- Highlight non-compliant resources with remediation status

## Safety Rules
- **NEVER auto-remediate without reviewing the remediation action**
- **Test custom rules** in evaluation-only mode first
- **Review advanced query results** before bulk operations
- **Check aggregator coverage** spans all required accounts/regions
- **Validate conformance pack parameters** before deployment
