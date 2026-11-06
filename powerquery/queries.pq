// =====================================================================
//  Saudi Vision 2030 Analytics Dashboard — Power Query (M)
//  ---------------------------------------------------------------------
//  One block per query. In Power BI: Transform data → New Source →
//  Blank Query → Advanced Editor → paste the block → rename the query
//  to the name in the header line.
//  SQL does the heavy lifting (unpivot, shares, QA); Power Query does
//  the connection, types, the quarter calendar and report-friendly flags.
// =====================================================================


// ---------------------------------------------------------------------
// QUERY: pServer        (parameter)
// ---------------------------------------------------------------------
"localhost\SQLEXPRESS" meta [IsParameterQuery = true, Type = "Text", IsParameterQueryRequired = true]


// ---------------------------------------------------------------------
// QUERY: pDatabase      (parameter)
// ---------------------------------------------------------------------
"Vision2030" meta [IsParameterQuery = true, Type = "Text", IsParameterQueryRequired = true]


// ---------------------------------------------------------------------
// QUERY: Vision2030DB   (helper — right-click → uncheck "Enable load")
// ---------------------------------------------------------------------
let
    Source = Sql.Database(pServer, pDatabase)
in
    Source


// ---------------------------------------------------------------------
// QUERY: FactKPI
// ---------------------------------------------------------------------
let
    Source  = Vision2030DB{[Schema = "dw", Item = "vw_FactKPI"]}[Data],
    Typed   = Table.TransformColumnTypes(Source, {
                {"QuarterKey", type text}, {"IndicatorKey", type text},
                {"Value", type number},    {"SeriesVintage", type text},
                {"EstimateType", type text}, {"SourceID", type text},
                {"Note", type text}}),
    // report-friendly flags used in tooltips and conditional formatting
    AddIsFlash       = Table.AddColumn(Typed, "IsFlash",
                         each [EstimateType] <> "final", type logical),
    AddIsPreRevision = Table.AddColumn(AddIsFlash, "IsPreRevision",
                         each [SeriesVintage] = "pre_census2022", type logical)
in
    AddIsPreRevision


// ---------------------------------------------------------------------
// QUERY: DimQuarter
// Built in M from the fact table's own range, so it is always continuous
// (no missing quarters → period-offset DAX never skips a quarter).
// ---------------------------------------------------------------------
let
    Keys       = List.Distinct(FactKPI[QuarterKey]),
    // "2017Q1" → absolute quarter number (year*4 + q - 1)
    ToAbs      = (k as text) as number =>
                    Number.From(Text.Start(k, 4)) * 4 + Number.From(Text.End(k, 1)) - 1,
    AbsList    = List.Transform(Keys, ToAbs),
    MinAbs     = List.Min(AbsList),
    MaxAbs     = List.Max(AbsList),
    Base       = Table.FromList({MinAbs .. MaxAbs}, Splitter.SplitByNothing(), {"Abs"}, null, ExtraValues.Error),
    AddYear    = Table.AddColumn(Base, "Year", each Number.IntegerDivide([Abs], 4), Int64.Type),
    AddQNum    = Table.AddColumn(AddYear, "QuarterNum", each Number.Mod([Abs], 4) + 1, Int64.Type),
    AddKey     = Table.AddColumn(AddQNum, "QuarterKey",
                    each Text.From([Year]) & "Q" & Text.From([QuarterNum]), type text),
    AddLabel   = Table.AddColumn(AddKey, "QuarterLabel",
                    each "Q" & Text.From([QuarterNum]) & " " & Text.From([Year]), type text),
    AddStart   = Table.AddColumn(AddLabel, "QuarterStart",
                    each #date([Year], ([QuarterNum] - 1) * 3 + 1, 1), type date),
    AddIndex   = Table.AddColumn(AddStart, "QuarterIndex", each [Abs] - MinAbs + 1, Int64.Type),
    AddPeriod  = Table.AddColumn(AddIndex, "Period", each
                    if [Year] <= 2019 then "Pre-COVID (≤2019)"
                    else if [Year] <= 2021 then "COVID & recovery (2020–21)"
                    else if [Year] <= 2024 then "Acceleration (2022–24)"
                    else "Late Vision (2025+)", type text),
    AddCovid   = Table.AddColumn(AddPeriod, "IsCovidShock",
                    each List.Contains({"2020Q2", "2020Q3"}, [QuarterKey]), type logical),
    Result     = Table.SelectColumns(AddCovid, {"QuarterKey", "Year", "QuarterNum", "QuarterLabel",
                    "QuarterStart", "QuarterIndex", "Period", "IsCovidShock"})
in
    Result


// ---------------------------------------------------------------------
// QUERY: DimIndicator
// ---------------------------------------------------------------------
let
    Source = Vision2030DB{[Schema = "dw", Item = "DimIndicator"]}[Data],
    Typed  = Table.TransformColumnTypes(Source, {
                {"IndicatorKey", type text}, {"IndicatorName", type text},
                {"IndicatorNameAr", type text}, {"Domain", type text},
                {"Population", type text}, {"Unit", type text}, {"BetterWhen", type text}})
in
    Typed


// ---------------------------------------------------------------------
// QUERY: DimTarget
// ---------------------------------------------------------------------
let
    Source = Vision2030DB{[Schema = "dw", Item = "DimTarget"]}[Data],
    Typed  = Table.TransformColumnTypes(Source, {
                {"IndicatorKey", type text}, {"KPIName", type text}, {"KPINameAr", type text},
                {"BaselineValue", type number}, {"BaselinePeriod", type text},
                {"OriginalTarget2030", type number}, {"RevisedTarget2030", type number},
                {"RevisedWhen", type text}, {"SourceID", type text}})
in
    Typed


// ---------------------------------------------------------------------
// QUERY: DimSource
// ---------------------------------------------------------------------
let
    Source = Vision2030DB{[Schema = "dw", Item = "DimSource"]}[Data],
    Typed  = Table.TransformColumnTypes(Source, {
                {"SourceID", type text}, {"Publisher", type text}, {"Title", type text},
                {"Url", type text}, {"SourceType", type text}}),
    // simple bucket for a slicer / table colour
    AddPrimary = Table.AddColumn(Typed, "IsPrimary",
                    each Text.StartsWith([SourceType], "primary"), type logical)
in
    AddPrimary


// ---------------------------------------------------------------------
// QUERY: GDPLevels
// ---------------------------------------------------------------------
let
    Source = Vision2030DB{[Schema = "dw", Item = "vw_GDPLevels"]}[Data],
    Typed  = Table.TransformColumnTypes(Source, {
                {"QuarterKey", type text}, {"OilSARbn", type number}, {"NonOilSARbn", type number},
                {"GovSARbn", type number}, {"NetTaxSARbn", type number}, {"GDPSARbn", type number},
                {"NonOilSharePct", type number}, {"OilSharePct", type number}, {"SourceID", type text}})
in
    Typed


// ---------------------------------------------------------------------
// QUERY: GDPAnnual
// ---------------------------------------------------------------------
let
    Source = Vision2030DB{[Schema = "stg", Item = "GDPGrowthAnnual"]}[Data],
    Typed  = Table.TransformColumnTypes(Source, {
                {"Year", Int64.Type}, {"TotalGDP", type number}, {"Oil", type number},
                {"NonOil", type number}, {"Government", type number},
                {"SourceID", type text}, {"Note", type text}})
in
    Typed


// ---------------------------------------------------------------------
// QUERY: QA_FemaleIdentity
// ---------------------------------------------------------------------
let
    Source = Vision2030DB{[Schema = "dw", Item = "vw_QA_FemaleIdentity"]}[Data],
    Typed  = Table.TransformColumnTypes(Source, {
                {"QuarterKey", type text}, {"LFPR", type number}, {"EPR", type number},
                {"UR_Published", type number}, {"UR_Implied", type number}, {"GapPP", type number}}),
    AddPass = Table.AddColumn(Typed, "Check", each if Number.Abs([GapPP]) <= 0.35 then "Pass" else "Fail", type text)
in
    AddPass
