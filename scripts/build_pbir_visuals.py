"""Generate PBIR visual.json files for the Vision 2030 report (page canvas 1920x1080).
Mockup coordinates are in 1280x720 space and are scaled by 1.5."""
import json, os, hashlib, shutil

OUT = "pbir_out"  # then copy pages/* into powerbi/Vision2030_Dashboard.Report/definition/pages
shutil.rmtree(OUT, ignore_errors=True)
S = 1.5
SCHEMA = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.14.0/schema.json"
PAGES = {"overview": "91d73dfc05cb88c28320", "labour": "6b0994b00c483ce0914b",
         "women": "e4d14b399de510a6435c", "divers": "5e8944cdec5c2512ecd4", "data": "106d161fed60c0060593"}
G, GOLD, INK, MUTED, WHITE, RED = "#0E7C4A", "#B5832A", "#16201B", "#98A19C", "#FFFFFF", "#B42318"

def L(v):            # literal expr
    return {"expr": {"Literal": {"Value": v}}}
def s(v): return L(f"'{v}'")
def b(v): return L("true" if v else "false")
def d(v): return L(f"{v}D")
def color(c): return {"solid": {"color": s(c)}}
def mref(m): return {"Measure": {"Expression": {"SourceRef": {"Entity": "FactKPI"}}, "Property": m}}
def cref(t, c): return {"Column": {"Expression": {"SourceRef": {"Entity": t}}, "Property": c}}
def color_measure(m): return {"solid": {"color": {"expr": mref(m)}}}

def proj_m(m, name=None):
    p = {"field": mref(m), "queryRef": f"FactKPI.{m}", "nativeQueryRef": m}
    if name: p["displayName"] = name
    return p
def proj_c(t, c, name=None, active=False):
    p = {"field": cref(t, c), "queryRef": f"{t}.{c}", "nativeQueryRef": c}
    if active: p["active"] = True
    if name: p["displayName"] = name
    return p

def flt_in(table, col, values):
    return {"name": "f" + hashlib.md5((table + col + str(values)).encode()).hexdigest()[:16],
            "field": cref(table, col), "type": "Categorical",
            "filter": {"Version": 2, "From": [{"Name": "t", "Entity": table, "Type": 0}],
                       "Where": [{"Condition": {"In": {
                           "Expressions": [{"Column": {"Expression": {"SourceRef": {"Source": "t"}}, "Property": col}}],
                           "Values": [[{"Literal": {"Value": f"'{v}'"}}] for v in values]}}}]}}

CONTAINER = {"background": [{"properties": {"show": b(False)}}],
             "border": [{"properties": {"show": b(False)}}],
             "dropShadow": [{"properties": {"show": b(False)}}],
             "title": [{"properties": {"show": b(False)}}],
             "visualHeader": [{"properties": {"show": b(False)}}]}

pages = {k: [] for k in PAGES}
def add(page, vtype, rect, query=None, objects=None, filters=None, extra_container=None, sort=None):
    x, y, w, h = rect
    name = hashlib.md5(f"{page}{len(pages[page])}{vtype}".encode()).hexdigest()[:20]
    vis = {"visualType": vtype}
    if query:
        vis["query"] = {"queryState": query}
        if sort: vis["query"]["sortDefinition"] = sort
    if objects: vis["objects"] = objects
    cont = json.loads(json.dumps(CONTAINER))
    if extra_container: cont.update(extra_container)
    vis["visualContainerObjects"] = cont
    vis["drillFilterOtherVisuals"] = True
    v = {"$schema": SCHEMA, "name": name,
         "position": {"x": round(x * S, 1), "y": round(y * S, 1), "z": len(pages[page]) * 1000 + 1000,
                      "height": round(h * S, 1), "width": round(w * S, 1), "tabOrder": len(pages[page]) * 1000},
         "visual": vis}
    if filters: v["filterConfig"] = {"filters": filters}
    pages[page].append(v)

def card(page, rect, measure, size=20, col=INK, filters=None, color_from=None, bold=True):
    lab = {"fontSize": d(size), "labelDisplayUnits": d(1),
           "fontFamily": s("'Segoe UI Semibold', wf_segoe-ui_semibold, helvetica, arial, sans-serif" if bold else "'Segoe UI', wf_segoe-ui_normal, helvetica, arial, sans-serif"),
           "color": color_measure(color_from) if color_from else color(col)}
    add(page, "card", rect, {"Values": {"projections": [proj_m(measure)]}},
        {"labels": [{"properties": lab}], "categoryLabels": [{"properties": {"show": b(False)}}]}, filters)

SORT_D = {"sort": [{"field": cref("DimQuarter", "QuarterStart"), "direction": "Ascending"}], "isDefaultSort": True}
SORT_Q = {"sort": [{"field": cref("DimQuarter", "QuarterLabel"), "direction": "Ascending"}], "isDefaultSort": True}
def axes(show_cat=True, show_val=True, val_title=False):
    return {"categoryAxis": [{"properties": {"show": b(show_cat), "showAxisTitle": b(False), "fontSize": d(11),
                                             "labelColor": color(MUTED), "gridlineShow": b(False)}}],
            "valueAxis": [{"properties": {"show": b(show_val), "showAxisTitle": b(val_title), "fontSize": d(11),
                                          "labelColor": color(MUTED), "gridlineShow": b(True),
                                          "gridlineColor": color("#E6E8E6"), "gridlineStyle": s("dashed")}}]}
def series_colors(pairs):
    return [{"properties": {"fill": color(c)}, "selector": {"metadata": f"FactKPI.{m}"}} for m, c in pairs]
def ref_lines(lines):
    out = []
    for i, (v, label) in enumerate(lines, 1):
        out.append({"properties": {"show": b(True), "displayName": s(label), "value": d(v),
                                   "lineColor": color(GOLD), "transparency": d(0), "style": s("dashed"),
                                   "width": d(2), "position": s("front"), "dataLabelShow": b(True),
                                   "dataLabelColor": color("#8A6420"), "dataLabelText": s("Name"),
                                   "dataLabelHorizontalPosition": s("right"), "dataLabelVerticalPosition": s("above")},
                    "selector": {"id": str(i)}})
    return out
def legend(show=True):
    return [{"properties": {"show": b(show), "position": s("TopLeft"), "fontSize": d(11), "labelColor": color("#5B6660"),
                            "showTitle": b(False)}}]

def line_chart(page, rect, measures, refs=None, show_legend=True, area=False, y_start=None, y_end=None):
    obj = axes()
    obj["dataPoint"] = series_colors(measures)
    obj["lineStyles"] = [{"properties": {"strokeWidth": d(3), "showMarker": b(False), "lineStyle": s("solid"),
                                         "lineChartType": s("straight"), "lineInterpolation": s("linear")}}]
    obj["categoryAxis"][0]["properties"]["axisType"] = s("Scalar")
    if y_start is not None: obj["valueAxis"][0]["properties"]["start"] = d(y_start)
    if y_end is not None: obj["valueAxis"][0]["properties"]["end"] = d(y_end)
    obj["legend"] = legend(show_legend)
    if refs: obj["y1AxisReferenceLine"] = ref_lines(refs)
    add(page, "areaChart" if area else "lineChart", rect,
        {"Category": {"projections": [proj_c("DimQuarter", "QuarterStart", active=True)]},
         "Y": {"projections": [proj_m(m) for m, _ in measures]}}, obj, sort=SORT_D)

def column_chart(page, rect, measures, highlight_latest=False, show_legend=False):
    obj = axes()
    if highlight_latest:
        obj["dataPoint"] = [{"properties": {"fill": color_measure("Column Color Latest")},
                             "selector": {"data": [{"dataViewWildcard": {"matchingOption": 1}}]}}]
    else:
        obj["dataPoint"] = series_colors(measures)
    obj["labels"] = [{"properties": {"show": b(True), "fontSize": d(11), "color": color(INK), "labelPrecision": L("1L")}}]
    obj["legend"] = legend(show_legend)
    add(page, "clusteredColumnChart", rect,
        {"Category": {"projections": [proj_c("DimQuarter", "QuarterLabel", active=True)]},
         "Y": {"projections": [proj_m(m) for m, _ in measures]}}, obj, sort=SORT_Q)

def table(page, rect, projections, filters=None, font=12):
    obj = {"grid": [{"properties": {"gridVertical": b(False), "gridHorizontal": b(True),
                                    "gridHorizontalColor": color("#E6E8E6"), "rowPadding": d(6), "textSize": d(font)}}],
           "columnHeaders": [{"properties": {"fontColor": color(MUTED), "backColor": color(WHITE), "fontSize": d(font)}}],
           "values": [{"properties": {"fontColorPrimary": color(INK), "backColorPrimary": color(WHITE),
                                      "backColorSecondary": color("#F7F8F7"), "fontSize": d(font)}}],
           "total": [{"properties": {"totals": b(False)}}]}
    add(page, "tableEx", rect, {"Values": {"projections": projections}}, obj, filters)

def year_slicer(page):
    add(page, "slicer", (1010, 88, 92, 26), {"Values": {"projections": [proj_c("DimQuarter", "Year", active=True)]}},
        {"data": [{"properties": {"mode": s("Dropdown")}}],
         "header": [{"properties": {"show": b(False)}}],
         "items": [{"properties": {"fontColor": color(INK), "textSize": d(9), "background": color(WHITE)}}],
         "selection": [{"properties": {"selectAllCheckboxEnabled": b(True), "singleSelect": b(False)}}]})

TABS = [(396, 83, "overview"), (481, 111, "labour"), (594, 71, "women"), (667, 109, "divers"), (778, 112, "data")]
def nav_buttons(page):
    for x, w, target in TABS:
        if target == page: continue
        add(page, "actionButton", (x, 25, w, 31), None,
            {"icon": [{"properties": {"shapeType": s("blank")}}, {"properties": {"shapeType": s("blank")}, "selector": {"id": "default"}}],
             "fill": [{"properties": {"show": b(True), "fillColor": color(WHITE), "transparency": d(100)}},
                      {"properties": {"show": b(True), "fillColor": color(WHITE), "transparency": d(100)}, "selector": {"id": "default"}},
                      {"properties": {"show": b(True), "fillColor": color(WHITE), "transparency": d(70)}, "selector": {"id": "hover"}},
                      {"properties": {"show": b(True), "fillColor": color(WHITE), "transparency": d(40)}, "selector": {"id": "selected"}}],
             "outline": [{"properties": {"show": b(False)}}, {"properties": {"show": b(False)}, "selector": {"id": "default"}}],
             "text": [{"properties": {"show": b(False)}}, {"properties": {"show": b(False)}, "selector": {"id": "default"}}]},
            extra_container={"visualLink": [{"properties": {"show": b(True), "type": s("PageNavigation"),
                                                            "navigationSection": s(PAGES[target])}}]})

IND = lambda k: [flt_in("DimIndicator", "IndicatorKey", [k])]

# ---------------- Page 1: Overview ----------------
p = "overview"
card(p, (100, 220, 150, 48), "Saudi Unemployment Latest", 26, WHITE)
card(p, (130, 192, 92, 34), "Latest Quarter Label", 11, WHITE, IND("UR_SA_T"), bold=False)
card(p, (188, 274, 100, 28), "Gap to Revised Target pp", 11, WHITE, IND("UR_SA_T"), bold=False)
card(p, (200, 344, 92, 32), "Progress to Revised Target %", 16, G, IND("UR_SA_T"))
card(p, (78, 440, 105, 40), "Female LFPR Latest", 20)
card(p, (180, 446, 115, 28), "YoY Arrow", 11, filters=IND("LFPR_SA_F"), color_from="YoY Color")
column_chart(p, (324, 190, 654, 300), [("Non-Oil Growth", G)], highlight_latest=True)
card(p, (1010, 205, 242, 44), "Change Since Start pp", 22, filters=IND("UR_SA_T"))
line_chart(p, (1004, 262, 254, 232), [("Saudi UR", G)], refs=[(5, "Target 5%")], show_legend=False, area=True, y_start=0, y_end=16)
_o = pages[p][-1]["visual"]["objects"]; _o["categoryAxis"][0]["properties"]["show"] = b(False); _o["valueAxis"][0]["properties"]["show"] = b(False); _o["valueAxis"][0]["properties"]["gridlineShow"] = b(False)
table(p, (84, 556, 890, 140), [proj_c("DimIndicator", "IndicatorName", "Indicator"), proj_m("Latest Value", "Latest"),
                               proj_m("Latest Quarter Label", "Quarter"), proj_m("Target 2030 Original", "Original 2030 target"),
                               proj_m("Target 2030 Revised", "Revised 2030 target"), proj_m("YoY Arrow", "Year on year"),
                               proj_m("Target Status", "Status")],
      [flt_in("DimIndicator", "IndicatorKey", ["UR_SA_T", "LFPR_SA_F", "GDP_YOY_NONOIL"])])
card(p, (1010, 566, 110, 44), "Non-Oil Share of Real GDP %", 24)
card(p, (1120, 574, 120, 30), "Oil Share of Real GDP %", 12, MUTED, bold=False)
year_slicer(p); nav_buttons(p)

# ---------------- Page 2: Labour market ----------------
p = "labour"
for i, (m, f, extra) in enumerate([("Saudi Unemployment Latest", None, "UR_SA_T"), ("Latest Value", "UR_KSA_T", "UR_KSA_T"),
                                   ("Latest Value", "LFPR_SA_T", "LFPR_SA_T"), ("Gap to Revised Target pp", "UR_SA_T", None)]):
    x = 70 + i * 301
    card(p, (x + 8, 186, 140, 46), m, 22, filters=IND(f) if f else None)
    if extra:
        card(p, (x + 150, 192, 132, 30), "YoY Arrow", 11, filters=IND(extra), color_from="YoY Color")
    else:
        card(p, (x + 150, 192, 132, 30), "Change Since Start pp", 11, MUTED, IND("UR_SA_T"), bold=False)
line_chart(p, (80, 300, 870, 400), [("Saudi UR", G)], refs=[(7, "Original 7%"), (5, "Revised 5%")], show_legend=False, y_start=0, y_end=17)
add(p, "slicer", (985, 590, 265, 100), {"Values": {"projections": [proj_c("DimQuarter", "Period", active=True)]}},
    {"data": [{"properties": {"mode": s("Basic")}}], "header": [{"properties": {"show": b(False)}}],
     "items": [{"properties": {"fontColor": color(INK), "textSize": d(11)}}]})
year_slicer(p); nav_buttons(p)

# ---------------- Page 3: Women ----------------
p = "women"
line_chart(p, (80, 186, 505, 512), [("Female LFPR", G), ("Male LFPR", GOLD)], refs=[(30, "30% original"), (40, "40% revised")], y_start=20, y_end=72)
line_chart(p, (619, 186, 369, 512), [("Female UR", G), ("Female EPR", GOLD)], y_start=5, y_end=35)
Q1 = [flt_in("DimQuarter", "QuarterKey", ["2026Q1"])]
card(p, (1040, 222, 190, 44), "Female UR at Peak Participation", 26, WHITE, Q1)
card(p, (1040, 262, 190, 28), "Denominator Effect pp", 12, WHITE, Q1, bold=False)
card(p, (1024, 478, 120, 44), "Progress to Revised Target %", 26, filters=IND("LFPR_SA_F"))
card(p, (1024, 528, 110, 26), "Female LFPR Latest", 12, MUTED, bold=False)
card(p, (1136, 528, 112, 26), "Gap to Revised Target pp", 12, MUTED, IND("LFPR_SA_F"), bold=False)
year_slicer(p); nav_buttons(p)

# ---------------- Page 4: Diversification ----------------
p = "divers"
for i, (m, f) in enumerate([("Non-Oil Growth Latest", None), ("Latest Value", "GDP_YOY_OIL"), ("Latest Value", "GDP_YOY_T")]):
    x = 70 + i * 310
    card(p, (x + 8, 186, 150, 46), m, 22, filters=IND(f) if f else None)
    card(p, (x + 160, 192, 128, 30), "Latest Quarter Label", 11, MUTED, IND(f or "GDP_YOY_NONOIL"), bold=False)
card(p, (1012, 184, 60, 44), "Quarters Non-Oil Beat Oil", 24)
card(p, (1064, 192, 80, 32), "Quarters With GDP Data", 12, MUTED, bold=False)
column_chart(p, (80, 300, 896, 400), [("Non-Oil Growth", G), ("Oil Growth", GOLD)], show_legend=True)
add(p, "tableEx", (1012, 312, 238, 160),
    {"Values": {"projections": [{"field": cref("GDPAnnual", "Year"), "queryRef": "GDPAnnual.Year", "nativeQueryRef": "Year"},
                                {"field": {"Aggregation": {"Expression": cref("GDPAnnual", "TotalGDP"), "Function": 0}}, "queryRef": "Sum(GDPAnnual.TotalGDP)", "nativeQueryRef": "Total", "displayName": "Total"},
                                {"field": {"Aggregation": {"Expression": cref("GDPAnnual", "NonOil"), "Function": 0}}, "queryRef": "Sum(GDPAnnual.NonOil)", "nativeQueryRef": "Non-oil", "displayName": "Non-oil"},
                                {"field": {"Aggregation": {"Expression": cref("GDPAnnual", "Oil"), "Function": 0}}, "queryRef": "Sum(GDPAnnual.Oil)", "nativeQueryRef": "Oil", "displayName": "Oil"}]}},
    {"grid": [{"properties": {"gridVertical": b(False), "rowPadding": d(6), "textSize": d(9)}}],
     "columnHeaders": [{"properties": {"fontColor": color(MUTED), "backColor": color(WHITE), "fontSize": d(9)}}],
     "values": [{"properties": {"fontColorPrimary": color(INK), "backColorPrimary": color(WHITE), "backColorSecondary": color("#F7F8F7"), "fontSize": d(9)}}],
     "total": [{"properties": {"totals": b(False)}}]})
card(p, (1012, 512, 120, 40), "Non-Oil Share of Real GDP %", 22)
year_slicer(p); nav_buttons(p)

# ---------------- Page 5: Data & method ----------------
p = "data"
add(p, "tableEx", (84, 188, 698, 505),
    {"Values": {"projections": [proj_c("DimSource", "Publisher"), proj_c("DimSource", "Title", "Release"),
                                proj_c("DimSource", "SourceType", "Type"), proj_c("DimSource", "Url", "Link")]}},
    {"grid": [{"properties": {"gridVertical": b(False), "rowPadding": d(5), "textSize": d(10)}}],
     "columnHeaders": [{"properties": {"fontColor": color(MUTED), "backColor": color(WHITE), "fontSize": d(10)}}],
     "values": [{"properties": {"fontColorPrimary": color(INK), "backColorPrimary": color(WHITE), "backColorSecondary": color("#F7F8F7"), "fontSize": d(10), "urlIcon": b(True)}}]})
nav_buttons(p); year_slicer(p)

# ---------------- write ----------------
manifest = []
for key, visuals in pages.items():
    for v in visuals:
        rel = f"pages/{PAGES[key]}/visuals/{v['name']}/visual.json"
        os.makedirs(os.path.dirname(f"{OUT}/{rel}"), exist_ok=True)
        json.dump(v, open(f"{OUT}/{rel}", "w"), indent=2)
        manifest.append(rel)
json.dump(manifest, open(f"{OUT}/manifest.json", "w"))
print(len(manifest), "visuals")
