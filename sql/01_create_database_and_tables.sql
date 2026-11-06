/* =====================================================================
   Saudi Vision 2030 Analytics Dashboard
   01 — Database, schemas and tables              (SQL Server / Express)
   ---------------------------------------------------------------------
   stg  = raw data exactly as published (wide, one row per quarter)
   dw   = dimension tables + views that Power BI reads
   Run in SSMS: open this file → Execute (F5).
   ===================================================================== */

IF DB_ID(N'Vision2030') IS NULL
    CREATE DATABASE Vision2030;
GO

USE Vision2030;
GO

IF SCHEMA_ID(N'stg') IS NULL EXEC (N'CREATE SCHEMA stg');
IF SCHEMA_ID(N'dw')  IS NULL EXEC (N'CREATE SCHEMA dw');
GO

/* drop in dependency order so the script can be re-run */
DROP VIEW  IF EXISTS dw.vw_QA_FemaleIdentity, dw.vw_FactKPI, dw.vw_GDPLevels;
DROP TABLE IF EXISTS
    stg.LabourParticipation, stg.LabourUnemployment, stg.LabourFemaleEmpPop,
    stg.GDPGrowthQuarterly, stg.GDPGrowthAnnual, stg.GDPLevels,
    dw.DimTarget, dw.DimIndicator, dw.DimSource;    -- DimTarget first: it references DimIndicator
GO

/* ---------- staging: labour ------------------------------------------ */
CREATE TABLE stg.LabourParticipation (
    QuarterKey  CHAR(6)       NOT NULL PRIMARY KEY,      -- e.g. 2025Q1
    SaudiMale   DECIMAL(5,1)  NULL,
    SaudiFemale DECIMAL(5,1)  NULL,
    SaudiTotal  DECIMAL(5,1)  NULL,
    SourceID    VARCHAR(100)  NOT NULL
);

CREATE TABLE stg.LabourUnemployment (
    QuarterKey    CHAR(6)       NOT NULL PRIMARY KEY,
    SaudiTotal    DECIMAL(5,1)  NULL,
    SaudiMale     DECIMAL(5,1)  NULL,
    SaudiFemale   DECIMAL(5,1)  NULL,
    KingdomTotal  DECIMAL(5,1)  NULL,
    SeriesVintage VARCHAR(30)   NOT NULL,                -- pre_census2022 | census2022_revised
    SourceID      VARCHAR(100)  NOT NULL,
    Note          NVARCHAR(200) NULL
);

CREATE TABLE stg.LabourFemaleEmpPop (
    QuarterKey  CHAR(6)       NOT NULL PRIMARY KEY,
    SaudiFemaleEmpToPop DECIMAL(5,1) NOT NULL,
    SourceID    VARCHAR(100)  NOT NULL
);

/* ---------- staging: economy ----------------------------------------- */
CREATE TABLE stg.GDPGrowthQuarterly (                   -- real YoY growth, %
    QuarterKey   CHAR(6)       NOT NULL PRIMARY KEY,
    TotalGDP     DECIMAL(5,1)  NULL,
    Oil          DECIMAL(5,1)  NULL,
    NonOil       DECIMAL(5,1)  NULL,
    Government   DECIMAL(5,1)  NULL,
    EstimateType VARCHAR(10)   NOT NULL,                 -- final | flash | mixed
    SourceID     VARCHAR(100)  NOT NULL,
    Note         NVARCHAR(200) NULL
);

CREATE TABLE stg.GDPGrowthAnnual (
    [Year]      SMALLINT      NOT NULL PRIMARY KEY,
    TotalGDP    DECIMAL(5,1)  NULL,
    Oil         DECIMAL(5,1)  NULL,
    NonOil      DECIMAL(5,1)  NULL,
    Government  DECIMAL(5,1)  NULL,
    SourceID    VARCHAR(100)  NOT NULL,
    Note        NVARCHAR(200) NULL
);

CREATE TABLE stg.GDPLevels (                            -- real, chain-linked, SAR bn
    QuarterKey   CHAR(6)       NOT NULL PRIMARY KEY,
    OilSARbn     DECIMAL(9,2)  NOT NULL,
    NonOilSARbn  DECIMAL(9,2)  NOT NULL,
    GovSARbn     DECIMAL(9,2)  NOT NULL,
    NetTaxSARbn  DECIMAL(9,2)  NOT NULL,
    GDPSARbn     DECIMAL(9,2)  NOT NULL,
    SourceID     VARCHAR(100)  NOT NULL
);

/* ---------- dimensions ----------------------------------------------- */
CREATE TABLE dw.DimIndicator (
    IndicatorKey    VARCHAR(20)   NOT NULL PRIMARY KEY,
    IndicatorName   NVARCHAR(100) NOT NULL,
    IndicatorNameAr NVARCHAR(100) NOT NULL,
    Domain          VARCHAR(20)   NOT NULL,              -- Labour | Economy
    Population      VARCHAR(30)   NOT NULL,
    Unit            VARCHAR(10)   NOT NULL,
    BetterWhen      VARCHAR(6)    NOT NULL CHECK (BetterWhen IN ('higher','lower'))
);

CREATE TABLE dw.DimTarget (
    IndicatorKey        VARCHAR(20)   NOT NULL PRIMARY KEY
                        REFERENCES dw.DimIndicator (IndicatorKey),
    KPIName             NVARCHAR(100) NOT NULL,
    KPINameAr           NVARCHAR(100) NOT NULL,
    BaselineValue       DECIMAL(5,1)  NOT NULL,
    BaselinePeriod      NVARCHAR(50)  NOT NULL,
    OriginalTarget2030  DECIMAL(5,1)  NOT NULL,
    RevisedTarget2030   DECIMAL(5,1)  NOT NULL,
    RevisedWhen         NVARCHAR(30)  NOT NULL,
    SourceID            VARCHAR(100)  NOT NULL
);

CREATE TABLE dw.DimSource (
    SourceID   VARCHAR(40)   NOT NULL PRIMARY KEY,
    Publisher  NVARCHAR(100) NOT NULL,
    Title      NVARCHAR(200) NOT NULL,
    Url        NVARCHAR(400) NOT NULL,
    SourceType VARCHAR(40)   NOT NULL                     -- primary | secondary
);
GO
