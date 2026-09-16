const pptxgen = require("pptxgenjs");
const path = require("path");

const deck = new pptxgen();
deck.layout = "LAYOUT_WIDE";
deck.author = "Microsoft Scout";
deck.company = "Microsoft";
deck.subject = "Cowork Value Intelligence interpretation storyboard";
deck.title = "Cowork Value Intelligence - Interpretation Storyboard";
deck.lang = "en-US";
deck.theme = { headFontFace: "Aptos Display", bodyFontFace: "Aptos", lang: "en-US" };

const root = path.resolve(__dirname, "..");
const images = path.join(root, "images", "report-pages");
const output = path.join(root, "Cowork Value Intelligence V1.0 In Testing - Interpretation Storyboard.pptx");

const C = {
  plum: "2B174D",
  purple: "4B2D83",
  violet: "7551A8",
  magenta: "D83B96",
  teal: "008272",
  blue: "0078D4",
  orange: "D83B01",
  green: "107C10",
  ink: "202033",
  muted: "625B6A",
  line: "D8CEE8",
  pale: "F7F5FA",
  paleBlue: "EEF5FC",
  paleTeal: "EAF8F7",
  white: "FFFFFF",
};

deck.defineSlideMaster({
  title: "CONTENT",
  background: { color: C.white },
  objects: [
    { rect: { x: 0, y: 0, w: 13.333, h: 0.16, fill: { color: C.purple }, line: { color: C.purple } } },
  ],
  slideNumber: { x: 12.55, y: 7.16, w: 0.35, h: 0.15, fontFace: "Aptos", fontSize: 7, color: C.muted, align: "right", margin: 0 },
});

function addFooter(slide, label = "Version 1.0 | In Testing | Fabricated sample data") {
  slide.addText("llorenz28/cowork-value-intelligence", {
    x: 0.45, y: 7.16, w: 4.7, h: 0.16, fontFace: "Aptos", fontSize: 6.8, color: C.muted, margin: 0,
  });
  slide.addText(label, {
    x: 7.1, y: 7.16, w: 5.1, h: 0.16, fontFace: "Aptos", fontSize: 6.8, color: C.muted, align: "right", margin: 0,
  });
}

function addTitle(slide, title, subtitle) {
  slide.addText(title, {
    x: 0.5, y: 0.33, w: 8.2, h: 0.4, fontFace: "Aptos Display", fontSize: 24, bold: true, color: C.plum, margin: 0,
  });
  slide.addText(subtitle, {
    x: 8.75, y: 0.41, w: 4.05, h: 0.22, fontFace: "Aptos", fontSize: 8.5, color: C.muted, align: "right", margin: 0,
  });
  slide.addShape(deck.ShapeType.line, { x: 0.5, y: 0.8, w: 12.3, h: 0, line: { color: C.line, width: 1 } });
}

function addPill(slide, text, x, y, w, color) {
  slide.addShape(deck.ShapeType.roundRect, { x, y, w, h: 0.32, rectRadius: 0.08, fill: { color }, line: { color } });
  slide.addText(text, { x: x + 0.05, y: y + 0.075, w: w - 0.1, h: 0.12, fontSize: 8, bold: true, color: C.white, align: "center", margin: 0 });
}

function addCallout(slide, label, text, x, y, w, h, color) {
  slide.addShape(deck.ShapeType.roundRect, {
    x, y, w, h, rectRadius: 0.08, fill: { color: C.white }, line: { color: C.line, width: 1.1 },
  });
  slide.addShape(deck.ShapeType.ellipse, { x: x + 0.13, y: y + 0.13, w: 0.34, h: 0.34, fill: { color }, line: { color } });
  slide.addText(label.slice(0, 1), {
    x: x + 0.13, y: y + 0.205, w: 0.34, h: 0.1, fontSize: 7.5, bold: true, color: C.white, align: "center", margin: 0,
  });
  slide.addText(label.toUpperCase(), {
    x: x + 0.56, y: y + 0.15, w: w - 0.72, h: 0.18, fontSize: 7.2, bold: true, color, margin: 0,
  });
  slide.addText(text, {
    x: x + 0.16, y: y + 0.55, w: w - 0.32, h: h - 0.68, fontSize: 9, color: C.ink, margin: 0, fit: "shrink", valign: "top",
  });
}

function addActionCallout(slide, text, x, y, w, color) {
  slide.addShape(deck.ShapeType.roundRect, {
    x, y, w, h: 0.74, rectRadius: 0.08, fill: { color: C.white }, line: { color: C.line, width: 1.1 },
  });
  slide.addShape(deck.ShapeType.ellipse, { x: x + 0.13, y: y + 0.2, w: 0.34, h: 0.34, fill: { color }, line: { color } });
  slide.addText("A", {
    x: x + 0.13, y: y + 0.275, w: 0.34, h: 0.1, fontSize: 7.5, bold: true, color: C.white, align: "center", margin: 0,
  });
  slide.addText("ACTION", {
    x: x + 0.56, y: y + 0.17, w: 0.72, h: 0.16, fontSize: 7.2, bold: true, color, margin: 0,
  });
  slide.addText(text, {
    x: x + 1.4, y: y + 0.15, w: w - 1.58, h: 0.28, fontSize: 9.3, color: C.ink, margin: 0, fit: "shrink", valign: "mid",
  });
}

function addImageFrame(slide, file, x, y, w, h, caption = "Actual Power BI capture • deterministic synthetic data") {
  slide.addShape(deck.ShapeType.roundRect, {
    x: x - 0.05, y: y - 0.05, w: w + 0.1, h: h + 0.1, rectRadius: 0.05,
    fill: { color: "F0EBF7" }, line: { color: C.violet, width: 1.2 },
  });
  slide.addImage({ path: path.join(images, file), x, y, w, h });
  if (caption) {
    slide.addText(caption, {
      x, y: y + h + 0.07, w, h: 0.16, fontSize: 7.2, italic: true, color: C.muted, align: "center", margin: 0,
    });
  }
}

function addPageSlide(page) {
  const slide = deck.addSlide("CONTENT");
  addTitle(slide, page.title, `${page.number} of 13 report pages`);
  addImageFrame(slide, page.image, 5.22, 1.04, 7.55, 4.53, page.caption);
  addCallout(slide, "Purpose", page.purpose, 0.5, 1.04, 4.4, 1.25, C.purple);
  addCallout(slide, "Read", page.read, 0.5, 2.47, 4.4, 1.25, C.blue);
  addCallout(slide, "Interpret", page.interpret, 0.5, 3.9, 4.4, 1.25, C.orange);
  if (page.notice) {
    addPill(slide, page.notice, 8.15, 5.58, 4.62, C.orange);
  }
  addActionCallout(slide, page.action, 0.5, 5.92, 12.27, C.teal);
  addFooter(slide);
}

// Cover
{
  const slide = deck.addSlide();
  slide.background = { color: C.white };
  slide.addShape(deck.ShapeType.rect, { x: 0, y: 0, w: 5.15, h: 7.5, fill: { color: C.plum }, line: { color: C.plum } });
  addPill(slide, "VERSION 1.0 • IN TESTING", 0.7, 0.72, 2.7, C.magenta);
  slide.addText("Cowork\nValue Intelligence", {
    x: 0.7, y: 1.45, w: 3.9, h: 1.55, fontFace: "Aptos Display", fontSize: 34, bold: true, color: C.white, margin: 0, breakLine: false,
  });
  slide.addText("Interpretation Storyboard", {
    x: 0.7, y: 3.28, w: 3.9, h: 0.42, fontSize: 20, bold: true, color: "EEE9F7", margin: 0,
  });
  slide.addText("A page-by-page guide to adoption, delegated work, modeled value, consumption, and evidence-aware action.", {
    x: 0.7, y: 3.92, w: 3.75, h: 1.1, fontSize: 16, color: "EEE9F7", margin: 0, fit: "shrink",
  });
  slide.addText("Fabricated sample data • @example.com identities", {
    x: 0.7, y: 6.6, w: 3.9, h: 0.22, fontSize: 9, color: "C9BEE0", margin: 0,
  });
  addImageFrame(slide, "02-executive-summary.png", 5.72, 1.34, 7.0, 4.2);
  slide.addText("Observed signals. Transparent assumptions. Defensible decisions.", {
    x: 5.72, y: 5.95, w: 7.0, h: 0.42, fontFace: "Aptos Display", fontSize: 20, bold: true, color: C.plum, align: "center", margin: 0,
  });
}

// How to use
{
  const slide = deck.addSlide("CONTENT");
  addTitle(slide, "Use the same four-question reading path", "Interpretation before action");
  const cards = [
    ["1", "PURPOSE", "Start with the business decision the page is designed to support.", C.purple],
    ["2", "READ", "Confirm the filters, reporting period, source status, and metric grain.", C.blue],
    ["3", "INTERPRET", "Separate observed evidence from modeled or allocated values.", C.orange],
    ["4", "ACTION", "Corroborate the source record and document the owner before acting.", C.teal],
  ];
  cards.forEach((card, i) => {
    const x = 0.6 + (i % 2) * 6.2;
    const y = 1.2 + Math.floor(i / 2) * 2.65;
    slide.addShape(deck.ShapeType.roundRect, { x, y, w: 5.75, h: 2.15, rectRadius: 0.08, fill: { color: i % 2 ? C.paleBlue : C.pale }, line: { color: C.line, width: 1.2 } });
    slide.addShape(deck.ShapeType.ellipse, { x: x + 0.3, y: y + 0.32, w: 0.58, h: 0.58, fill: { color: card[3] }, line: { color: card[3] } });
    slide.addText(card[0], { x: x + 0.3, y: y + 0.46, w: 0.58, h: 0.16, fontSize: 12, bold: true, color: C.white, align: "center", margin: 0 });
    slide.addText(card[1], { x: x + 1.08, y: y + 0.34, w: 3.8, h: 0.25, fontSize: 10, bold: true, color: card[3], margin: 0 });
    slide.addText(card[2], { x: x + 1.08, y: y + 0.78, w: 4.2, h: 0.8, fontSize: 14, color: C.ink, margin: 0, fit: "shrink" });
  });
  addFooter(slide);
}

// Confidence and sources
{
  const slide = deck.addSlide("CONTENT");
  addTitle(slide, "Different evidence requires different wording", "Confidence ladder");
  const rows = [
    ["OBSERVED", "Direct source count", "The connected export contains…", C.green],
    ["DERIVED", "Arithmetic over observed fields", "The report calculates…", C.blue],
    ["MODELED", "Observed activity plus assumptions", "Under the selected assumptions…", C.purple],
    ["ALLOCATED", "A total distributed without source metering", "The modeled allocation suggests…", C.orange],
    ["UNAVAILABLE", "A required dependency is absent", "This cannot be calculated yet.", "A80000"],
  ];
  rows.forEach((row, i) => {
    const y = 1.08 + i * 1.08;
    slide.addShape(deck.ShapeType.roundRect, { x: 0.72, y, w: 11.85, h: 0.82, rectRadius: 0.05, fill: { color: i % 2 ? C.pale : C.white }, line: { color: C.line, width: 1 } });
    addPill(slide, row[0], 0.92, y + 0.24, 1.55, row[3]);
    slide.addText(row[1], { x: 2.75, y: y + 0.18, w: 3.65, h: 0.28, fontSize: 12, bold: true, color: C.ink, margin: 0 });
    slide.addText(row[2], { x: 6.45, y: y + 0.18, w: 5.6, h: 0.28, fontSize: 12, italic: true, color: C.muted, margin: 0 });
  });
  addFooter(slide);
}

{
  const slide = deck.addSlide("CONTENT");
  addTitle(slide, "Four source contracts, one evidence chain", "Customer-owned inputs");
  const sources = [
    ["Purview audit", "Threads, timestamps, skills, resources, optional model attribution", C.purple],
    ["Cowork usage", "Reported tasks, scheduled split, active days, reconciliation", C.blue],
    ["Organization", "Department, business unit, manager, role, geography", C.teal],
    ["Consumption", "Credit allowance, credits used, sessions, and recency", C.orange],
  ];
  sources.forEach((source, i) => {
    const x = 0.72 + i * 3.1;
    slide.addShape(deck.ShapeType.roundRect, { x, y: 1.4, w: 2.65, h: 3.6, rectRadius: 0.08, fill: { color: i % 2 ? C.paleBlue : C.pale }, line: { color: source[2], width: 1.5 } });
    slide.addShape(deck.ShapeType.ellipse, { x: x + 0.88, y: 1.8, w: 0.9, h: 0.9, fill: { color: source[2] }, line: { color: source[2] } });
    slide.addText(String(i + 1), { x: x + 0.88, y: 2.04, w: 0.9, h: 0.2, fontSize: 16, bold: true, color: C.white, align: "center", margin: 0 });
    slide.addText(source[0], { x: x + 0.25, y: 2.95, w: 2.15, h: 0.42, fontSize: 17, bold: true, color: C.plum, align: "center", margin: 0 });
    slide.addText(source[1], { x: x + 0.25, y: 3.55, w: 2.15, h: 1.0, fontSize: 11.5, color: C.ink, align: "center", margin: 0, fit: "shrink" });
  });
  slide.addText("The usage export is aggregate evidence. It must never manufacture an event timeline.", {
    x: 1.3, y: 5.55, w: 10.7, h: 0.55, fontSize: 16, bold: true, color: C.orange, align: "center", margin: 0,
  });
  addFooter(slide);
}

const pages = [
  { number: 1, title: "Start Here", image: "01-start-here.png", purpose: "Route each business question to the page with the right evidence.", read: "Choose the decision first: adoption, audience, cost, ROI, work mix, or next action.", interpret: "A page can be useful even when optional billing or organization inputs are absent.", action: "Open one path and verify its data-status notes before quoting a number." },
  { number: 2, title: "Executive Summary", image: "02-executive-summary.png", purpose: "Summarize adoption, delegated work, modeled value, cost, and work mix.", read: "Read observed users and tasks before scenario-based value and ROI.", interpret: "A favorable ROI is conditional on labor rate, billing model, and credit price.", action: "Confirm reconciliation and Finance-approved inputs before sharing the headline." },
  { number: 3, title: "Activity & Value", image: "03-activity-value.png", purpose: "Show which skills and departments contribute to modeled value.", read: "Skill invocations are observed; hours and dollars combine activity with assumptions.", interpret: "High volume shows embedded workflows; high value reflects the selected time-saving assumptions.", action: "Validate organization mappings and compare low, mid, and high labor-rate scenarios." },
  { number: 4, title: "Actions", image: "04-actions.png", purpose: "Explain what Cowork did by skill, category, and value tier.", read: "Skill activity and category value use different grains; do not sum repeated category value across skills.", interpret: "A broader skill mix can signal workflow maturity, but unmapped tools need review.", action: "Review unmapped skills first, then use category and tier views for rollups." },
  { number: 5, title: "How Far They Delegate", image: "05-how-far-they-delegate.png", purpose: "Describe task depth, elapsed duration, steps, and skill chaining.", read: "Duration is first-to-last audit event time, not measured human attention.", interpret: "Longer or multi-skill threads can show complex delegation or process friction.", action: "Sample the underlying thread and confirm business purpose before calling it autonomous." },
  { number: 6, title: "Value vs Cost", image: "06-value-vs-cost.png", purpose: "Compare modeled value with customer-priced observed consumption.", read: "Value is modeled; credits are observed; cost and ROI require selected contract inputs.", interpret: "Position above the diagonal is favorable only under the current assumptions.", action: "Re-run with Finance-approved terms and inspect user-level outliers." },
  { number: 7, title: "Methodology & Value Calculator", image: "07-methodology-value-calculator.png", purpose: "Make the value formula and every adjustable input visible.", read: "Observed tasks × typical minutes ÷ 60 × labor rate produces baseline value.", interpret: "The low-to-high range is assumption sensitivity, not statistical confidence.", action: "Export the assumptions, period, filters, and formula with every value result." },
  { number: 8, title: "Consumption & Forecast", image: "08-consumption-forecast.png", purpose: "Estimate month-end credit consumption and commitment fit.", read: "The projection is a straight line from observed credits and elapsed days.", interpret: "A positive gap suggests overage; a negative gap suggests under-utilization.", action: "Check freshness and seasonality before changing a commitment." },
  { number: 9, title: "BU Showback", image: "09-bu-showback.png", purpose: "Attribute consumption and modeled value to business units.", read: "Organization comes from the customer export; allocated cost follows the selected policy.", interpret: "Allocation is not invoice metering and should not be treated as a chargeback by default.", action: "Confirm cost-center ownership and allocation policy with Finance." },
  { number: 10, title: "Value by User Tier", image: "10-value-by-user-tier.png", purpose: "Show how concentrated tasks and modeled value are across users.", read: "Percentile tiers require at least 20 users; the synthetic sample supports the split.", interpret: "Concentration can identify champions, dependency, or uneven enablement.", action: "Pair tiers with business unit and work category before targeting action." },
  { number: 11, title: "Right-Sizing & Reclaim", image: "11-right-sizing-reclaim.png", caption: null, notice: "EXPECTED BLANK • LICENSE PRICE REQUIRED", purpose: "Identify utilization, recency, and budget exceptions.", read: "Near-limit and over-limit use observed consumption; reclaim dollars need license price.", interpret: "Low activity is a follow-up signal, not an automatic removal decision.", action: "Confirm role, leave, seasonality, and license terms before changing access." },
  { number: 12, title: "Model & LLM Breakdown", image: "12-model-llm-breakdown.png", purpose: "Show source-attributed model activity and modeled efficiency by category.", read: "Model labels are observed; current cost and credits are allocated estimates.", interpret: "The page cannot yet prove that one model is cheaper without model-specific metering.", action: "Add compatible per-model credit and duration evidence before recommending a model." },
  { number: 13, title: "Glossary", image: "13-glossary.png", purpose: "Define each metric and disclose its ownership and availability.", read: "Use the definition and data status together; unavailable does not mean zero.", interpret: "Modeled and allocated metrics need their assumptions when shared.", action: "Copy the definition, period, filters, and confidence label into decision records." },
];
pages.forEach(addPageSlide);

(async () => {
  await deck.writeFile({ fileName: output });
})();
