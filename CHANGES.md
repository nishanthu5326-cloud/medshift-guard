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
