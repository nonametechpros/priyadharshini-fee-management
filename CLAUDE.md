# Changelog

## 2026-07-20

Pushed a set of updates to the Priyadarshini Fee Management app.

**Fixes**
- Payment lists (Dashboard and All Payments) no longer show "Unknown student" — names now load reliably every time.
- Deleting a student now automatically removes their related payment and activity records too, with a warning that shows exactly what will be removed before you confirm.

**Performance**
- All Payments and Student List now load more entries automatically as you scroll, instead of needing to tap "Load more".
- Increased the number of records loaded per page for smoother browsing.

**Reports**
- The "Monthly Fee Summary" has been reworked into "Fee Summary" — you can now pick any date range (defaults to the current month) instead of only a full year.
- The PDF export has been rebuilt: it now includes the school logo, the selected date range, an itemized list of payments (serial no., date, student name, collected, pending), and totals at the bottom.

Live: https://priyadarsini-app.web.app
