const pptxgen = require("pptxgenjs");
const path = require("path");

const deck = new pptxgen();
deck.layout = "LAYOUT_WIDE";
deck.author = "Microsoft Scout";
deck.company = "Microsoft";
deck.subject = "Cowork Value Intelligence interpretation guide";
deck.title = "Cowork Value Intelligence - Interpretation Guide";
deck.lang = "en-US";
deck.theme = {
  headFontFace: "Aptos Display",
  bodyFontFace: "Aptos",
  lang: "en-US",
};

const root = path.resolve(__dirname, "..");
const images = path.join(root, "images", "report-pages");
const output = path.join(root, "Cowork Value Intelligence - Interpretation Guide.pptx");

const C = {
  plum: "2B174D",
  purple: "4B2D83",
  violet: "7551A8",
  magenta: "D83B96",
  teal: "008272",
  blue: "0078D4",
  orange: "D83B01",
  green: "107C10",
  red: "A80000",
  ink: "202033",
  muted: "625B6A",
  line: "D8CEE8",
  pale: "F7F5FA",
  paleBlue: "EEF5FC",
  paleTeal: "EAF8F7",
  paleOrange: "FFF4EC",
  white: "FFFFFF",
};

deck.defineSlideMaster({
  title: "CONTENT",
  background: { color: C.white },
  objects: [
    {
      rect: {
        x: 0,
        y: 0,
        w: 13.333,
        h: 0.14,
        fill: { color: C.purple },
        line: { color: C.purple },
      },
    },
  ],
  slideNumber: {
    x: 12.55,
    y: 7.16,
    w: 0.35,
    h: 0.15,
    fontFace: "Aptos",
    fontSize: 7,
    color: C.muted,
    align: "right",
    margin: 0,
  },
});

function addFooter(slide, label = "In Testing | Fabricated sample data") {
  slide.addText("llorenz28/cowork-value-intelligence", {
    x: 0.45,
    y: 7.16,
    w: 4.7,
    h: 0.16,
    fontFace: "Aptos",
    fontSize: 6.8,
    color: C.muted,
    margin: 0,
  });
  slide.addText(label, {
    x: 7.1,
    y: 7.16,
    w: 5.1,
    h: 0.16,
    fontFace: "Aptos",
    fontSize: 6.8,
    color: C.muted,
    align: "right",
    margin: 0,
  });
}

function addTitle(slide, title, subtitle) {
  slide.addText(title, {
    x: 0.5,
    y: 0.34,
    w: 8.5,
    h: 0.42,
    fontFace: "Aptos Display",
    fontSize: 24,
    bold: true,
    color: C.plum,
    margin: 0,
  });
  slide.addText(subtitle, {
    x: 8.9,
    y: 0.43,
    w: 3.9,
    h: 0.2,
    fontFace: "Aptos",
    fontSize: 8.5,
    color: C.muted,
    align: "right",
    margin: 0,
  });
}

function addPill(slide, text, x, y, w, color) {
  slide.addShape(deck.ShapeType.roundRect, {
    x,
    y,
    w,
    h: 0.32,
    rectRadius: 0.08,
    fill: { color },
    line: { color },
  });
  slide.addText(text, {
    x: x + 0.05,
    y: y + 0.075,
    w: w - 0.1,
    h: 0.12,
    fontSize: 8,
    bold: true,
    color: C.white,
    align: "center",
    margin: 0,
  });
}

function addCard(slide, label, text, x, y, w, h, color, fill = C.white) {
  slide.addShape(deck.ShapeType.roundRect, {
    x,
    y,
    w,
    h,
    rectRadius: 0.08,
    fill: { color: fill },
    line: { color: C.line, width: 1 },
  });
  slide.addShape(deck.ShapeType.ellipse, {
    x: x + 0.13,
    y: y + 0.13,
    w: 0.34,
    h: 0.34,
    fill: { color },
    line: { color },
  });
  slide.addText(label.slice(0, 1).toUpperCase(), {
    x: x + 0.13,
    y: y + 0.205,
    w: 0.34,
    h: 0.1,
    fontSize: 7.5,
    bold: true,
    color: C.white,
    align: "center",
    margin: 0,
  });
  slide.addText(label.toUpperCase(), {
    x: x + 0.56,
    y: y + 0.15,
    w: w - 0.72,
    h: 0.17,
    fontSize: 7.2,
    bold: true,
    color,
    margin: 0,
  });
  slide.addText(text, {
    x: x + 0.16,
    y: y + 0.5,
    w: w - 0.32,
    h: h - 0.6,
    fontSize: 9,
    color: C.ink,
    margin: 0,
    fit: "shrink",
    valign: "top",
  });
}

function addWideCallout(slide, label, text, x, y, w, h, color, fill) {
  slide.addShape(deck.ShapeType.roundRect, {
    x,
    y,
    w,
    h,
    rectRadius: 0.08,
    fill: { color: fill },
    line: { color, width: 1.1 },
  });
  addPill(slide, label.toUpperCase(), x + 0.14, y + 0.14, 1.12, color);
  slide.addText(text, {
    x: x + 1.45,
    y: y + 0.15,
    w: w - 1.62,
    h: h - 0.28,
    fontSize: 9.2,
    color: C.ink,
    margin: 0,
    fit: "shrink",
    valign: "mid",
  });
}

function addImageFrame(slide, file, x, y, w, h, caption, portrait = false) {
  let imageX = x;
  let imageY = y;
  let imageW = w;
  let imageH = h;
  if (portrait) {
    imageH = h;
    imageW = h * (615 / 748);
    imageX = x + (w - imageW) / 2;
  }

  slide.addShape(deck.ShapeType.roundRect, {
    x: imageX - 0.05,
    y: imageY - 0.05,
    w: imageW + 0.1,
    h: imageH + 0.1,
    rectRadius: 0.05,
    fill: { color: "F0EBF7" },
    line: { color: C.violet, width: 1.1 },
  });
  slide.addImage({
    path: path.join(images, file),
    x: imageX,
    y: imageY,
    w: imageW,
    h: imageH,
  });
  slide.addText(caption, {
    x,
    y: y + h + 0.07,
    w,
    h: 0.16,
    fontSize: 7.2,
    italic: true,
    color: C.muted,
    align: "center",
    margin: 0,
  });
}

function addPageSlide(page) {
  const slide = deck.addSlide("CONTENT");
  addTitle(
    slide,
    page.title,
    `${page.number} of 12 report pages${page.hidden ? " | hidden operational page" : ""}`,
  );
  addImageFrame(
    slide,
    page.image,
    5.15,
    1.02,
    7.65,
    4.3,
    page.caption || "Current Power BI capture | deterministic fabricated sample data",
    page.hidden,
  );
  addCard(slide, "Purpose", page.purpose, 0.5, 1.02, 4.35, 1.0, C.purple);
  addCard(slide, "Read", page.read, 0.5, 2.14, 4.35, 1.0, C.blue);
  addCard(slide, "Diagnose", page.diagnose, 0.5, 3.26, 4.35, 1.0, C.orange);
  addCard(slide, "Interpret", page.interpret, 0.5, 4.38, 4.35, 1.0, C.violet);
  addWideCallout(slide, "Action", page.action, 0.5, 5.67, 6.05, 0.94, C.teal, C.paleTeal);
  addWideCallout(slide, "Guardrail", page.guardrail, 6.75, 5.67, 6.05, 0.94, C.red, C.paleOrange);
  addFooter(slide, page.hidden ? "In Testing | Hidden assumptions page | Fabricated sample data" : undefined);
}

function addSectionSlide(number, title, subtitle) {
  const slide = deck.addSlide();
  slide.background = { color: C.plum };
  slide.addText(`SECTION ${number}`, {
    x: 0.72,
    y: 1.05,
    w: 2.1,
    h: 0.3,
    fontSize: 13,
    bold: true,
    color: "D6CDEA",
    margin: 0,
  });
  slide.addText(title, {
    x: 0.72,
    y: 1.62,
    w: 11.7,
    h: 0.85,
    fontFace: "Aptos Display",
    fontSize: 38,
    bold: true,
    color: C.white,
    margin: 0,
  });
  slide.addText(subtitle, {
    x: 0.72,
    y: 2.82,
    w: 10.9,
    h: 1.1,
    fontSize: 20,
    color: "EEE9F7",
    margin: 0,
    fit: "shrink",
  });
  slide.addShape(deck.ShapeType.roundRect, {
    x: 0.72,
    y: 5.35,
    w: 11.85,
    h: 0.95,
    rectRadius: 0.08,
    fill: { color: C.purple },
    line: { color: C.violet, width: 1 },
  });
  slide.addText("Observed signals. Transparent assumptions. Defensible decisions.", {
    x: 1.05,
    y: 5.67,
    w: 11.2,
    h: 0.28,
    fontSize: 17,
    bold: true,
    color: C.white,
    align: "center",
    margin: 0,
  });
}

// 1. Cover
{
  const slide = deck.addSlide();
  slide.background = { color: C.white };
  slide.addShape(deck.ShapeType.rect, {
    x: 0,
    y: 0,
    w: 5.05,
    h: 7.5,
    fill: { color: C.plum },
    line: { color: C.plum },
  });
  addPill(slide, "IN TESTING | INTERPRETATION GUIDE", 0.7, 0.72, 3.05, C.magenta);
  slide.addText("Cowork\nValue Intelligence", {
    x: 0.7,
    y: 1.48,
    w: 3.85,
    h: 1.55,
    fontFace: "Aptos Display",
    fontSize: 34,
    bold: true,
    color: C.white,
    margin: 0,
  });
  slide.addText("A detailed operating guide for observed work, modeled value, consumption, allocation, and defensible action.", {
    x: 0.7,
    y: 3.45,
    w: 3.72,
    h: 1.35,
    fontSize: 16,
    color: "EEE9F7",
    margin: 0,
    fit: "shrink",
  });
  slide.addText("Fabricated sample data | @example.com identities", {
    x: 0.7,
    y: 6.6,
    w: 3.9,
    h: 0.22,
    fontSize: 9,
    color: "C9BEE0",
    margin: 0,
  });
  addImageFrame(
    slide,
    "02-executive-summary.png",
    5.58,
    1.35,
    7.15,
    4.02,
    "Current Cowork Value executive summary",
  );
  slide.addText("From source evidence to an owned decision.", {
    x: 5.58,
    y: 5.82,
    w: 7.15,
    h: 0.45,
    fontFace: "Aptos Display",
    fontSize: 20,
    bold: true,
    color: C.plum,
    align: "center",
    margin: 0,
  });
}

// 2. Agenda
{
  const slide = deck.addSlide("CONTENT");
  addTitle(slide, "Agenda", "Orientation, page walkthroughs, methodology, and operating boundaries");
  const cards = [
    ["1", "Orient", "Choose the decision and the evidence path before reading a KPI.", C.purple],
    ["2", "Read", "Use the same five-layer page walkthrough for every view.", C.blue],
    ["3", "Challenge", "Inspect assumptions, allocation rules, and missing dependencies.", C.orange],
    ["4", "Act", "End with an owner, source check, guardrail, and next step.", C.teal],
  ];
  cards.forEach((card, i) => {
    const x = 0.68 + (i % 2) * 6.18;
    const y = 1.35 + Math.floor(i / 2) * 2.45;
    slide.addShape(deck.ShapeType.roundRect, {
      x,
      y,
      w: 5.75,
      h: 1.9,
      rectRadius: 0.08,
      fill: { color: i % 2 ? C.paleBlue : C.pale },
      line: { color: C.line, width: 1.1 },
    });
    slide.addShape(deck.ShapeType.ellipse, {
      x: x + 0.28,
      y: y + 0.34,
      w: 0.62,
      h: 0.62,
      fill: { color: card[3] },
      line: { color: card[3] },
    });
    slide.addText(card[0], {
      x: x + 0.28,
      y: y + 0.5,
      w: 0.62,
      h: 0.16,
      fontSize: 13,
      bold: true,
      color: C.white,
      align: "center",
      margin: 0,
    });
    slide.addText(card[1], {
      x: x + 1.12,
      y: y + 0.32,
      w: 3.8,
      h: 0.28,
      fontSize: 16,
      bold: true,
      color: card[3],
      margin: 0,
    });
    slide.addText(card[2], {
      x: x + 1.12,
      y: y + 0.78,
      w: 4.1,
      h: 0.62,
      fontSize: 13,
      color: C.ink,
      margin: 0,
      fit: "shrink",
    });
  });
  addFooter(slide);
}

// 3. What this guide adds
{
  const slide = deck.addSlide("CONTENT");
  addTitle(slide, "What this guide adds", "The report exposes its evidence, assumptions, and interpretation boundaries");
  const items = [
    ["Friendly skill labels", "Curated names appear where known; technical identifiers fall back to readable labels without changing classification.", C.purple],
    ["Value scope control", "Verified-only and broader representative scenarios keep uncertain action mappings visible instead of silently valuing them.", C.blue],
    ["Transparent assumptions", "Category minutes, labor rate, billing mode, price inputs, and quality adjustments remain visible and challengeable.", C.orange],
    ["Allocation boundaries", "Per-skill, department, and model costs are directional allocations unless the source supplies matching metering.", C.teal],
    ["Population gates", "User tiers and related comparisons stay unavailable until the filtered population supports the method.", C.violet],
    ["Decision language", "Every view pairs a next action with wording that stays inside the evidence the report actually contains.", C.green],
  ];
  items.forEach((item, i) => {
    const x = 0.62 + (i % 3) * 4.18;
    const y = 1.18 + Math.floor(i / 3) * 2.5;
    addCard(slide, item[0], item[1], x, y, 3.78, 2.05, item[2], i < 3 ? C.pale : C.paleBlue);
  });
  addFooter(slide);
}

// 4. Five-minute orientation
{
  const slide = deck.addSlide("CONTENT");
  addTitle(slide, "Five-minute orientation", "If time is limited, read these four pages in order");
  const steps = [
    ["1", "Start Here", "Choose the decision path and confirm required inputs.", C.purple],
    ["2", "Executive Summary", "Read observed activity before modeled value and cost.", C.blue],
    ["3", "Methodology & Value Calculator", "Inspect the selected assumptions and sensitivity.", C.orange],
    ["4", "Glossary", "Carry the metric definition and evidence label into the decision.", C.teal],
  ];
  steps.forEach((step, i) => {
    const y = 1.2 + i * 1.35;
    slide.addShape(deck.ShapeType.roundRect, {
      x: 0.85,
      y,
      w: 11.65,
      h: 1.05,
      rectRadius: 0.08,
      fill: { color: i % 2 ? C.paleBlue : C.pale },
      line: { color: C.line, width: 1 },
    });
    slide.addShape(deck.ShapeType.ellipse, {
      x: 1.12,
      y: y + 0.2,
      w: 0.62,
      h: 0.62,
      fill: { color: step[3] },
      line: { color: step[3] },
    });
    slide.addText(step[0], {
      x: 1.12,
      y: y + 0.36,
      w: 0.62,
      h: 0.16,
      fontSize: 13,
      bold: true,
      color: C.white,
      align: "center",
      margin: 0,
    });
    slide.addText(step[1], {
      x: 2.02,
      y: y + 0.21,
      w: 3.25,
      h: 0.25,
      fontSize: 15,
      bold: true,
      color: step[3],
      margin: 0,
    });
    slide.addText(step[2], {
      x: 5.3,
      y: y + 0.2,
      w: 6.6,
      h: 0.48,
      fontSize: 12.5,
      color: C.ink,
      margin: 0,
      fit: "shrink",
    });
  });
  addFooter(slide);
}

// 5. Evidence model
{
  const slide = deck.addSlide("CONTENT");
  addTitle(slide, "Evidence model at a glance", "Required activity flows through derived facts; optional inputs add context and cost");
  const sources = [
    ["Purview audit", "Required event evidence", C.purple],
    ["Cowork usage", "Optional aggregate reconciliation", C.blue],
    ["Organization", "Optional department and business unit context", C.teal],
    ["Consumption", "Optional observed credits and recency", C.orange],
  ];
  sources.forEach((source, i) => {
    const x = 0.58 + i * 3.16;
    slide.addShape(deck.ShapeType.roundRect, {
      x,
      y: 1.2,
      w: 2.72,
      h: 1.72,
      rectRadius: 0.08,
      fill: { color: i % 2 ? C.paleBlue : C.pale },
      line: { color: source[2], width: 1.3 },
    });
    slide.addText(source[0], {
      x: x + 0.18,
      y: 1.52,
      w: 2.36,
      h: 0.3,
      fontSize: 16,
      bold: true,
      color: source[2],
      align: "center",
      margin: 0,
    });
    slide.addText(source[1], {
      x: x + 0.2,
      y: 2.02,
      w: 2.32,
      h: 0.48,
      fontSize: 11,
      color: C.ink,
      align: "center",
      margin: 0,
      fit: "shrink",
    });
  });
  slide.addText("Source evidence", {
    x: 0.7,
    y: 3.48,
    w: 2.2,
    h: 0.28,
    fontSize: 15,
    bold: true,
    color: C.plum,
    margin: 0,
  });
  slide.addShape(deck.ShapeType.chevron, {
    x: 2.9,
    y: 3.35,
    w: 1.0,
    h: 0.6,
    fill: { color: C.violet },
    line: { color: C.violet },
  });
  slide.addText("Derived task, user, category, recency, and reconciliation facts", {
    x: 4.0,
    y: 3.35,
    w: 4.45,
    h: 0.6,
    fontSize: 14,
    bold: true,
    color: C.ink,
    align: "center",
    valign: "mid",
    margin: 0,
  });
  slide.addShape(deck.ShapeType.chevron, {
    x: 8.55,
    y: 3.35,
    w: 1.0,
    h: 0.6,
    fill: { color: C.violet },
    line: { color: C.violet },
  });
  slide.addText("Modeled value and directional allocations", {
    x: 9.62,
    y: 3.35,
    w: 2.9,
    h: 0.6,
    fontSize: 14,
    bold: true,
    color: C.ink,
    align: "center",
    valign: "mid",
    margin: 0,
  });
  addWideCallout(
    slide,
    "Boundary",
    "The usage export is aggregate evidence. It must never manufacture an event timeline or replace missing Purview detail.",
    1.1,
    5.08,
    11.1,
    0.95,
    C.red,
    C.paleOrange,
  );
  addFooter(slide);
}

// 6. Evidence wording
{
  const slide = deck.addSlide("CONTENT");
  addTitle(slide, "Different evidence requires different wording", "Use the label that matches the metric's actual evidence condition");
  const rows = [
    ["OBSERVED", "Direct source count", "The connected export contains...", C.green],
    ["DERIVED", "Arithmetic over observed fields", "The report calculates...", C.blue],
    ["MODELED", "Observed activity plus assumptions", "Under the selected assumptions...", C.purple],
    ["ALLOCATED", "A total distributed without source metering", "The modeled allocation suggests...", C.orange],
    ["UNAVAILABLE", "A required dependency is absent", "This cannot be calculated yet.", C.red],
  ];
  rows.forEach((row, i) => {
    const y = 1.05 + i * 1.1;
    slide.addShape(deck.ShapeType.roundRect, {
      x: 0.72,
      y,
      w: 11.85,
      h: 0.84,
      rectRadius: 0.05,
      fill: { color: i % 2 ? C.pale : C.white },
      line: { color: C.line, width: 1 },
    });
    addPill(slide, row[0], 0.92, y + 0.25, 1.55, row[3]);
    slide.addText(row[1], {
      x: 2.75,
      y: y + 0.2,
      w: 3.65,
      h: 0.28,
      fontSize: 12,
      bold: true,
      color: C.ink,
      margin: 0,
    });
    slide.addText(row[2], {
      x: 6.45,
      y: y + 0.2,
      w: 5.6,
      h: 0.28,
      fontSize: 12,
      italic: true,
      color: C.muted,
      margin: 0,
    });
  });
  addFooter(slide);
}

// 7. Page walkthrough section
addSectionSlide(
  1,
  "Page-by-page walkthrough",
  "Read every page in five layers: purpose, reading order, diagnostic question, action, and guardrail.",
);

const pages = [
  {
    number: 1,
    title: "Start Here",
    image: "01-start-here.png",
    purpose: "Route each value, cost, distribution, or setup question to the page with the right evidence.",
    read: "Choose the decision first, then confirm that the required source files and customer inputs are available.",
    diagnose: "Which business question must be answered now, and which page owns that question?",
    interpret: "A page can still be useful when optional organization or consumption inputs are absent.",
    action: "Open one path and verify its source-status notes before quoting any number.",
    guardrail: "Do not treat modeled value, observed credits, allocated cost, and invoice chargeback as interchangeable.",
  },
  {
    number: 2,
    title: "Executive Summary",
    image: "02-executive-summary.png",
    purpose: "Summarize observed activity, modeled value, effective cost, return, and assumption status.",
    read: "Read active users and task volume before modeled hours, value, effective platform cost, and ROI.",
    diagnose: "Are the headline results complete, reconciled, and supported by current customer inputs?",
    interpret: "A favorable return is conditional on time, labor, billing, and price assumptions.",
    action: "Confirm reconciliation and Finance-approved inputs before sharing the headline.",
    guardrail: "Do not present scenario ROI as causality, audited savings, or realized cash return.",
  },
  {
    number: 3,
    title: "Task Categories & Methodology",
    image: "03-task-categories-methodology.png",
    caption: "Current default viewport | scrollable methodology table continues beyond the visible rows",
    purpose: "Show observed work by category and the minute benchmarks that produce modeled value.",
    read: "Read task volume, mapping coverage, scheduled share, and the selected low, mid, or high benchmark.",
    diagnose: "Which categories drive the result, and how much is explained by benchmark choice?",
    interpret: "Minutes saved are published assumptions applied to observed tasks, not measured task duration.",
    action: "Review source citations and the hidden assumptions page before changing a benchmark.",
    guardrail: "Do not compare categories without carrying their task count, effort band, and selected estimate basis.",
  },
  {
    number: 4,
    title: "Methodology & Value Calculator",
    image: "04-methodology-value-calculator.png",
    caption: "Current default viewport | scrollable category table continues beyond the visible rows",
    purpose: "Make the value formula, customer inputs, sensitivity range, and selected adjustments visible.",
    read: "Read baseline value, adjusted value, platform cost, and return together with the selected controls.",
    diagnose: "Which input moves the conclusion most, and is that input approved by its business owner?",
    interpret: "Low, mid, and high outputs are assumption scenarios, not statistical confidence intervals.",
    action: "Record the estimate basis, labor rate, adjustments, billing mode, and price inputs with every result.",
    guardrail: "Do not share a dollar result without its period, filters, evidence label, and assumption set.",
  },
  {
    number: 5,
    title: "Action Assumptions",
    image: "05-action-assumptions.png",
    hidden: true,
    caption: "Hidden operational page | current 44-action assumption catalog",
    purpose: "Maintain the action taxonomy, benchmark minutes, evidence citations, and representative mappings.",
    read: "Review action name, category, effort band, low-mid-high estimates, and source citation as one record.",
    diagnose: "Does each valued action have a defensible category, estimate, source, and mapping confidence?",
    interpret: "Changes affect modeled hours, value, net value, and ROI across every visible page.",
    action: "Document and approve changes before exporting or presenting affected results.",
    guardrail: "Do not assign value to ambiguous or unclassified records merely to increase coverage.",
  },
  {
    number: 6,
    title: "Value vs Cost",
    image: "06-value-vs-cost.png",
    caption: "Current default viewport | scrollable detail and interpretation panels continue in the report",
    purpose: "Compare modeled value with customer-priced observed consumption under the selected billing mode.",
    read: "Confirm billing mode and required inputs before adjusted value, effective cost, net value, and ROI.",
    diagnose: "Does the conclusion hold when the cost basis and value assumptions are changed?",
    interpret: "Positioning is scenario-based; cost is not an invoice unless backed by matching billing records.",
    action: "Re-run with Finance-approved terms and inspect band-level outliers before making a decision.",
    guardrail: "Do not infer productivity or causality from a favorable value-to-cost ratio.",
  },
  {
    number: 7,
    title: "Value by Department",
    image: "07-value-by-department.png",
    caption: "Current default viewport | scrollable department table continues beyond the visible rows",
    purpose: "Distribute observed tasks, credits, modeled value, and allocated cost across business units.",
    read: "Check organization-match coverage before comparing tasks, value, credits, and cost separately.",
    diagnose: "Are differences driven by work mix, population size, consumption, or incomplete identity matching?",
    interpret: "Department cost follows the documented allocation rule and is not a ledger charge.",
    action: "Reconcile ownership and identity coverage with the authorized organization-data owner.",
    guardrail: "Do not rank departments without population, role, seasonality, and work-category context.",
  },
  {
    number: 8,
    title: "Value by User Tier",
    image: "08-value-by-user-tier.png",
    purpose: "Show how task activity, assisted time, and modeled value concentrate across active users.",
    read: "Read tier population, task share, modeled value share, and user detail together.",
    diagnose: "Does concentration reflect champions, dependency, uneven enablement, or a filtered population effect?",
    interpret: "Percentile tiers require at least 20 active users and are relative to the current filter context.",
    action: "Pair the tier with role, department, work category, and seasonality before targeting enablement.",
    guardrail: "Tiers are not employee-performance ratings and must not be used for personnel action.",
  },
  {
    number: 9,
    title: "Right-Sizing & Reclaim",
    image: "09-right-sizing-reclaim.png",
    caption: "Current default viewport | scrollable user table continues beyond the visible rows",
    purpose: "Identify near-limit, over-limit, inactive, and under-utilizing usage patterns for review.",
    read: "Read observed credits, allowance, activity recency, and budget segment within the same period.",
    diagnose: "Is the pattern explained by role, leave, seasonality, contract terms, or stale data?",
    interpret: "A budget or recency flag is a review prompt, not an automatic license decision.",
    action: "Confirm manager context and customer terms before changing access, allowance, or assignment.",
    guardrail: "Reclaim dollars remain unavailable without source-backed assignment and customer seat-price data.",
  },
  {
    number: 10,
    title: "Skills & Allocated Consumption",
    image: "10-skills-allocated-consumption.png",
    purpose: "Connect observed skill volume with a directional allocation of credits, cost, and classified value.",
    read: "Read invocation count and friendly skill label first, then mapping coverage and allocated outputs.",
    diagnose: "Which skills are observed most, and how much of their activity has a defensible value classification?",
    interpret: "Friendly labels improve readability; they do not change mapping, category, or value treatment.",
    action: "Use observed skill volume for enablement; use allocated consumption only as directional planning context.",
    guardrail: "The source does not meter credits or value per skill, so repeated parent values must not be summed.",
  },
  {
    number: 11,
    title: "Model & LLM Breakdown",
    image: "11-model-llm-breakdown.png",
    purpose: "Show source-attributed model activity and the directional allocation that follows from task share.",
    read: "Confirm model names are present in Purview before reading allocated cost, credits, or efficiency.",
    diagnose: "Is the model label source-backed, and is there model-specific metering for the decision?",
    interpret: "Allocated cost and efficiency cannot prove that one model is cheaper or more productive.",
    action: "Obtain source-backed per-model metering before making model selection or cost recommendations.",
    guardrail: "If model data is unavailable, stop; do not infer or fabricate a model label.",
  },
  {
    number: 12,
    title: "Glossary",
    image: "12-glossary.png",
    purpose: "Define each metric and disclose its evidence label, source dependency, calculation, and limitation.",
    read: "Use the definition and data status together; unavailable does not mean zero.",
    diagnose: "Can a reviewer reproduce the metric from the listed source and calculation?",
    interpret: "Modeled and allocated results must travel with their assumptions and allocation basis.",
    action: "Copy the definition, period, filters, evidence label, and selected inputs into the decision record.",
    guardrail: "Do not rename a metric in a way that overstates what the source evidence proves.",
  },
];
pages.forEach(addPageSlide);

// 20. Methodology section
addSectionSlide(
  2,
  "Methodology and operating controls",
  "Understand the formulas, billing modes, allocation rules, source checks, and documentation required behind the visuals.",
);

// 21. Value methodology
{
  const slide = deck.addSlide("CONTENT");
  addTitle(slide, "Methodology | Modeled value", "Observed task volume multiplied by explicit, customer-reviewable assumptions");
  slide.addShape(deck.ShapeType.roundRect, {
    x: 0.72,
    y: 1.18,
    w: 11.9,
    h: 1.12,
    rectRadius: 0.08,
    fill: { color: C.pale },
    line: { color: C.violet, width: 1.2 },
  });
  slide.addText("Assisted hours = sum(category task threads x selected category minutes saved) / 60", {
    x: 1.0,
    y: 1.48,
    w: 11.3,
    h: 0.28,
    fontFace: "Consolas",
    fontSize: 16,
    bold: true,
    color: C.plum,
    align: "center",
    margin: 0,
  });
  slide.addText("Estimated value = assisted hours x loaded labor rate", {
    x: 1.0,
    y: 1.84,
    w: 11.3,
    h: 0.24,
    fontFace: "Consolas",
    fontSize: 15,
    color: C.plum,
    align: "center",
    margin: 0,
  });
  const cards = [
    ["Observed", "Task threads and category assignment from approved source evidence.", C.green],
    ["Selected", "Low, mid, or high minutes-saved benchmark for each category.", C.blue],
    ["Customer input", "Loaded labor rate and optional reinvestment, quality, or skill adjustments.", C.orange],
    ["Output", "A scenario estimate whose value changes when the assumptions change.", C.purple],
  ];
  cards.forEach((card, i) => {
    const x = 0.72 + (i % 2) * 6.05;
    const y = 2.75 + Math.floor(i / 2) * 1.65;
    addCard(slide, card[0], card[1], x, y, 5.62, 1.32, card[2], i % 2 ? C.paleBlue : C.pale);
  });
  addWideCallout(
    slide,
    "Language",
    "Say 'under the selected assumptions' and carry the estimate basis, labor rate, period, and filters with the result.",
    0.72,
    6.1,
    11.9,
    0.78,
    C.teal,
    C.paleTeal,
  );
  addFooter(slide);
}

// 22. Billing methodology
{
  const slide = deck.addSlide("CONTENT");
  addTitle(slide, "Methodology | Billing and allocation", "Five planning modes keep value, cost, and consumption concepts separate");
  const modes = [
    ["Credit-Priced", "Observed credits x customer credit price", C.purple],
    ["License-Included", "Customer seat price or contracted cost", C.blue],
    ["Prepaid", "Committed amount within the selected period", C.teal],
    ["Hybrid", "Base commitment plus qualified overage", C.orange],
    ["Monthly Committed", "Monthly commitment compared with observed use", C.violet],
  ];
  modes.forEach((mode, i) => {
    const y = 1.0 + i * 0.9;
    slide.addShape(deck.ShapeType.roundRect, {
      x: 0.68,
      y,
      w: 7.3,
      h: 0.68,
      rectRadius: 0.05,
      fill: { color: i % 2 ? C.paleBlue : C.pale },
      line: { color: C.line, width: 1 },
    });
    addPill(slide, mode[0], 0.88, y + 0.18, 1.55, mode[2]);
    slide.addText(mode[1], {
      x: 2.72,
      y: y + 0.18,
      w: 4.9,
      h: 0.23,
      fontSize: 11,
      color: C.ink,
      margin: 0,
    });
  });
  addCard(
    slide,
    "Observed",
    "Credits used, active users, activity recency, task threads, and source attributes when available.",
    8.35,
    1.0,
    4.25,
    1.42,
    C.green,
    C.paleTeal,
  );
  addCard(
    slide,
    "Modeled",
    "Assisted hours, estimated value, adjusted value, return, and forecast outputs.",
    8.35,
    2.65,
    4.25,
    1.42,
    C.purple,
    C.pale,
  );
  addCard(
    slide,
    "Allocated",
    "Department, skill, or model cost distributed by a documented rule without direct source metering.",
    8.35,
    4.3,
    4.25,
    1.42,
    C.orange,
    C.paleOrange,
  );
  addWideCallout(
    slide,
    "Boundary",
    "Allocation supports planning and showback. It is not an invoice, ledger charge, or source-measured chargeback unless the source explicitly supplies that evidence.",
    0.68,
    5.75,
    7.3,
    0.98,
    C.red,
    C.paleOrange,
  );
  addFooter(slide);
}

// 23. Data pipeline
{
  const slide = deck.addSlide("CONTENT");
  addTitle(slide, "Data pipeline | Inputs and validation", "Local and SharePoint editions use the same logical contract");
  const steps = [
    ["1", "Collect", "Export approved Purview activity plus any optional usage, organization, and consumption files.", C.purple],
    ["2", "Place", "Use one protected local folder or the configured SharePoint folder path.", C.blue],
    ["3", "Refresh", "Confirm source discovery, schema compatibility, and freshness before reading KPIs.", C.teal],
    ["4", "Reconcile", "Compare task, user, credit, and identity totals against the source exports.", C.orange],
    ["5", "Document", "Record period, filters, assumptions, unavailable dependencies, and the output owner.", C.violet],
  ];
  steps.forEach((step, i) => {
    const y = 0.98 + i * 1.05;
    slide.addShape(deck.ShapeType.roundRect, {
      x: 0.72,
      y,
      w: 11.9,
      h: 0.82,
      rectRadius: 0.05,
      fill: { color: i % 2 ? C.paleBlue : C.pale },
      line: { color: C.line, width: 1 },
    });
    slide.addShape(deck.ShapeType.ellipse, {
      x: 0.94,
      y: y + 0.14,
      w: 0.54,
      h: 0.54,
      fill: { color: step[3] },
      line: { color: step[3] },
    });
    slide.addText(step[0], {
      x: 0.94,
      y: y + 0.28,
      w: 0.54,
      h: 0.14,
      fontSize: 11,
      bold: true,
      color: C.white,
      align: "center",
      margin: 0,
    });
    slide.addText(step[1], {
      x: 1.72,
      y: y + 0.18,
      w: 1.5,
      h: 0.22,
      fontSize: 13,
      bold: true,
      color: step[3],
      margin: 0,
    });
    slide.addText(step[2], {
      x: 3.18,
      y: y + 0.17,
      w: 8.95,
      h: 0.32,
      fontSize: 11.2,
      color: C.ink,
      margin: 0,
      fit: "shrink",
    });
  });
  addWideCallout(
    slide,
    "Security",
    "Keep customer exports in approved protected storage. Review every screenshot, video, PDF, and export for identifiers before sharing.",
    0.72,
    6.05,
    11.9,
    0.78,
    C.red,
    C.paleOrange,
  );
  addFooter(slide);
}

// 24. Decision language
{
  const slide = deck.addSlide("CONTENT");
  addTitle(slide, "Defensible decision language", "End with the evidence, the boundary, and an owned next step");
  const examples = [
    ["Value", "\"Under the selected category-minute and labor-rate assumptions, the observed task volume models to...\"", C.purple],
    ["Cost", "\"Using the selected billing mode and customer-approved price inputs, effective platform cost is...\"", C.blue],
    ["Allocation", "\"The directional allocation suggests concentration in..., but source metering is not available at this grain.\"", C.orange],
    ["Right-sizing", "\"The current period flags this account for review; role, leave, seasonality, and contract terms still require validation.\"", C.teal],
  ];
  examples.forEach((example, i) => {
    const y = 1.1 + i * 1.25;
    slide.addShape(deck.ShapeType.roundRect, {
      x: 0.72,
      y,
      w: 11.9,
      h: 0.96,
      rectRadius: 0.06,
      fill: { color: i % 2 ? C.paleBlue : C.pale },
      line: { color: C.line, width: 1 },
    });
    addPill(slide, example[0].toUpperCase(), 0.95, y + 0.3, 1.38, example[2]);
    slide.addText(example[1], {
      x: 2.65,
      y: y + 0.21,
      w: 9.4,
      h: 0.42,
      fontSize: 12.5,
      italic: true,
      color: C.ink,
      margin: 0,
      fit: "shrink",
    });
  });
  slide.addShape(deck.ShapeType.roundRect, {
    x: 0.72,
    y: 6.08,
    w: 11.9,
    h: 0.78,
    rectRadius: 0.06,
    fill: { color: C.plum },
    line: { color: C.plum },
  });
  slide.addText("Decision record minimum: metric definition | evidence label | period | filters | assumptions | owner | next validation step", {
    x: 1.02,
    y: 6.33,
    w: 11.3,
    h: 0.22,
    fontSize: 13,
    bold: true,
    color: C.white,
    align: "center",
    margin: 0,
  });
  addFooter(slide, "In Testing | Decision support, not billing or personnel evidence");
}

(async () => {
  await deck.writeFile({ fileName: output });
})();
