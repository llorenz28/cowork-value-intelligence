# Cowork Intelligence Templates: interpretation guide

This guide applies to the active testing templates:

- **Cowork Adoption Intelligence v2 Testing** (`2.0.1-testing`): nine
  viewer-facing pages focused on adoption, sustained use, delegation maturity,
  potential champions, and action patterns.
- **Cowork Value V1 Testing** (`1.1.0-testing`): 11 viewer-facing pages plus one
  hidden assumptions page focused on modeled value, consumption, chargeback,
  five billing scenarios, and right-sizing.

The legacy 13-page combined-source report under `src` is not covered here.

> The repository sample is fabricated. Its results, `$75/hour` screenshot
> assumption, and QA-only contract inputs are demonstrations, not customer
> findings, benchmarks, or recommendations.

## Choose the correct template

| Business question | Primary template | Start with |
| --- | --- | --- |
| Are people returning to Cowork and using it more deeply? | Adoption | Executive Summary, then Weekly Adoption & Usage |
| Which users show repeatable enablement patterns? | Adoption | Cowork Champions |
| What work and skills are being delegated? | Adoption | Actions by Category, then Usage Explorer |
| How much modeled time or value could the observed work represent? | Value | Task Categories & Methodology, then Methodology & Value Calculator |
| How do modeled value and customer-priced consumption compare? | Value | Value vs Cost |
| Which users or departments are near or over allowance? | Value | Right-Sizing & Reclaim, then Value by Department |
| What does the Microsoft-compatible per-user overage logic show? | Value | Value vs Cost and the [chargeback section](#microsoft-chargeback-foundation) below |

## Read every result in this order

1. Confirm the reporting period and all active filters.
2. Check whether each required source is available and matched.
3. Identify the metric grain: audit event, task thread, skill invocation, user,
   or consumption record.
4. Identify the evidence label: observed, derived, modeled, allocated estimate,
   or unavailable.
5. Corroborate unusual activity in the originating system before acting.
6. Protect user, resource, organization, and consumption data in every export.

## Evidence labels

| Label | Meaning | Safe wording |
| --- | --- | --- |
| Observed | Directly counted from a connected source field | "The connected export contains..." |
| Derived | Arithmetic over observed fields | "The report calculates..." |
| Modeled | Observed activity combined with an assumption or customer input | "Under the selected assumptions..." |
| Allocated estimate | A total distributed across dimensions without source metering at that grain | "The modeled allocation suggests..." |
| Unavailable | A required source or input is absent | "This cannot be calculated from the current inputs." |

Blank or unavailable is not zero.

## Shared metric and grain rules

| Concept | How the templates treat it |
| --- | --- |
| Audit event | One Purview record. Multiple events can belong to one task thread. |
| Cowork task | One distinct task thread. Repeated events in the same thread do not create additional tasks. |
| Distinct skills per task | Distinct plugin names in a thread. Repeated calls to the same plugin count once for skill-chaining depth. |
| Skill invocation | An observed plugin event. Invocation totals can be higher than distinct skills or tasks. |
| Reported task | A task total from the optional Cowork usage export. Use it to reconcile with Purview threads, not replace them. |
| User | A normalized, case-insensitive, trimmed user principal name used to join activity, usage, consumption, and optional organization data. |
| Credit | Observed only when a compatible Cost Management **Consumption > Users** export is loaded and matched. |
| Model or LLM | Observed only when Purview emits `ModelTransparencyDetails`; otherwise model-specific results remain unavailable. |

Do not compare totals at different grains as if they should be identical. When
Purview task threads and the admin-center reported task count differ, investigate
date coverage, export freshness, retention, identity matching, and product
definitions before drawing a conclusion.

## Adoption template page guide

The core Adoption experience does not require consumption data. Optional
modeled-value and cost fields remain unavailable until their required customer
inputs are connected.

### 1. Start Here

**Question:** Which page answers the decision in front of me?

**Read first:** Choose a route based on the business question, not the most
favorable metric.

**Do not conclude:** That every route has the same source requirements.

**Next check:** Open the recommended page and review its data-status notes before
quoting a result.

### 2. Executive Summary

**Question:** How broad, consistent, and deep is current Cowork adoption?

**Read first:** Reach and task volume, then return behavior, intensity, action
mix, and the adoption momentum direction.

**Interpret carefully:** The momentum score combines multiple adoption signals.
Use its direction across several periods; do not treat one score as a universal
benchmark.

**Next check:** Move to Weekly Adoption & Usage to confirm whether the headline
reflects a sustained pattern or a short-lived spike.

### 3. Weekly Adoption & Usage

**Question:** Are users starting, returning, and deepening use over time?

**Read first:** Weekly active users and tasks, then new, retained, resurrected,
and churned users. Use the view selector to compare reach, prompts per active
user, active days, return rate, and momentum.

**Interpret carefully:** The latest week can be partial. A high-intensity week
with low reach is different from broad adoption with moderate intensity.
Department views require matching organization data.

**Next check:** Compare several complete weeks and explain any changes in export
coverage, filters, rollout phases, or seasonality.

### 4. User Maturity

**Question:** How far are users progressing from trial behavior toward repeatable
delegation?

**Read first:** The rule-based delegation ladder:

| Rung | Current rule |
| --- | --- |
| 0 - Not started | No observed Cowork task threads |
| 1 - Trying | Has tasks but does not meet a higher rung |
| 2 - Using | At least three average distinct skills per user |
| 3 - Delegating | At least 30% of task threads use multiple distinct skills |
| 4 - Automating | At least one reported scheduled task |

**Interpret carefully:** These are behavior stages created by the report, not
product certifications or measures of employee ability. Rung 4 depends on the
optional Cowork usage export; without it, scheduled work cannot be identified.

**Next check:** Inspect the underlying task, skill, and scheduled-use evidence
before recommending coaching or workflow expansion.

### 5. Cowork Champions

**Question:** Which users have enough sustained, category-specific evidence to
consider for enablement outreach?

**Read first:** A user is eligible only with at least three tasks across at least
two active weeks in the selected category and filter context. The evidence score
is:

- 40% category activity percentile
- 35% active-week consistency percentile
- 25% delegation-stage score

The Top 5%, Top 10%, or Top 20% selector admits that share of eligible users,
rounded up to at least one candidate.

**Interpret carefully:** A candidate is a relative engagement signal, not an
employee-performance rating or automatic nomination. Small cohorts make
percentile ranks unstable. Missing organization data prevents department
coverage analysis.

**Next check:** Confirm role fit, willingness, manager support, and a repeatable
workflow before inviting a candidate to a champion program.

### 6. Actions by Category

**Question:** What types of work are represented in observed Cowork task threads?

**Read first:** Category task counts and shares, then the category mapping and
any unmapped activity.

**Interpret carefully:** Categories are deterministic classifications of
available task signals. They describe the report's mapping, not the business
outcome, quality, or intent of the work.

**Next check:** Review material unmapped activity and sample source records
before changing the category mapping.

### 7. Activity & Value

**Question:** Which skills and categories drive activity, modeled hours, and
optional modeled value?

**Read first:** Skill invocations are observed. Assisted hours apply the selected
cited time-saved basis to observed category tasks. Dollar value multiplies those
hours by the selected loaded labor rate.

**Interpret carefully:** Hours and dollars are modeled, not stopwatch-measured
savings. Value by department requires matching organization data. Cost and ROI
require compatible consumption data and customer-approved billing inputs.

**Next check:** Test low, mid, and high time assumptions and a Finance-approved
labor rate before presenting modeled value.

### 8. Usage Explorer

**Question:** Which skills and users explain the aggregate patterns?

**Read first:** In Action Explorer, use observed invocations, users, mapping
status, and parent category. In User Detail, use task count, duration, distinct
skills, recency, and any available reported usage or consumption.

**Interpret carefully:** Skill-sliced assisted hours and value repeat the parent
category total across skills in that category because the source does not meter
task value per skill. Do not sum those repeated skill rows.

**Next check:** Use this page to investigate aggregate findings, not to create an
employee ranking or automatic action list.

### 9. Adoption Metric Guide

**Question:** What does a metric mean and what source supports it?

**Read first:** Definition, evidence type, source requirement, and known
limitation.

**Interpret carefully:** "Unavailable" means a dependency is absent. It does not
mean no activity occurred.

**Next check:** Include the metric definition, reporting period, filters, and
evidence label whenever a result leaves the report.

## Value template page guide

### 1. Start Here

**Question:** Which value, cost, or right-sizing page should I use?

**Read first:** Choose the route that matches the decision and confirm that its
required sources and customer inputs are available.

**Do not conclude:** That modeled value, observed credits, chargeback, and
allocated cost are interchangeable.

**Next check:** Use the Glossary and this guide before presenting the result.

### 2. Executive Summary

**Question:** What is the overall relationship between observed work, modeled
value, and customer-priced platform cost?

**Read first:** Task threads and active users, then modeled hours and value, then
consumption and billing-aware cost.

**Interpret carefully:** A favorable ROI is conditional on the selected time,
labor, billing, and price assumptions. It does not establish causality or realized
cash savings.

**Next check:** Reconcile task totals and confirm every selected customer input
with its owner.

### 3. Task Categories & Methodology

**Question:** Which work categories generate the modeled hours and value?

**Read first:** Observed task volume by category, mapping coverage, and the
selected low, mid, or high minutes-saved benchmark.

**Interpret carefully:** A category benchmark is an assumption applied to each
task in that category. It is not measured duration or proof that the full amount
was saved.

**Next check:** Review the research source and the hidden Action Assumptions page
before changing any of the 44 minute benchmarks.

### 4. Methodology & Value Calculator

**Question:** How sensitive is modeled value to the selected assumptions?

**Current calculation:**

```text
Assisted hours =
  sum(category task threads x selected category minutes saved) / 60

Estimated value =
  assisted hours x loaded labor rate
```

Additional reinvestment, quality, and skill adjustments are customer-controlled
scenarios. Billing inputs on this page stay synchronized with Value vs Cost.

**Interpret carefully:** Low, mid, and high results are assumption scenarios,
not statistical confidence intervals.

**Next check:** Record the estimate basis, labor rate, adjustments, billing mode,
and price inputs with every exported value result.

### 5. Value vs Cost

**Question:** Under the selected scenario, how does modeled value compare with
platform cost?

**Read first:** Confirm the billing mode and its required inputs. Then read
adjusted modeled value, effective platform cost, net value, and billing-aware ROI.

**Interpret carefully:** Department cost is allocated in proportion to observed
department credits. It is not invoice metering. The scatter shows scenario
positioning, not causal productivity.

**Next check:** Use the [billing-mode table](#five-billing-modes) and verify
Finance-approved inputs before sharing any cost or ROI result.

### 6. Value by Department

**Question:** How are observed tasks, credits, modeled value, and allocated cost
distributed across departments?

**Read first:** Confirm organization-match coverage, then compare task volume,
modeled value, observed credits, and allocated cost separately.

**Interpret carefully:** Department attributes come from the optional
organization export. Unmatched users can make department comparisons incomplete.
Allocated cost follows credit share and is not a ledger charge.

**Next check:** Reconcile department ownership and identity coverage with the
authorized organization-data owner.

### 7. Value by User Tier

**Question:** How concentrated are task activity and modeled value across users?

**Read first:** Tier population, task share, modeled value share, and the
underlying user context.

**Interpret carefully:** The percentile split requires at least 20 active users.
Tiers are relative to the filtered population and are not performance ratings.

**Next check:** Pair a tier with role, department, seasonality, and work-category
context before recommending enablement.

### 8. Right-Sizing & Reclaim

**Question:** Which users are near allowance, over allowance, inactive, or
under-utilizing allocated credits?

**Read first:** Observed credits and allowance, activity recency, and budget
segment. Treat the current filter period and snapshot date as part of the result.

**Interpret carefully:** Near-limit begins at 85% of allowance. An over-limit or
low-use flag is a review prompt, not an automatic license or access decision.
Reclaimable license dollars remain unavailable without source-backed assignment
and customer seat-price data.

**Next check:** Confirm role, leave status, workload seasonality, license terms,
and manager context before changing access or allowance.

### 9. Skills & Allocated Consumption

**Question:** Which observed skills are associated with task volume and an
allocated share of credits or cost?

**Read first:** Observed invocation count and users, then mapping coverage.
Treat allocated credits and cost as estimates based on the documented allocation
rule.

**Interpret carefully:** The source does not meter credits or value per skill.
Repeated parent-category values must not be summed across skills.

**Next check:** Use observed skill volume for enablement planning; use allocated
consumption only as a directional planning view.

### 10. Model & LLM Breakdown

**Question:** Does the source provide model-attributed activity, and what
directional allocation follows from it?

**Read first:** Confirm whether model names are present in Purview. If the report
shows `(Model data not available)`, stop; do not infer a model.

**Interpret carefully:** Credits, cost, and efficiency by model are allocated
estimates based on task share. They are not model-specific billing meters and
cannot prove that one model is cheaper or more efficient.

**Next check:** Obtain source-backed per-model metering before making model
selection or cost recommendations.

### 11. Glossary

**Question:** What does each Value metric mean, and is it available?

**Read first:** Metric definition, evidence label, source dependency, and
limitation.

**Interpret carefully:** A modeled or allocated result must always travel with
its assumptions and allocation basis.

**Next check:** Copy the definition, period, filters, evidence label, and selected
inputs into any presentation or decision record.

### Hidden page: Action Assumptions

This internal page supports navigation and editing of category minute
assumptions. It is hidden from standard page tabs. Changes affect modeled hours,
value, net value, and ROI; document and approve them before using the results.

## Microsoft chargeback foundation

[![Microsoft CreditUsage chargeback dashboard preview](https://raw.githubusercontent.com/microsoft/CreditUsage/main/images/dashboard-preview.gif)](https://github.com/microsoft/CreditUsage/blob/main/images/dashboard-preview.gif)

*Official Microsoft `CreditUsage` reference dashboard preview. It is not a
screenshot of the extended Cowork Value report in this repository. Source:
[Microsoft `CreditUsage`](https://github.com/microsoft/CreditUsage) (MIT).*

The Value template follows the Microsoft `CreditUsage` per-user allowance and
overage rule:

```text
Over-limit credits =
  sum for each user(max(user credits used - user credit limit, 0))

Chargeback =
  over-limit credits x customer-selected rate per credit

Covered credits =
  total credits used - over-limit credits
```

Unused allowance from one user never offsets another user's overage. Calculate
the overage at user grain first, then sum it. A tenant-level subtraction of total
credits from total allowance is not equivalent and can hide chargeback.

`Chargeback $` prices only the per-user over-limit credits. It is different from
`Effective Platform Cost $`, which prices the selected whole-platform billing
scenario.

## Five billing modes

All price fields are **rates per credit**, not rates per 1,000 credits.

| Billing mode | Required customer inputs | Current calculation | Safe interpretation |
| --- | --- | --- | --- |
| Credit-Priced | Observed credits and PAYG Rate per Credit | Credits used x PAYG rate | Period consumption priced at the selected per-credit rate |
| License-Included | None for incremental credit cost | Effective platform cost = $0 | Scenario with no incremental credit charge; modeled value remains available and ROI is intentionally blank |
| Prepaid | Prepaid Credits Purchased and Prepaid Rate per Credit | Purchased pool x prepaid rate | Full cost of the purchased pool; unused capacity is not prorated away |
| Hybrid | Prepaid Credits Purchased, Prepaid Rate per Credit, PAYG Rate per Credit, and observed credits | Prepaid pool cost + actual credits above the pool x PAYG rate | Current-period prepaid pool plus actual PAYG overage |
| Monthly Committed | Monthly Committed Credits, Prepaid Rate per Credit, PAYG Rate per Credit, and enough observed data for the month-end forecast | Commitment cost + projected month-end credits above commitment x PAYG rate | Forward-looking monthly commitment scenario; overage uses the straight-line month-end projection |

Missing required inputs return blank or an input-required message. Do not replace
missing contract data with an assumed price in a customer result.

## Keep these cost concepts separate

| Metric | Basis | It does not mean |
| --- | --- | --- |
| Chargeback $ | Sum of per-user over-limit credits x Rate per Credit | Total platform cost |
| Effective Platform Cost $ | Cost under the selected billing mode | Official invoice or ledger amount |
| Department allocated cost | Effective platform cost distributed by observed department credit share | Department-level metered billing |
| Skill/model allocated credits or cost | Total distributed by the documented task-share rule | Source-metered skill or model consumption |
| Net Value (Billing) $ | Adjusted modeled value minus effective platform cost | Realized cash savings |
| ROI (Billing) | Adjusted modeled value divided by effective platform cost | Audited financial return or causal impact |

## Before exporting or presenting a result

1. Name the template and page.
2. Record the reporting period, snapshot date, and active filters.
3. Confirm source availability, freshness, and identity-match coverage.
4. State the metric grain.
5. Include the evidence label.
6. Record the time-saved basis and loaded labor rate for modeled value.
7. Record every adjustment applied to modeled value.
8. Record the billing mode and every price, pool, or commitment input.
9. State the allocation basis for department, skill, or model estimates.
10. Have the appropriate data, Finance, and business owners review the result.

## Usage and compliance disclaimer

Coverage depends on licensing, audit settings, retention, product behavior,
permissions, export completeness, and identity matching. The templates can
contain false positives, false negatives, incomplete model attribution, and
estimates. They do not inspect prompt content, prove intent, establish causality,
replace official billing, or authorize personnel action.

Customers control collection, storage, sensitivity labels, access, retention,
publication, and lawful use of their data. The repository sample is fabricated
and sends no customer data to GitHub.
