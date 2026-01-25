# Shipyard Pro Product Gates

**LICENSE STATUS**: ⚠️ UNLICENSED (TRIAL MODE)

> **WARNING**: This build is from an UNLICENSED instance.
> Artifacts are for evaluation purposes only and should not be used for production delivery.
> To activate a license: `pnpm -s license:activate "<LICENSE_STRING>"`

## Summary

- Evidence: OK
- Audit: FAIL
- Cost: OK

## Evidence
- Bundle: dist/gates/artifacts/evidence/
- Files: evidence.json, EVIDENCE.md, SHA256SUMS.txt, VERIFY.txt

## Audit
- Export: dist/gates/artifacts/audit/activity_export.json
- NDJSON: dist/gates/artifacts/audit/activity_export.ndjson
- Schema: src/schemas/activity_event.schema.json
- Verify: dist/gates/artifacts/audit/VERIFY.txt, RETENTION.txt

## Cost
- JSON: dist/gates/artifacts/cost/cost_report.json
- CSV: dist/gates/artifacts/cost/cost_report.csv
- Verify: dist/gates/artifacts/cost/VERIFY.txt
