# v2 changes (benchmark only)

File changed: artifacts/medshift-guard/backend/engine/simulate.py

- Baseline ("usual practice") now tops each centre up to one month of expected use every 30 days,
  using the same forecast and monthly learning rule as MedShift. The old one-shot day-0 split is
  kept in the output as `one_shot_split` for reference.
- Trip cost is a parameter, default Rs 1,500 (was Rs 50 inside the benchmark).
- Warehouse stock still unsent at expiry now counts as expired for every policy.
- `use_solver=True` runs the OR-Tools model instead of the greedy allocator (slower; untested here).
- Output notes and assumptions are included in the API response. Existing keys are unchanged, so the
  Benchmark page still works.

Results (5 seeds x 3 noise levels, MedShift vs usual practice, Rs 1,500 trips):
expired stock -28%, stockout days -13%, trips -9%.
At low noise MedShift has +9% more stockout days. Against the old one-shot split it was -52% / -43% / +253% trips.

# v3 changes (routine centre-to-centre exchange, distance-based transport cost)

New files (backend/engine):
- geo.py        hard-coded simulated road distances between the 8 centres + transport cost = fixed + per_km x km
- rebalance.py  donor/receiver matching, trip gating, plain-language reasons
- tests/test_rebalance.py   runs without a database:  python tests/test_rebalance.py

Changed:
- backend/main.py   the optimiser run now also proposes centre-to-centre transfers on normal days
  (skipped while an outbreak is active - the emergency rebalancing takes over then).
  New field transport_per_km on /api/optimise, new endpoint GET /api/distances.
- backend/models.py  Recommendation.reason column allows longer text.
- src/App.tsx  new slider "Transport cost per km" on the Recommendations page (+ API types).

How it decides: a transfer line is proposed when a donor centre would let stock expire (or holds
more than its safety target) and a receiver centre is short. Nearest donors are used first. All
medicines for the same donor->receiver pair share ONE trip. The pair is kept only if its rupee
benefit (expected waste avoided + expected shortage avoided) beats the trip cost
(Trip penalty setting + Rs/km x distance). Rejected pairs show up as "No transfer" with the reason.

Untested: the API glue in main.py (needs FastAPI/SQLAlchemy to run). The decision logic itself is
tested against the seeded database and by tests/test_rebalance.py.

# v4 changes
- Removed the weather signal: endpoint /api/signals/weather, the header message and the
  "Weather risk hint" card on the Emergency page. The app no longer makes any external API call,
  so it is fully offline once installed (only the Google font still loads online, with a fallback).

# v5 changes
- Deleted unused Replit/scaffold files: root main.py, pyproject.toml, uv.lock, .replit, replit.md, scripts/,
  artifacts/api-server, artifacts/mockup-sandbox, lib/db, lib/api-zod, dist/, *.tsbuildinfo.
- Side effect: pnpm typecheck and API client regeneration (lib/api-spec) no longer work. Not needed to run the app.

# v6 changes (risk score, audit trail, approvals)

Risk score (Inventory, Overview, Recommendations)
- Was 0% almost everywhere because each batch was scored on its own slice of centre stock against the
  centre's whole demand, and warehouse stock was ignored.
- Now built from: demand forecast (90-day history, incl. outbreak uplift), day-to-day variation, shelf life,
  first-expiry-first-out order (earlier batches are used first), stock at every centre AND in the warehouse,
  and unit price.
- Each batch shows Expiry risk, Stock-out risk (next 14 days, counted once per medicine on the batch that
  would be sent out next), expected units/value to expire, and an overall Risk score = the higher of the two.
- Batch detail lists the reasons, the warehouse position and each centre's cover, expiry and stock-out risk.
- Recommendations show expiry risk and the receiving centre's stock-out risk before -> after the transfer,
  and a plain-language reason for every proposed transfer.

Audit trail
- Shows only approved transfers, rejected transfers and emergency actions (outbreak declared/ended,
  emergency procurement). Approvals/rejections of emergency transfers carry an Emergency tag.
- Recommendations, optimiser runs and other system entries are no longer written to the audit log.
- Filter: All types / Approved / Rejected / Emergency (also applied to the CSV export).

Approvals
- Approvals were failing after the first few because most centres were already over their storage
  capacity and the optimiser ignored stock of other medicines when checking room. The error was not
  shown, so the item just stayed in the queue.
- Optimiser now plans against each centre's real remaining room (all medicines). Demo centres get
  capacity above what they hold. Errors are now shown as a message, approved/rejected items leave the
  queue immediately, and buttons are disabled while a decision is saving.
- Bulk approve reports anything it could not approve and why.

Demo data
- Seed now overstocks the short-dated batch at two centres for five medicines, so there is real expiry
  exposure to find. The shipped medshift.db is freshly seeded (old demo approvals are cleared).

# v7 changes (Database page, day-by-day forecast)

Demand forecast
- The 30-day forecast was one flat number repeated every day. Each day is now
  (smoothed level + damped trend) x weekday factor x outbreak uplift for that date.
  Weekday factors and the trend come from the last 90 days of consumption. The outbreak uplift
  ramps up at the start of an outbreak and stops on its end date. The band is a 95% range per day.
- Forecast page shows the weekday pattern, the next-30-days total and trend, and a table of all 30 days.
- The optimiser and risk scores still use the average daily demand, so their numbers are unchanged.

Database page (new, in the sidebar)
- Browse every stored table (centres, medicines, batches, centre stock, daily consumption,
  recommendations, outbreaks, procurement requests, audit log, settings) and the calculated numbers
  (demand forecast summary, 30-day daily forecast, batch risk scores, centre batch risk, centre distances).
- Search, page through 100 rows at a time, download any table as CSV, or download every table as CSVs in one zip.
- API: GET /api/db/tables, GET /api/db/tables/{name}, GET /api/db/tables/{name}/export.csv, GET /api/db/export.zip
