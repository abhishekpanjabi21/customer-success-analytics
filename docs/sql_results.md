# SQL results

Output of every query in `sql/customer_success_analysis.sql` and `sql/backtest_health_score.sql`, run on the CSVs in `data/` with SQLite. Long results show the first 15 rows.

## dq_row_counts

6 rows

| table_name      |   row_count |
|:----------------|------------:|
| accounts        |        2600 |
| monthly_revenue |       46476 |
| product_usage   |       45997 |
| nps_responses   |        7297 |
| onboarding      |        2600 |
| support_tickets |       31107 |

## dq_duplicates_and_orphans

1 rows

|   duplicate_accounts |   orphan_revenue_rows |   churned_missing_date |
|---------------------:|----------------------:|-----------------------:|
|                    0 |                     0 |                      0 |

## kpi_mrr_arr_trend

33 rows

| month      |   total_mrr |   total_arr |   paying_customers |
|:-----------|------------:|------------:|-------------------:|
| 2024-01-01 |     1149201 |    13790412 |                476 |
| 2024-02-01 |     1283681 |    15404172 |                536 |
| 2024-03-01 |     1473385 |    17680620 |                603 |
| 2024-04-01 |     1663172 |    19958064 |                672 |
| 2024-05-01 |     1884399 |    22612788 |                734 |
| 2024-06-01 |     2081709 |    24980508 |                791 |
| 2024-07-01 |     2272819 |    27273828 |                857 |
| 2024-08-01 |     2449938 |    29399256 |                909 |
| 2024-09-01 |     2591221 |    31094652 |                979 |
| 2024-10-01 |     2793700 |    33524400 |               1025 |
| 2024-11-01 |     2979314 |    35751768 |               1095 |
| 2024-12-01 |     3140350 |    37684200 |               1140 |
| 2025-01-01 |     3319851 |    39838212 |               1207 |
| 2025-02-01 |     3476236 |    41714832 |               1256 |
| 2025-03-01 |     3591138 |    43093656 |               1317 |

## kpi_mrr_movements

32 rows

| month      |   new_mrr |   expansion_mrr |   contraction_mrr |   churned_mrr |
|:-----------|----------:|----------------:|------------------:|--------------:|
| 2024-02-01 |    134480 |               0 |                 0 |             0 |
| 2024-03-01 |    183727 |           10627 |               550 |          4100 |
| 2024-04-01 |    198114 |           10714 |              1684 |         17357 |
| 2024-05-01 |    241615 |            8260 |              6289 |         22359 |
| 2024-06-01 |    200309 |            7128 |               625 |          9502 |
| 2024-07-01 |    212045 |           10429 |               224 |         31140 |
| 2024-08-01 |    207264 |            6220 |               375 |         35990 |
| 2024-09-01 |    162778 |            7024 |               802 |         27717 |
| 2024-10-01 |    224718 |            3006 |              2356 |         22889 |
| 2024-11-01 |    223020 |           16716 |              3814 |         50308 |
| 2024-12-01 |    171822 |            8329 |              2400 |         16715 |
| 2025-01-01 |    181053 |           16704 |              1631 |         16625 |
| 2025-02-01 |    166435 |           19521 |              3576 |         25995 |
| 2025-03-01 |    130508 |           13899 |              1195 |         28310 |
| 2025-04-01 |    202017 |           18918 |               971 |         75374 |

## kpi_monthly_logo_churn

32 rows

| month      |   customers_start |   customers_churned |   logo_churn_rate_pct |
|:-----------|------------------:|--------------------:|----------------------:|
| 2024-02-01 |               476 |                   0 |                  0    |
| 2024-03-01 |               536 |                   3 |                  0.56 |
| 2024-04-01 |               603 |                   6 |                  1    |
| 2024-05-01 |               672 |                   8 |                  1.19 |
| 2024-06-01 |               734 |                   9 |                  1.23 |
| 2024-07-01 |               791 |                   9 |                  1.14 |
| 2024-08-01 |               857 |                  11 |                  1.28 |
| 2024-09-01 |               909 |                   9 |                  0.99 |
| 2024-10-01 |               979 |                  17 |                  1.74 |
| 2024-11-01 |              1025 |                  10 |                  0.98 |
| 2024-12-01 |              1095 |                  10 |                  0.91 |
| 2025-01-01 |              1140 |                   9 |                  0.79 |
| 2025-02-01 |              1207 |                  14 |                  1.16 |
| 2025-03-01 |              1256 |                  13 |                  1.04 |
| 2025-04-01 |              1317 |                  18 |                  1.37 |

## kpi_nrr_grr_ttm

1 rows

|   cohort_customers |   cohort_start_mrr |   cohort_end_mrr |   nrr_pct |   grr_pct |   logo_retention_pct |
|-------------------:|-------------------:|-----------------:|----------:|----------:|---------------------:|
|               1620 |        4.53847e+06 |      4.18859e+06 |      92.3 |      87.8 |                 87.8 |

## churn_by_segment

3 rows

| segment    |   customers |   churned |   churn_pct |
|:-----------|------------:|----------:|------------:|
| Mid-Market |         759 |       168 |        22.1 |
| SMB        |        1587 |       282 |        17.8 |
| Enterprise |         254 |        29 |        11.4 |

## churn_reasons

6 rows

| churn_reason               |   churned_customers |   pct_of_churn |
|:---------------------------|--------------------:|---------------:|
| Low adoption               |                 156 |           32.6 |
| Budget cuts                |                  98 |           20.5 |
| Switched to competitor     |                  86 |           18   |
| Missing features           |                  66 |           13.8 |
| Poor onboarding experience |                  42 |            8.8 |
| Company acquired / closed  |                  31 |            6.5 |

## churn_by_onboarding

3 rows

| onboarding_status   |   customers |   churn_pct |
|:--------------------|------------:|------------:|
| Completed Late      |         232 |        34.5 |
| Completed On Time   |        2338 |        17.1 |
| In Progress         |          30 |         0   |

## kpi_nps_by_segment

3 rows

| segment    |   responses |   promoters_pct |   detractors_pct |   nps |
|:-----------|------------:|----------------:|-----------------:|------:|
| Enterprise |         423 |            46.1 |             18.2 |    28 |
| Mid-Market |        1149 |            43   |             19.7 |    23 |
| SMB        |        2443 |            47.2 |             18.7 |    29 |

## engagement_trend

33 rows

| month      |   seat_utilisation_pct |   avg_features_adopted |
|:-----------|-----------------------:|-----------------------:|
| 2024-01-01 |                   70.7 |                    8.5 |
| 2024-02-01 |                   71.9 |                    8.5 |
| 2024-03-01 |                   70.9 |                    8.5 |
| 2024-04-01 |                   70.8 |                    8.5 |
| 2024-05-01 |                   71.1 |                    8.5 |
| 2024-06-01 |                   71   |                    8.4 |
| 2024-07-01 |                   71   |                    8.5 |
| 2024-08-01 |                   71.5 |                    8.5 |
| 2024-09-01 |                   71.3 |                    8.6 |
| 2024-10-01 |                   71.3 |                    8.5 |
| 2024-11-01 |                   72.2 |                    8.6 |
| 2024-12-01 |                   71.3 |                    8.6 |
| 2025-01-01 |                   71.9 |                    8.6 |
| 2025-02-01 |                   71.2 |                    8.6 |
| 2025-03-01 |                   71.5 |                    8.7 |

## churn_warning_signal

2 rows

| status   |   utilisation_last_3_months_pct |
|:---------|--------------------------------:|
| Active   |                            73.5 |
| Churned  |                            32.9 |

## onboarding_by_segment

3 rows

| segment    |   customers |   avg_days_to_go_live |   target_days |   on_time_pct |   avg_onboarding_csat |
|:-----------|------------:|----------------------:|--------------:|--------------:|----------------------:|
| Enterprise |         254 |                  58.3 |            75 |          77.9 |                  4.05 |
| Mid-Market |         759 |                  33.4 |            45 |          85   |                  4    |
| SMB        |        1587 |                  13   |            21 |          95.8 |                  4.04 |

## health_distribution

3 rows

| risk_tier       |   customers |      arr |   avg_health |
|:----------------|------------:|---------:|-------------:|
| Healthy         |        1102 | 33945924 |           87 |
| Needs Attention |         901 | 35912496 |           73 |
| High Risk       |         118 |  5736864 |           60 |

## renewals_at_risk

171 rows

| account_id   | company_name             | segment    | csm_owner     | renewal_date   |    arr |   health_score | risk_tier       |   utilisation |   latest_nps |
|:-------------|:-------------------------|:-----------|:--------------|:---------------|-------:|---------------:|:----------------|--------------:|-------------:|
| ACC-12426    | Primeflow Co             | Enterprise | Sofia Alvarez | 2027-02-01     | 393120 |             63 | High Risk       |         0.555 |            7 |
| ACC-10918    | Urbanpoint Group         | Enterprise | Neha Iyer     | 2027-02-01     | 325080 |             67 | Needs Attention |         0.538 |            7 |
| ACC-11371    | Urbanflow Co             | Enterprise | Emily Chen    | 2027-02-01     | 319680 |             66 | Needs Attention |         0.621 |            7 |
| ACC-10295    | Urbanwave Group          | Enterprise | Daniel Brooks | 2027-01-01     | 302400 |             70 | Needs Attention |         0.594 |            6 |
| ACC-10864    | Vertexworks Group        | Enterprise | Priya Sharma  | 2027-01-01     | 294300 |             74 | Needs Attention |         0.754 |            6 |
| ACC-11584    | Greenflow LLC            | Enterprise | Rahul Mehta   | 2027-01-01     | 277020 |             79 | Needs Attention |         0.814 |            8 |
| ACC-11680    | Peakflow Solutions       | Enterprise | Rahul Mehta   | 2027-02-01     | 275940 |             79 | Needs Attention |         0.761 |            9 |
| ACC-11412    | Vertexly Systems         | Enterprise | Daniel Brooks | 2027-01-01     | 271620 |             70 | Needs Attention |         0.618 |            9 |
| ACC-11366    | Atlaspath Co             | Enterprise | Rahul Mehta   | 2027-02-01     | 255420 |             76 | Needs Attention |         0.787 |            7 |
| ACC-10885    | Peakpoint Technologies   | Enterprise | James Carter  | 2027-01-01     | 237600 |             71 | Needs Attention |         0.615 |            8 |
| ACC-12000    | Corenest Systems         | Enterprise | Daniel Brooks | 2027-01-01     | 207900 |             67 | Needs Attention |         0.54  |            9 |
| ACC-12061    | Novastack LLC            | Enterprise | James Carter  | 2027-01-01     | 207360 |             79 | Needs Attention |         0.717 |           10 |
| ACC-12398    | Urbansphere Technologies | Enterprise | Sofia Alvarez | 2027-01-01     | 203040 |             73 | Needs Attention |         0.707 |            7 |
| ACC-12359    | Cleargrid LLC            | Enterprise | Lucas Martin  | 2027-01-01     | 200700 |             78 | Needs Attention |         0.776 |            8 |
| ACC-10356    | Vertexscale Solutions    | Enterprise | James Carter  | 2027-01-01     | 192240 |             72 | Needs Attention |         0.671 |            7 |

## expansion_opportunities

344 rows

| account_id   | company_name         | segment    | plan       | csm_owner     |   health_score |   utilisation |   avg_features |   mrr_now | opportunity_type   |   potential_added_mrr |
|:-------------|:---------------------|:-----------|:-----------|:--------------|---------------:|--------------:|---------------:|----------:|:-------------------|----------------------:|
| ACC-11924    | Brightflow Ltd       | Enterprise | Growth     | Daniel Brooks |             84 |         0.874 |           11.7 |     14325 | Plan upgrade       |                 11460 |
| ACC-10414    | Coreline Group       | Enterprise | Growth     | Rahul Mehta   |             84 |         0.737 |           11   |     13425 | Plan upgrade       |                 10740 |
| ACC-12399    | Atlaslogic Solutions | Enterprise | Growth     | Sofia Alvarez |             88 |         0.84  |           10.7 |     12375 | Plan upgrade       |                  9900 |
| ACC-12231    | Silverscale Co       | Enterprise | Growth     | Lucas Martin  |             91 |         0.812 |           11   |     10975 | Plan upgrade       |                  8780 |
| ACC-10827    | Pixelforge Group     | Enterprise | Growth     | Rahul Mehta   |             89 |         0.819 |           10.7 |      9250 | Plan upgrade       |                  7400 |
| ACC-12291    | Clearbridge Inc      | Mid-Market | Growth     | Rahul Mehta   |             91 |         0.881 |           11   |      8750 | Plan upgrade       |                  7000 |
| ACC-11164    | Novahub Technologies | Enterprise | Growth     | Priya Sharma  |             81 |         0.76  |           10.7 |      7975 | Plan upgrade       |                  6380 |
| ACC-12162    | Greenscale Group     | Mid-Market | Growth     | Sofia Alvarez |            100 |         0.898 |           12   |      7825 | Plan upgrade       |                  6260 |
| ACC-10793    | Swiftscale Inc       | Mid-Market | Growth     | Neha Iyer     |             99 |         0.869 |           11   |      6575 | Plan upgrade       |                  5260 |
| ACC-11359    | Orbitly Ltd          | Mid-Market | Growth     | Aisha Khan    |             93 |         0.863 |           10.7 |      6125 | Plan upgrade       |                  4900 |
| ACC-11958    | Vertexmind Solutions | Enterprise | Enterprise | James Carter  |             96 |         0.941 |           11.3 |     24345 | Seat expansion     |                  4869 |
| ACC-11530    | Truepoint Solutions  | Mid-Market | Growth     | Rahul Mehta   |             93 |         0.88  |           11.3 |      5950 | Plan upgrade       |                  4760 |
| ACC-10828    | Primeworks Ltd       | Mid-Market | Growth     | Rahul Mehta   |             93 |         0.862 |           12   |      5375 | Plan upgrade       |                  4300 |
| ACC-12278    | Brightwave Inc       | Mid-Market | Growth     | Sofia Alvarez |             86 |         0.837 |           11.3 |      5250 | Plan upgrade       |                  4200 |
| ACC-11839    | Greenpoint Systems   | Enterprise | Enterprise | James Carter  |             94 |         0.946 |           10.7 |     20475 | Seat expansion     |                  4095 |

## csm_portfolio

10 rows

| csm_owner     |   accounts |   arr_managed |   avg_health |   high_risk_accounts |
|:--------------|-----------:|--------------:|-------------:|---------------------:|
| Lucas Martin  |        227 |       9308088 |           79 |                    8 |
| Rahul Mehta   |        230 |       9049908 |           79 |                   21 |
| Sofia Alvarez |        229 |       8078940 |           80 |                   13 |
| James Carter  |        197 |       7812228 |           80 |                    9 |
| Aisha Khan    |        206 |       7709376 |           78 |                   15 |
| Neha Iyer     |        199 |       7603968 |           79 |                    9 |
| Daniel Brooks |        198 |       7571604 |           79 |                   10 |
| Emily Chen    |        214 |       7063332 |           79 |                   19 |
| Priya Sharma  |        224 |       6760248 |           80 |                    9 |
| Marco Rossi   |        197 |       4637592 |           81 |                    5 |

## backtest_health_score

3 rows

| risk_tier_sep_2025   |   customers |   churned_next_12m |   churn_pct |
|:---------------------|------------:|-------------------:|------------:|
| High Risk            |          89 |                 38 |        42.7 |
| Needs Attention      |         683 |                 95 |        13.9 |
| Healthy              |         848 |                 53 |         6.3 |
