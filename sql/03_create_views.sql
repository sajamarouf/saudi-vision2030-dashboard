/* =====================================================================
   03 — Views that Power BI reads (the "semantic" layer)
   ---------------------------------------------------------------------
   dw.vw_FactKPI   : unpivots every wide staging table into ONE long fact
                     (QuarterKey × IndicatorKey → Value) so that a single
                     set of DAX measures works for all 12 indicators.
   dw.vw_GDPLevels : adds non-oil / oil share of real GDP.
   ===================================================================== */
USE Vision2030;
GO

CREATE OR ALTER VIEW dw.vw_FactKPI
AS
/* 1) Labour force participation */
SELECT  p.QuarterKey,
        v.IndicatorKey,
        v.Value,
        SeriesVintage = CAST('census2022_revised' AS VARCHAR(30)),
        EstimateType  = CAST('final' AS VARCHAR(10)),
        p.SourceID,
        Note          = CAST(N'' AS NVARCHAR(200))
FROM    stg.LabourParticipation AS p
CROSS APPLY (VALUES ('LFPR_SA_M', p.SaudiMale),
                    ('LFPR_SA_F', p.SaudiFemale),
                    ('LFPR_SA_T', p.SaudiTotal)) AS v (IndicatorKey, Value)
WHERE   v.Value IS NOT NULL

UNION ALL
/* 2) Unemployment — the series note only belongs to the headline Saudi rate */
SELECT  u.QuarterKey,
        v.IndicatorKey,
        v.Value,
        u.SeriesVintage,
        'final',
        u.SourceID,
        CASE WHEN v.IndicatorKey = 'UR_SA_T' THEN ISNULL(u.Note, N'') ELSE N'' END
FROM    stg.LabourUnemployment AS u
CROSS APPLY (VALUES ('UR_SA_T',  u.SaudiTotal),
                    ('UR_SA_M',  u.SaudiMale),
                    ('UR_SA_F',  u.SaudiFemale),
                    ('UR_KSA_T', u.KingdomTotal)) AS v (IndicatorKey, Value)
WHERE   v.Value IS NOT NULL

UNION ALL
/* 3) Female employment-to-population ratio */
SELECT  e.QuarterKey,
        'EPR_SA_F',
        e.SaudiFemaleEmpToPop,
        'census2022_revised',
        'final',
        e.SourceID,
        N''
FROM    stg.LabourFemaleEmpPop AS e

UNION ALL
/* 4) GDP growth by activity */
SELECT  g.QuarterKey,
        v.IndicatorKey,
        v.Value,
        'rebased_2023',
        g.EstimateType,
        g.SourceID,
        ISNULL(g.Note, N'')
FROM    stg.GDPGrowthQuarterly AS g
CROSS APPLY (VALUES ('GDP_YOY_T',      g.TotalGDP),
                    ('GDP_YOY_OIL',    g.Oil),
                    ('GDP_YOY_NONOIL', g.NonOil),
                    ('GDP_YOY_GOV',    g.Government)) AS v (IndicatorKey, Value)
WHERE   v.Value IS NOT NULL;
GO

CREATE OR ALTER VIEW dw.vw_GDPLevels
AS
SELECT  QuarterKey,
        OilSARbn, NonOilSARbn, GovSARbn, NetTaxSARbn, GDPSARbn,
        NonOilSharePct = CAST(ROUND(100.0 * NonOilSARbn / GDPSARbn, 2) AS DECIMAL(5,2)),
        OilSharePct    = CAST(ROUND(100.0 * OilSARbn    / GDPSARbn, 2) AS DECIMAL(5,2)),
        SourceID
FROM    stg.GDPLevels;
GO

/* Accounting identity for Saudi women:
   unemployment = (participation − employment ratio) / participation.
   If the published three series are consistent, GapPP stays within rounding. */
CREATE OR ALTER VIEW dw.vw_QA_FemaleIdentity
AS
SELECT  p.QuarterKey,
        LFPR        = p.SaudiFemale,
        EPR         = e.SaudiFemaleEmpToPop,
        UR_Published = u.SaudiFemale,
        UR_Implied  = CAST(ROUND(100.0 * (p.SaudiFemale - e.SaudiFemaleEmpToPop) / p.SaudiFemale, 2) AS DECIMAL(5,2)),
        GapPP       = CAST(ROUND(100.0 * (p.SaudiFemale - e.SaudiFemaleEmpToPop) / p.SaudiFemale
                                 - u.SaudiFemale, 2) AS DECIMAL(5,2))
FROM    stg.LabourParticipation AS p
JOIN    stg.LabourFemaleEmpPop  AS e ON e.QuarterKey = p.QuarterKey
JOIN    stg.LabourUnemployment  AS u ON u.QuarterKey = p.QuarterKey
WHERE   u.SaudiFemale IS NOT NULL;
GO
