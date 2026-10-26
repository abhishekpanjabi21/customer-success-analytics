"""
Synthetic SaaS Customer Success dataset generator.
Creates 6 CSV files that behave like real CRM / billing / product data.
A hidden 'fit' score per account drives engagement, NPS, churn and expansion,
so the analysis finds real patterns (low usage -> churn, slow onboarding -> churn).
"""
import numpy as np, pandas as pd, os
from datetime import date, timedelta

rng = np.random.default_rng(42)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")
os.makedirs(OUT, exist_ok=True)

N = 2600
AS_OF = pd.Timestamp("2026-09-01")
months = pd.date_range("2024-01-01", "2026-09-01", freq="MS")

industries = ["Technology", "Healthcare", "Financial Services", "Retail & E-commerce",
              "Manufacturing", "Education", "Media & Marketing", "Logistics"]
regions = ["North America", "EMEA", "APAC", "LATAM"]
region_p = [0.45, 0.28, 0.20, 0.07]
segments = ["SMB", "Mid-Market", "Enterprise"]
seg_p = [0.60, 0.30, 0.10]
plan_price = {"Starter": 12, "Growth": 25, "Enterprise": 45}  # USD per seat per month
csms = ["Priya Sharma", "Daniel Brooks", "Aisha Khan", "Marco Rossi", "Emily Chen",
        "Rahul Mehta", "Sofia Alvarez", "James Carter", "Neha Iyer", "Lucas Martin"]
acq_channels = ["Inbound", "Outbound", "Partner", "Self-serve"]

syl1 = ["Nova", "Blue", "Peak", "Bright", "Core", "Swift", "Prime", "Green", "Silver", "Apex",
        "Clear", "Bold", "True", "North", "Urban", "Vertex", "Lumen", "Atlas", "Orbit", "Pixel"]
syl2 = ["works", "labs", "logic", "stack", "flow", "path", "point", "wave", "ly", "grid",
        "sphere", "forge", "nest", "hub", "scale", "line", "bridge", "craft", "base", "mind"]
sfx = ["Inc", "Ltd", "LLC", "Group", "Solutions", "Technologies", "Co", "Systems"]

accounts, monthly, usage, nps, onboarding, tickets = [], [], [], [], [], []
used_names = set()
tid = 1; rid = 1

for i in range(N):
    aid = f"ACC-{10001 + i}"
    while True:
        name = f"{rng.choice(syl1)}{rng.choice(syl2)} {rng.choice(sfx)}"
        if name not in used_names:
            used_names.add(name); break
    seg = rng.choice(segments, p=seg_p)
    if seg == "SMB":
        plan = rng.choice(["Starter", "Growth"], p=[0.7, 0.3]); seats = int(rng.integers(5, 40))
    elif seg == "Mid-Market":
        plan = rng.choice(["Growth", "Enterprise"], p=[0.75, 0.25]); seats = int(rng.integers(40, 200))
    else:
        plan = rng.choice(["Growth", "Enterprise"], p=[0.2, 0.8]); seats = int(rng.integers(150, 600))

    fit = float(np.clip(rng.normal(0.62, 0.18), 0.05, 0.98))   # hidden customer quality
    # signup between Jul 2023 and Jun 2026
    signup = pd.Timestamp("2023-07-01") + pd.Timedelta(days=int(rng.integers(0, 1150)))
    start_month = max(pd.Timestamp(signup.year, signup.month, 1), months[0])

    # Onboarding
    base_days = {"SMB": 14, "Mid-Market": 35, "Enterprise": 60}[seg]
    target = {"SMB": 21, "Mid-Market": 45, "Enterprise": 75}[seg]
    days_live = int(max(3, rng.normal(base_days * (1.6 - fit), base_days * 0.3)))
    go_live = signup + pd.Timedelta(days=days_live)
    if go_live > AS_OF:
        ob_status = "In Progress"; go_live_str = None; days_live_out = None
    else:
        ob_status = "Completed On Time" if days_live <= target else "Completed Late"
        go_live_str = go_live.date(); days_live_out = days_live
    onboarding.append(dict(account_id=aid, kickoff_date=signup.date(), go_live_date=go_live_str,
                           days_to_go_live=days_live_out, target_days=target,
                           onboarding_status=ob_status,
                           training_sessions=int(rng.integers(1, 4 if seg == "SMB" else 9)),
                           onboarding_csat=int(np.clip(round(rng.normal(2.5 + 2.5 * fit, 0.6)), 1, 5))))

    # Monthly simulation
    price = plan_price[plan]
    cur_seats = seats
    hazard = 0.004 + 0.045 * (1 - fit) ** 2
    if ob_status == "Completed Late": hazard *= 1.5
    if seg == "Enterprise": hazard *= 0.6
    churn_month = None
    hist = []
    for m in months[months >= start_month]:
        tenure = (m.year - start_month.year) * 12 + m.month - start_month.month
        if tenure >= 2 and rng.random() < hazard:
            churn_month = m; break
        if tenure >= 2:
            r = rng.random()
            if r < 0.035 * fit:                          # expansion
                cur_seats = int(cur_seats * rng.uniform(1.08, 1.35)) + 1
            elif r > 1 - 0.02 * (1 - fit):               # contraction
                cur_seats = max(3, int(cur_seats * rng.uniform(0.75, 0.93)))
        hist.append((m, cur_seats))

    churn_reason = None
    if churn_month is not None:
        churn_reason = rng.choice(["Low adoption", "Budget cuts", "Switched to competitor",
                                   "Poor onboarding experience", "Missing features",
                                   "Company acquired / closed"],
                                  p=[0.30, 0.18, 0.20, 0.12, 0.13, 0.07])

    n_hist = len(hist)
    for k, (m, s) in enumerate(hist):
        mrr = s * price
        monthly.append(dict(account_id=aid, month=m.date(), seats=s, mrr=mrr))
        # usage: decays in last 3 months before churn (the warning signal)
        util = rng.normal(0.35 + 0.6 * fit, 0.08)
        if churn_month is not None and k >= n_hist - 3:
            util *= 0.6 - 0.1 * (k - (n_hist - 3))
        util = float(np.clip(util, 0.02, 1.0))
        au = int(round(s * util))
        usage.append(dict(account_id=aid, month=m.date(), licensed_seats=s, active_users=au,
                          logins=int(au * rng.uniform(8, 22)),
                          features_adopted=int(np.clip(round(rng.normal(3 + 9 * fit, 1.5)), 1, 12))))
        # support tickets
        lam = (0.15 + 1.2 * (1 - fit)) * (1 + s / 600)
        for _ in range(rng.poisson(lam)):
            created = m + pd.Timedelta(days=int(rng.integers(0, 28)))
            pri = rng.choice(["Low", "Medium", "High", "Urgent"], p=[0.35, 0.40, 0.18, 0.07])
            hrs = round(float(rng.gamma(2, {"Low": 20, "Medium": 12, "High": 6, "Urgent": 2.5}[pri])), 1)
            tickets.append(dict(ticket_id=f"TKT-{tid:06d}", account_id=aid, created_date=created.date(),
                                category=rng.choice(["Bug", "How-to", "Billing", "Integration", "Feature request"],
                                                    p=[0.30, 0.30, 0.10, 0.18, 0.12]),
                                priority=pri, resolution_hours=hrs,
                                ticket_csat=int(np.clip(round(rng.normal(2.8 + 2 * fit - hrs / 80, 0.8)), 1, 5))))
            tid += 1
        # NPS survey every 6 months of tenure
        if k % 6 == 3:
            score = int(np.clip(round(rng.normal(3.9 + 7 * fit, 1.5)), 0, 10))
            if churn_month is not None and k >= n_hist - 4: score = max(0, score - 3)
            nps.append(dict(response_id=f"NPS-{rid:05d}", account_id=aid,
                            survey_date=(m + pd.Timedelta(days=int(rng.integers(0, 25)))).date(),
                            nps_score=score))
            rid += 1

    if churn_month is not None:
        monthly.append(dict(account_id=aid, month=churn_month.date(), seats=0, mrr=0))
        status = "Churned"; churn_date = (churn_month + pd.Timedelta(days=int(rng.integers(0, 27)))).date()
    else:
        status = "Active"; churn_date = None

    first_contract = pd.Timestamp(signup.year, signup.month, 1)
    years = max(1, (AS_OF.year - first_contract.year) + 1)
    renewal = first_contract + pd.DateOffset(years=years)
    if renewal <= AS_OF: renewal += pd.DateOffset(years=1)

    accounts.append(dict(account_id=aid, company_name=name, industry=rng.choice(industries),
                         region=rng.choice(regions, p=region_p), segment=seg, plan=plan,
                         csm_owner=rng.choice(csms), acquisition_channel=rng.choice(acq_channels),
                         signup_date=signup.date(), renewal_date=None if status == "Churned" else renewal.date(),
                         status=status, churn_date=churn_date, churn_reason=churn_reason,
                         price_per_seat=price, contracted_seats_at_start=seats))

pd.DataFrame(accounts).to_csv(f"{OUT}/accounts.csv", index=False)
pd.DataFrame(monthly).to_csv(f"{OUT}/monthly_revenue.csv", index=False)
pd.DataFrame(usage).to_csv(f"{OUT}/product_usage.csv", index=False)
pd.DataFrame(nps).to_csv(f"{OUT}/nps_responses.csv", index=False)
pd.DataFrame(onboarding).to_csv(f"{OUT}/onboarding.csv", index=False)
pd.DataFrame(tickets).to_csv(f"{OUT}/support_tickets.csv", index=False)
for f in os.listdir(OUT):
    print(f, len(pd.read_csv(f"{OUT}/{f}")))
