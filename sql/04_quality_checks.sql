/* =====================================================================
   04 — Data-quality checks
   Every query should return ZERO rows, except the last summary.
   Any row returned = a problem to fix before refreshing Power BI.
   ===================================================================== */
USE Vision2030;
GO

/* 1. Duplicate quarter × indicator */
SELECT  'duplicate' AS Issue, QuarterKey, IndicatorKey, COUNT(*) AS n
FROM    dw.vw_FactKPI
GROUP BY QuarterKey, IndicatorKey
HAVING  COUNT(*) > 1;

/* 2. Quarter key not in the yyyyQn format */
SELECT  'bad quarter key' AS Issue, QuarterKey, IndicatorKey
FROM    dw.vw_FactKPI
WHERE   QuarterKey NOT LIKE '[12][0-9][0-9][0-9]Q[1-4]';

/* 3. Labour rates must be 0–100; GDP growth must be within ±40 */
SELECT  'out of range' AS Issue, QuarterKey, IndicatorKey, Value
FROM    dw.vw_FactKPI
WHERE  (IndicatorKey NOT LIKE 'GDP%' AND (Value < 0 OR Value > 100))
   OR  (IndicatorKey LIKE 'GDP%'     AND ABS(Value) > 40);

/* 4. Indicator used in the fact but not described in DimIndicator */
SELECT  DISTINCT 'unknown indicator' AS Issue, f.IndicatorKey
FROM    dw.vw_FactKPI AS f
LEFT JOIN dw.DimIndicator AS d ON d.IndicatorKey = f.IndicatorKey
WHERE   d.IndicatorKey IS NULL;

/* 5. Every SourceID (some rows cite two, separated by ';') must exist */
SELECT  DISTINCT 'unknown source' AS Issue, LTRIM(RTRIM(s.value)) AS SourceID
FROM    dw.vw_FactKPI AS f
CROSS APPLY STRING_SPLIT(f.SourceID, ';') AS s
LEFT JOIN dw.DimSource AS d ON d.SourceID = LTRIM(RTRIM(s.value))
WHERE   d.SourceID IS NULL;

/* 6. Female identity check: implied vs published unemployment (rounding ≤ 0.35 pp) */
SELECT  'identity gap' AS Issue, *
FROM    dw.vw_QA_FemaleIdentity
WHERE   ABS(GapPP) > 0.35;

/* 7. Summary — this one SHOULD return rows: what is in the fact table */
SELECT  f.IndicatorKey,
        d.IndicatorName,
        n_quarters   = COUNT(*),
        first_q      = MIN(f.QuarterKey),
        last_q       = MAX(f.QuarterKey),
        latest_value = MAX(CASE WHEN f.QuarterKey = x.last_q THEN f.Value END)
FROM    dw.vw_FactKPI AS f
JOIN    dw.DimIndicator AS d ON d.IndicatorKey = f.IndicatorKey
CROSS APPLY (SELECT MAX(QuarterKey) AS last_q
             FROM dw.vw_FactKPI WHERE IndicatorKey = f.IndicatorKey) AS x
GROUP BY f.IndicatorKey, d.IndicatorName
ORDER BY d.IndicatorName;
GO
