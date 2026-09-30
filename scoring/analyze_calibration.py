import json, re, glob, sys
from collections import defaultdict

CRITERIA = json.load(open("scoring/judge_criteria.json"))["criteria"]
CRIT_IDS = [c["id"] for c in CRITERIA]

# One quantitative-test mutant per ORACLE=JUDGE criterion it's a labelled
# positive for. MUT-L23 is a positive for both L23 and C18 (documented
# overlap in judge_criteria.json).
MUTANT_TARGET = {
    "MUT-L23": ["L23", "C18"],
    "MUT-C04": ["C04"], "MUT-C08": ["C08"], "MUT-C13": ["C13"],
    "MUT-L06": ["L06"], "MUT-L08": ["L08"], "MUT-L09": ["L09"],
    "MUT-L10": ["L10"], "MUT-L12": ["L12"], "MUT-L21": ["L21"],
    "MUT-L27": ["L27"],
}
# The other 9 ledger mutants (R01, R02, L30, L31, L29, C01, C03, L28, C16)
# are ORACLE=STATIC, not judge-relevant -- excluded from the quantitative
# decision rule, reported separately as a specificity check only (the judge
# should not invent NON_COMPLIANT verdicts on judge criteria just because
# something unrelated changed in the tree).
STATIC_ONLY_MUTANTS = ["MUT-R01", "MUT-R02", "MUT-L30", "MUT-L31", "MUT-L29",
                       "MUT-C01", "MUT-C03", "MUT-L28", "MUT-C16"]

def extract_json(result_text):
    """The judge doesn't always emit pure JSON despite instructions -- strip
    markdown fences and any preamble/trailing prose, extracting the outermost
    [...] array."""
    text = result_text.strip()
    # strip ```json ... ``` or ``` ... ``` fences if present
    fence = re.search(r"```(?:json)?\s*(\[.*\])\s*```", text, re.DOTALL)
    if fence:
        text = fence.group(1)
    else:
        start = text.find("[")
        end = text.rfind("]")
        if start != -1 and end != -1 and end > start:
            text = text[start:end+1]
    return json.loads(text)

def load_verdicts(label, rep):
    path = f"calibration/judge_results/{label}/rep{rep}.json"
    import os
    if not os.path.exists(path):
        return None, "NO_DATA (never judged, or removed as invalid)"
    try:
        raw = json.load(open(path))
    except Exception as e:
        return None, f"CORRUPT_FILE: {e}"
    if raw.get("is_error"):
        # A harness-level failure (rate limit, etc.), not a judge verdict.
        # Must be excluded from every rate calculation, never counted as a
        # missed detection -- conflating the two produced a false "25%
        # detection, NOT USABLE" result during a weekly usage-limit window.
        return None, f"HARNESS_ERROR: {raw.get('result','')[:80]!r}"
    try:
        verdicts = extract_json(raw["result"])
    except Exception as e:
        return None, f"PARSE_FAIL: {e}"
    by_id = {v["id"]: v["verdict"] for v in verdicts if "id" in v and "verdict" in v}
    missing = set(CRIT_IDS) - set(by_id)
    if missing:
        return by_id, f"MISSING_IDS: {missing}"
    return by_id, None

LABELS = ["control"] + list(MUTANT_TARGET) + STATIC_ONLY_MUTANTS
all_verdicts = {}  # label -> rep -> {id: verdict}
parse_issues = []
for label in LABELS:
    all_verdicts[label] = {}
    for rep in [1, 2, 3]:
        by_id, issue = load_verdicts(label, rep)
        all_verdicts[label][rep] = by_id
        if issue:
            parse_issues.append((label, rep, issue))

print("=== parse issues ===")
for label, rep, issue in parse_issues:
    print(f"  {label} rep{rep}: {issue}")
print(f"  ({len(parse_issues)} issues out of {len(LABELS)*3} calls)\n")

def majority_verdict(label, crit_id):
    votes = [all_verdicts[label][r].get(crit_id) for r in [1,2,3] if all_verdicts[label][r]]
    votes = [v for v in votes if v]
    if not votes:
        return None, 0.0
    from collections import Counter
    c = Counter(votes)
    top, n = c.most_common(1)[0]
    return top, n/len(votes)

print("=== quantitative detection rate (judge-targeted mutants only) ===")
detected = 0
total_mut = 0
no_data = 0
detail = []
for mut, targets in MUTANT_TARGET.items():
    for t in targets:
        verdict, agree = majority_verdict(mut, t)
        if verdict is None:
            no_data += 1
            print(f"  {mut} -> {t}: NO DATA (all replicates errored) -- excluded, not counted as missed")
            continue
        total_mut += 1
        is_detected = (verdict == "NON_COMPLIANT")
        if is_detected:
            detected += 1
        detail.append((mut, t, verdict, agree, is_detected))
        print(f"  {mut} -> {t}: majority verdict={verdict} (agreement={agree:.2f})  {'DETECTED' if is_detected else 'missed'}")

if no_data:
    print(f"\n  ({no_data} target(s) excluded for lack of data -- rerun scoring/run_calibration.sh before trusting this rate)")
detection_rate = detected / total_mut if total_mut else float("nan")
print(f"\n  detection rate: {detected}/{total_mut} = {detection_rate:.2%}\n" if total_mut else "\n  detection rate: UNDEFINED (no valid data at all)\n")

print("=== specificity: control (false-positive floor) ===")
fp_ids = []
for crit_id in CRIT_IDS:
    verdict, agree = majority_verdict("control", crit_id)
    marker = " <-- FALSE POSITIVE" if verdict == "NON_COMPLIANT" else ""
    print(f"  {crit_id}: majority={verdict} (agreement={agree:.2f}){marker}")
    if verdict == "NON_COMPLIANT":
        fp_ids.append(crit_id)
fp_rate = len(fp_ids) / len(CRIT_IDS)
print(f"\n  false-positive rate on control: {len(fp_ids)}/{len(CRIT_IDS)} = {fp_rate:.2%}  ({fp_ids})\n")

print("=== specificity check: STATIC-only mutants (should not trip JUDGE criteria) ===")
static_fp_count = 0
static_fp_total = 0
for mut in STATIC_ONLY_MUTANTS:
    spurious = []
    for crit_id in CRIT_IDS:
        verdict, agree = majority_verdict(mut, crit_id)
        static_fp_total += 1
        ctrl_verdict, _ = majority_verdict("control", crit_id)
        if verdict == "NON_COMPLIANT" and ctrl_verdict != "NON_COMPLIANT":
            spurious.append(crit_id)
            static_fp_count += 1
    print(f"  {mut}: spurious NEW non-compliant vs control = {spurious}")
print(f"\n  spurious rate on STATIC-only mutants: {static_fp_count}/{static_fp_total} = {static_fp_count/static_fp_total:.2%}\n")

print("=== inter-replicate agreement (all trees, all criteria) ===")
agreements = []
for label in LABELS:
    for crit_id in CRIT_IDS:
        verdict, agree = majority_verdict(label, crit_id)
        if verdict is not None:  # skip (tree, criterion) pairs with zero valid replicates
            agreements.append(agree)
mean_agree = sum(agreements) / len(agreements) if agreements else float("nan")
print(f"  mean 3-rep agreement across {len(agreements)} (tree, criterion) pairs with data: {mean_agree:.2%}\n")

print("=== DECISION RULE (pre-registered, §5.1.2) ===")
if no_data:
    print(f"  INCOMPLETE -- {no_data} judge-targeted mutant/criterion pair(s) have zero valid replicates")
    print("  (harness errors, e.g. a usage-limit window -- rerun scoring/run_calibration.sh to fill gaps).")
    print("  Not applying the decision rule on partial data.")
else:
    print(f"  detection rate on judge-targeted mutants: {detection_rate:.2%}  (need >= 50%)")
    print(f"  false-positive rate on control:           {fp_rate:.2%}")
    verdict_usable = detection_rate >= 0.5 and fp_rate <= detection_rate
    print(f"  RESULT: judge is {'USABLE' if verdict_usable else 'NOT USABLE'} per the pre-committed rule")
