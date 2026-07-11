# Known Limitations — MR SQUIRREL v1.0

This document lists features that are intentionally not yet implemented.
These are not bugs — they are deferred features documented for transparency.

---

## Export

### PDF Export
- **Status:** Not implemented
- **UI:** Button exists but is disabled with "Coming Soon" tooltip
- **Reason:** Requires a PDF generation library compatible with Flutter Web
- **Planned:** Phase 20+

---

## Backup & Recovery

### Restore from Backup File
- **Status:** Not implemented
- **UI:** Restore button exists but shows "Coming Soon" dialog
- **Reason:** Requires careful data validation and Supabase write permissions
- **Planned:** Phase 20+

### Automatic Scheduled Backup
- **Status:** Not implemented
- **Current:** Manual backup only (local JSON download)
- **Cloud Backup:** Supabase handles automatic daily backups
- **Planned:** Phase 20+

---

## Authentication

### User Invitation from Dashboard
- **Status:** Not implemented
- **UI:** "Invite User" button exists but shows "Coming Soon" dialog
- **Reason:** Requires Supabase Auth admin API integration
- **Planned:** Phase 20+

### Password Reset from Dashboard
- **Status:** Not implemented
- **UI:** "Reset Password" button exists but shows "Coming Soon" dialog
- **Planned:** Phase 20+

### Role-Based Access Control (RBAC)
- **Status:** Partial — roles are stored but not enforced at UI level
- **Current:** All authenticated users see the same dashboard
- **Planned:** Phase 21+

---

## Device Management

### Force Sync
- **Status:** Not implemented
- **UI:** "Force Sync" button exists but shows "Coming Soon" dialog
- **Reason:** Requires a push notification or polling mechanism to the Android app
- **Planned:** Phase 20+

### Revoke Device
- **Status:** Not implemented
- **UI:** "Revoke Device" button exists but shows "Coming Soon" dialog
- **Reason:** Requires auth token invalidation at device level
- **Planned:** Phase 20+

---

## Android App

### Barcode Scanner
- **Status:** Not implemented
- **Reason:** Hardware dependency, not required for Phase 1
- **Planned:** Phase 22+

### Push Notifications
- **Status:** Not implemented
- **Reason:** Requires Firebase Cloud Messaging setup
- **Planned:** Phase 22+

### Product Images
- **Status:** Not implemented
- **Reason:** Storage bucket created but upload UI not built
- **Planned:** Phase 23+

### Receipt Printing
- **Status:** Not implemented
- **Planned:** Phase 22+

---

## Business Features

### Supplier Management
- **Status:** Not implemented
- **Reason:** Not required for Phase 1 warung operations
- **Planned:** Phase 24+

### Purchase Orders
- **Status:** Not implemented
- **Planned:** Phase 24+

### Multi-Warehouse / Multi-Location
- **Status:** Not implemented
- **Reason:** Architecture supports organization_id but not multiple locations
- **Planned:** Future

### Employee Commission
- **Status:** Not implemented
- **Planned:** Future

### Tax Calculation
- **Status:** Not implemented
- **Planned:** Future

---

## Synchronization

### Pull Synchronization (Phase 8B)
- **Status:** Partially implemented
- **Current:** Pull cursor is advanced but received records are not applied locally
- **Impact:** Changes made on web dashboard do not appear on Android
- **Planned:** Phase 8C completion before pilot

### Conflict Resolution UI
- **Status:** No UI — resolved automatically by last-write-wins
- **Planned:** Phase 21+

---

## Web Dashboard

### Real-time Updates
- **Status:** Not implemented — data refreshes only on manual reload
- **Planned:** Phase 20+

### Mobile Support
- **Status:** Not supported — dashboard is desktop-only
- **Reason:** Intentional — dashboard is for administrators on desktop
- **Planned:** Not planned

---

## Notes

All limitations above are intentional design decisions for Phase 1.
The application is designed specifically for a single-location Indonesian warung kelontong.
Features listed above are deferred until validated demand exists.
