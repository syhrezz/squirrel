# MR SQUIRREL — QA Testing Documentation

## Purpose

This package defines the acceptance testing framework for MR SQUIRREL before every release.
It is used to prove the application is reliable before any pilot deployment.

## Scope

- Android operational app (Flutter)
- Web administration dashboard (Flutter Web)
- Supabase backend
- Offline-first synchronization

## How to Execute Tests

1. Open `acceptance_checklist.md`
2. Execute tests in order, module by module
3. Record result (PASS / FAIL / BLOCKED) for each item
4. Log execution details in `test_execution_log.md`
5. File any failures using `bug_template.md`

## Pass / Fail Criteria

| Result   | Meaning |
|----------|---------|
| PASS     | Actual result matches expected result exactly |
| FAIL     | Actual result does not match expected result |
| BLOCKED  | Test cannot be executed due to external dependency |
| SKIP     | Test intentionally skipped (document reason) |

## Priority Levels

| Priority | Description |
|----------|-------------|
| P0       | Critical — blocks core business operations. Release cannot proceed if any P0 fails. |
| P1       | High — major feature broken. Release should not proceed without resolution. |
| P2       | Medium — feature partially broken. Can release with documented workaround. |
| P3       | Low — cosmetic or edge case. Can release, schedule fix in next sprint. |

## Release Criteria

A release may proceed when:
- All P0 tests PASS
- All P1 tests PASS or have accepted workarounds
- No more than 3 P2 failures
- All known P3 failures are documented in `known_limitations.md`

## Regression Testing Workflow

1. Run acceptance checklist before every release
2. On any code change to sync infrastructure, re-run all Synchronization tests
3. On any database schema change, re-run all data integrity tests
4. On any UI change, re-run affected module tests
5. After a bug fix, re-run the specific test case plus surrounding tests

## Test Environment Requirements

- Android emulator or physical device (Android 10+)
- Chrome browser (latest stable)
- Supabase project with migrations 001–007 applied
- Two devices available for multi-device sync tests
- Network control capability (for offline tests)
