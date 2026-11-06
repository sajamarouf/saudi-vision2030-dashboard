/* =====================================================================
   02 — Load the curated data (every row keeps its SourceID)
   Re-runnable: truncates then inserts.
   ===================================================================== */
USE Vision2030;
GO
SET NOCOUNT ON;
DELETE FROM dw.DimTarget;
DELETE FROM dw.DimIndicator;
TRUNCATE TABLE dw.DimSource;
TRUNCATE TABLE stg.LabourParticipation;
TRUNCATE TABLE stg.LabourUnemployment;
TRUNCATE TABLE stg.LabourFemaleEmpPop;
TRUNCATE TABLE stg.GDPGrowthQuarterly;
TRUNCATE TABLE stg.GDPGrowthAnnual;
TRUNCATE TABLE stg.GDPLevels;

-- Labour force participation rate, Saudis 15+ (GASTAT LFS, census-2022 revised)
INSERT INTO stg.LabourParticipation (QuarterKey, SaudiMale, SaudiFemale, SaudiTotal, SourceID) VALUES
    ('2021Q1', 64.8, 31.9, 48.3, 'GLMM_LFPR'),
    ('2021Q2', 65.0, 32.1, 48.5, 'GLMM_LFPR'),
    ('2021Q3', 65.1, 34.3, 49.6, 'GLMM_LFPR'),
    ('2021Q4', 65.6, 34.7, 50.1, 'GLMM_LFPR'),
    ('2022Q1', 65.1, 33.3, 49.1, 'GLMM_LFPR'),
    ('2022Q2', 66.5, 35.1, 50.8, 'GLMM_LFPR'),
    ('2022Q3', 66.3, 36.5, 51.4, 'GLMM_LFPR'),
    ('2022Q4', 67.3, 35.5, 51.5, 'GLMM_LFPR'),
    ('2023Q1', 67.1, 35.5, 51.4, 'GLMM_LFPR'),
    ('2023Q2', 66.3, 34.8, 50.7, 'GLMM_LFPR'),
    ('2023Q3', 65.7, 35.4, 50.8, 'GLMM_LFPR'),
    ('2023Q4', 65.4, 35.0, 50.4, 'GLMM_LFPR'),
    ('2024Q1', 66.4, 35.8, 51.4, 'GLMM_LFPR'),
    ('2024Q2', 66.3, 35.4, 50.8, 'GLMM_LFPR'),
    ('2024Q3', 66.9, 36.2, 51.5, 'GLMM_LFPR'),
    ('2024Q4', 66.2, 36.0, 51.1, 'GLMM_LFPR'),
    ('2025Q1', 66.4, 36.3, 51.3, 'GLMM_LFPR'),
    ('2025Q2', 64.0, 34.5, 49.2, 'GLMM_LFPR'),
    ('2025Q3', 64.3, 33.7, 49.0, 'GLMM_LFPR'),
    ('2025Q4', 64.7, 34.5, 49.5, 'GLMM_LFPR'),
    ('2026Q1', 64.2, 33.9, 49.0, 'GLMM_LFPR'),
    ('2026Q2', 63.9, 33.7, NULL, 'ENT_Q2_2026');

-- Unemployment rate (%)
INSERT INTO stg.LabourUnemployment (QuarterKey, SaudiTotal, SaudiMale, SaudiFemale, KingdomTotal, SeriesVintage, SourceID, Note) VALUES
    ('2017Q1', 12.7, NULL, NULL, 5.8, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2017Q2', 12.8, NULL, NULL, 6.0, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2017Q3', 12.8, NULL, NULL, 5.8, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2017Q4', 12.8, NULL, NULL, 6.0, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2018Q1', 12.9, NULL, NULL, 6.1, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2018Q2', 12.9, NULL, NULL, 6.0, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2018Q3', 12.8, NULL, NULL, 6.0, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2018Q4', 12.7, NULL, NULL, 6.0, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2019Q1', 12.5, NULL, NULL, 5.7, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2019Q2', 12.3, NULL, NULL, 5.6, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2019Q3', 12.0, NULL, NULL, 5.5, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2019Q4', 12.0, NULL, NULL, 5.7, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2020Q1', 11.8, NULL, NULL, 5.7, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2020Q2', 15.4, NULL, NULL, 9.0, 'pre_census2022', 'ARGAAM_UR', N'COVID-19 shock'),
    ('2020Q3', 14.9, NULL, NULL, 8.5, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2020Q4', 12.6, NULL, NULL, 7.4, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2021Q1', 11.7, 7.2, 21.2, 6.5, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2021Q2', 11.3, NULL, NULL, 6.6, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2021Q3', 11.3, NULL, NULL, 6.6, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2021Q4', 11.0, NULL, NULL, 6.9, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2022Q1', 10.1, 5.1, 20.2, 6.0, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2022Q2', 9.7, 4.7, NULL, 5.8, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2022Q3', 9.9, NULL, NULL, 5.8, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2022Q4', 8.0, NULL, NULL, 4.8, 'pre_census2022', 'ARGAAM_UR', NULL),
    ('2023Q1', 8.7, NULL, NULL, 4.3, 'census2022_revised', 'ARGAAM_UR', NULL),
    ('2023Q2', 8.5, NULL, NULL, 4.1, 'census2022_revised', 'ARGAAM_UR', NULL),
    ('2023Q3', 8.8, NULL, NULL, 4.2, 'census2022_revised', 'ARGAAM_UR', NULL),
    ('2023Q4', 7.8, 4.6, 13.9, 3.4, 'census2022_revised', 'ARGAAM_UR;GASTAT_LMS_Q1_2024', NULL),
    ('2024Q1', 7.6, 4.2, 14.2, 3.5, 'census2022_revised', 'ARGAAM_UR;GASTAT_LMS_Q1_2024', NULL),
    ('2024Q2', 7.1, 4.0, 12.8, 3.3, 'census2022_revised', 'ARGAAM_UR;GASTAT_LMS_Q2_2024', NULL),
    ('2024Q3', 7.8, 4.7, 13.6, 3.7, 'census2022_revised', 'ARGAAM_Q3_2024', NULL),
    ('2024Q4', 7.0, NULL, 11.9, 3.5, 'census2022_revised', 'IMF_A4_2025;GASTAT_LMS_Q1_2025', NULL),
    ('2025Q1', 6.3, NULL, 10.5, 2.8, 'census2022_revised', 'GASTAT_LMS_Q1_2025', NULL),
    ('2025Q2', 6.8, 4.3, 11.3, 3.2, 'census2022_revised', 'GASTAT_LMS_Q2_2025;ENT_Q2_2026', N'Derived: GASTAT says Q2-2026 (6.5%) is 0.3 pp below Q2-2025'),
    ('2025Q3', 7.5, NULL, 12.1, NULL, 'census2022_revised', 'GASTAT_LMS_Q3_2025;GASTAT_LMS_Q4_2025', NULL),
    ('2025Q4', 7.2, NULL, 10.3, 3.5, 'census2022_revised', 'GASTAT_LMS_Q4_2025', NULL),
    ('2026Q1', 6.4, NULL, 9.0, 3.1, 'census2022_revised', 'GASTAT_LMS_Q1_2026', NULL),
    ('2026Q2', 6.5, 4.8, 9.6, 3.0, 'census2022_revised', 'ENT_Q2_2026', NULL);

-- Employment-to-population ratio, Saudi women (%)
INSERT INTO stg.LabourFemaleEmpPop (QuarterKey, SaudiFemaleEmpToPop, SourceID) VALUES
    ('2024Q1', 30.7, 'GASTAT_LMS_Q1_2025'),
    ('2024Q2', 30.8, 'GASTAT_LMS_Q2_2024'),
    ('2024Q3', 31.3, 'AMWAL_Q3_2024'),
    ('2024Q4', 31.8, 'GASTAT_LMS_Q1_2025'),
    ('2025Q1', 32.5, 'GASTAT_LMS_Q1_2025'),
    ('2025Q3', 29.7, 'GASTAT_LMS_Q4_2025'),
    ('2025Q4', 31.0, 'GASTAT_LMS_Q4_2025'),
    ('2026Q1', 30.8, 'GASTAT_LMS_Q1_2026');

-- Real GDP growth by activity, YoY % (rebased series, base 2023)
INSERT INTO stg.GDPGrowthQuarterly (QuarterKey, TotalGDP, Oil, NonOil, Government, EstimateType, SourceID, Note) VALUES
    ('2025Q1', 3.4, -0.5, 4.9, 3.2, 'final', 'GASTAT_GDP_Q1_2025', NULL),
    ('2025Q2', 3.9, 3.8, 4.6, 0.6, 'final', 'GASTAT_GDP_Q2_2025', NULL),
    ('2025Q3', 4.8, 8.3, 4.3, 1.4, 'final', 'GASTAT_GDP_Q3_2025', N'flash had 5.0 / 8.2 / 4.5 / 1.8'),
    ('2025Q4', 4.9, 10.4, 4.1, -1.2, 'final', 'GASTAT_GDP_2025', NULL),
    ('2026Q1', 3.0, 2.9, 2.9, 1.5, 'final', 'GASTAT_GDP_Q1_2026', N'flash had 2.8 / 2.3 / 2.8 / 1.5'),
    ('2026Q2', -4.7, -24.7, 0.8, 0.9, 'mixed', 'GASTAT_FLASH_Q3_2026;GASTAT_FLASH_Q2_2026', N'GDP and non-oil revised in Q3 flash; oil & government still flash values'),
    ('2026Q3', -3.8, -20.4, 1.9, -2.7, 'flash', 'GASTAT_FLASH_Q3_2026', NULL);

INSERT INTO stg.GDPGrowthAnnual ([Year], TotalGDP, Oil, NonOil, Government, SourceID, Note) VALUES
    (2024, 2.0, -4.4, 4.5, NULL, 'IMF_A4_2025', N'rebased series (base 2023); pre-rebase release said 1.3 / -4.5 / 4.3'),
    (2025, 4.5, 5.7, 4.9, 0.9, 'GASTAT_GDP_2025', NULL);

-- Real GDP levels, SAR bn (chain-linked)
INSERT INTO stg.GDPLevels (QuarterKey, OilSARbn, NonOilSARbn, GovSARbn, NetTaxSARbn, GDPSARbn, SourceID) VALUES
    ('2024Q3', 308.51, 646.71, 148.59, 62.84, 1166.65, 'ARGAAM_GDP_Q3_2025'),
    ('2025Q3', 334.01, 674.22, 150.60, 65.07, 1222.87, 'ARGAAM_GDP_Q3_2025');

-- Indicator dimension (EN / AR names; BetterWhen drives the arrows and colours)
INSERT INTO dw.DimIndicator (IndicatorKey, IndicatorName, IndicatorNameAr, Domain, Population, Unit, BetterWhen) VALUES
    ('LFPR_SA_M', N'Labour force participation – Saudi men', N'المشاركة في القوى العاملة – السعوديون', 'Labour', 'Saudi male', N'%', 'higher'),
    ('LFPR_SA_F', N'Labour force participation – Saudi women', N'المشاركة في القوى العاملة – السعوديات', 'Labour', 'Saudi female', N'%', 'higher'),
    ('LFPR_SA_T', N'Labour force participation – Saudis', N'المشاركة في القوى العاملة – إجمالي السعوديين', 'Labour', 'Saudi total', N'%', 'higher'),
    ('UR_SA_T', N'Unemployment rate – Saudis', N'معدل البطالة – السعوديون', 'Labour', 'Saudi total', N'%', 'lower'),
    ('UR_SA_M', N'Unemployment rate – Saudi men', N'معدل البطالة – السعوديون الذكور', 'Labour', 'Saudi male', N'%', 'lower'),
    ('UR_SA_F', N'Unemployment rate – Saudi women', N'معدل البطالة – السعوديات', 'Labour', 'Saudi female', N'%', 'lower'),
    ('UR_KSA_T', N'Unemployment rate – whole Kingdom', N'معدل البطالة – إجمالي المملكة', 'Labour', 'Kingdom total', N'%', 'lower'),
    ('EPR_SA_F', N'Employment-to-population – Saudi women', N'نسبة المشتغلات إلى السكان – السعوديات', 'Labour', 'Saudi female', N'%', 'higher'),
    ('GDP_YOY_T', N'Real GDP growth (YoY)', N'نمو الناتج المحلي الحقيقي (سنوي)', 'Economy', 'Total economy', N'% YoY', 'higher'),
    ('GDP_YOY_OIL', N'Oil activities growth (YoY)', N'نمو الأنشطة النفطية', 'Economy', 'Oil activities', N'% YoY', 'higher'),
    ('GDP_YOY_NONOIL', N'Non-oil activities growth (YoY)', N'نمو الأنشطة غير النفطية', 'Economy', 'Non-oil activities', N'% YoY', 'higher'),
    ('GDP_YOY_GOV', N'Government activities growth (YoY)', N'نمو الأنشطة الحكومية', 'Economy', 'Government activities', N'% YoY', 'higher');

-- Vision 2030 targets: original and revised
INSERT INTO dw.DimTarget (IndicatorKey, KPIName, KPINameAr, BaselineValue, BaselinePeriod, OriginalTarget2030, RevisedTarget2030, RevisedWhen, SourceID) VALUES
    ('UR_SA_T', N'Saudi unemployment rate', N'معدل البطالة بين السعوديين', 12.7, N'2017Q1 (earliest in dataset)', 7.0, 5.0, N'Nov 2024', 'ARABNEWS_TARGET_5'),
    ('LFPR_SA_F', N'Saudi female labour force participation', N'مشاركة المرأة السعودية في سوق العمل', 17.7, N'2016Q2', 30.0, 40.0, N'2024-2025', 'AAWSAT_TARGET_40;GLMM_LFPR_2016');

-- Source register
INSERT INTO dw.DimSource (SourceID, Publisher, Title, Url, SourceType) VALUES
    ('GLMM_LFPR', N'Gulf Labour Markets & Migration (GRC) compiling GASTAT', N'Saudi Arabia LFPR by nationality and sex Q1 2021-Q1 2026 (census-2022 revised)', N'https://gulfmigration.grc.net/saudi-arabia-labour-force-participation-rates-by-nationality-saudi-non-saudi-and-sex-q1-2021-q1-2026/', 'secondary (verbatim GASTAT table)'),
    ('GLMM_LFPR_2016', N'Gulf Labour Markets & Migration (GRC) compiling GASTAT', N'Saudi Arabia LFPR Q2 2016-Q3 2023', N'https://gulfmigration.grc.net/saudi-arabia-labour-force-participation-rates-by-nationality-saudi-non-saudi-and-sex-q2-2016-q3-2023/', 'secondary (verbatim GASTAT table)'),
    ('ARGAAM_UR', N'Argaam', N'Unemployment among Saudis down to 7.1% in Q2 2024 (history table)', N'https://www.argaam.com/en/article/articledetail/id/1757560', 'secondary'),
    ('ARGAAM_Q3_2024', N'Argaam', N'Unemployment among Saudis up to 7.8% in Q3 2024', N'https://www.argaam.com/en/article/articledetail/id/1779328', 'secondary'),
    ('AMWAL_Q3_2024', N'Amwal Al Ghad', N'S. Arabia unemployment rises to 7.8% in Q3-24', N'https://en.amwalalghad.com/?p=188052', 'secondary'),
    ('GASTAT_LMS_Q1_2024', N'GASTAT', N'Labor Market Publication Q1 2024 (news)', N'https://stats.gov.sa/en/news/535', 'primary'),
    ('GASTAT_LMS_Q2_2024', N'GASTAT', N'Labor Market Statistics Q2 2024 press release', N'https://stats.gov.sa/sites/default/files/LMS%20Q2_2024_PR_EN_0.pdf', 'primary'),
    ('GASTAT_LMS_Q1_2025', N'GASTAT', N'Labor Market Statistics Q1 2025 press release', N'https://www.stats.gov.sa/documents/d/guest/lms-q1_2025_pr_en-press-release-1-pdf', 'primary'),
    ('GASTAT_LMS_Q2_2025', N'GASTAT', N'GASTAT publishes Labor Market Statistics for Q2 of 2025', N'https://stats.gov.sa/en/w/news/93', 'primary'),
    ('GASTAT_LMS_Q3_2025', N'GASTAT', N'GASTAT publishes Labor Market Statistics for Q3 of 2025', N'https://www.stats.gov.sa/en/w/news/146', 'primary'),
    ('GASTAT_LMS_Q4_2025', N'GASTAT', N'Labor Market Statistics Q4 2025 press release', N'https://www.stats.gov.sa/documents/d/guest/lms-q4_2025_pr_en-press-release-1-pdf', 'primary'),
    ('GASTAT_LMS_Q1_2026', N'Gulf News reporting GASTAT', N'Saudi unemployment falls to 6.4% in Q1 2026', N'https://gulfnews.com/world/gulf/saudi/saudi-unemployment-falls-to-64-in-q1-2026-1.500592445', 'secondary'),
    ('ENT_Q2_2026', N'EnterpriseAM reporting GASTAT', N'First wartime labor data: women''s employment stalls as participation slips', N'https://enterpriseam.com/ksa/2026/10/01/first-wartime-labor-data-womens-employment-stalls-as-participation-slips/', 'secondary'),
    ('IMF_A4_2025', N'IMF', N'Saudi Arabia 2025 Article IV staff report', N'https://www.imf.org/-/media/files/publications/cr/2025/english/1sauea2025001-source-pdf.pdf', 'primary'),
    ('GASTAT_GDP_Q1_2025', N'WAM reporting GASTAT', N'Saudi Arabia''s real GDP grows 3.4% in Q1 2025', N'https://www.wam.ae/en/article/bk3mkxr-saudi-arabias-real-gdp-grows-34-2025', 'secondary'),
    ('GASTAT_GDP_Q2_2025', N'GASTAT', N'Non-oil activities grow by 4.6% in Q2 2025', N'https://stats.gov.sa/en/w/news/83', 'primary'),
    ('GASTAT_GDP_Q3_2025', N'GASTAT', N'Saudi economy grows by 4.8% in Q3 2025', N'https://stats.gov.sa/en/w/news/131', 'primary'),
    ('GASTAT_GDP_2025', N'GASTAT', N'Saudi economy records 4.5% growth in 2025', N'https://www.stats.gov.sa/en/w/news/171', 'primary'),
    ('GASTAT_GDP_Q1_2026', N'GASTAT', N'Saudi economy records 3.0% growth in Q1 of 2026', N'https://stats.gov.sa/en/w/news/199', 'primary'),
    ('GASTAT_FLASH_Q2_2026', N'Arab News reporting GASTAT', N'Saudi non-oil activities up 0.6% in Q2', N'https://www.arabnews.pk/node/2652792/business-economy', 'secondary'),
    ('GASTAT_FLASH_Q3_2026', N'GASTAT', N'Real GDP flash estimates Q3 2026', N'https://www.stats.gov.sa/documents/d/guest/gdp-flash-estimatesq3-2026-en', 'primary'),
    ('ARGAAM_GDP_Q3_2025', N'Argaam', N'Saudi GDP rises 4.8% in Q3 2025 (levels table)', N'https://www.argaam.com/en/article/articledetail/id/1864350', 'secondary'),
    ('ARABNEWS_TARGET_5', N'Arab News', N'Saudi Arabia sets new unemployment rate target of 5% by 2030', N'https://www.arabnews.pk/node/2580945', 'secondary'),
    ('AAWSAT_TARGET_40', N'Asharq Al-Awsat', N'Saudi Vision drives localization; female participation goal revised to 40%', N'https://english.aawsat.com/node/5136748', 'secondary');
GO
