#!/usr/bin/env bash
# TIER 2 — the site a bootstrap produces builds, deploys (dry) and serves.
#
# placement.test.sh proves the tree a bootstrap ends with is the right tree.
# This proves it WORKS, by doing to it what its own pipelines will:
#
#   1. at the finished site, the landing's own checks — install with the
#      lockfile the site ships, render fixtures, typecheck, lint, test,
#      build. The bootstrap's own landings are checked in the box with
#      `orun validate` and `orun plan` alone (`checks: local`; their PR's CI
#      on an `orun/BASE-…` branch is `plan` alone, and the convergence on
#      main builds, deploys and smoke-tests the site), so THIS is where a
#      site those steps refuse is caught: before the tag, not after a build
#      has merged it. Every later pull request of the site runs ci.yml's
#      verify lanes;
#   2. the stage lane's own steps, rendered by `orun plan` in the site: on a
#      pull request (the verify profile) `verify-app-structure`, `build-app` —
#      the component's buildCommand (`vuepress build src` through turbo; the
#      site bakes in no origin), the same step the deploy profile runs —
#      `verify-build-output` and `deploy-dry-run` (`wrangler deploy --dry-run
#      --name <reponame>-web-stage`). They run IN THE TREE THE RUNNER STAGES
#      for the job (testing/lib/stage-job.py), with the dependency layout the
#      pinned composition produces: if its install step is `scope: lane`, the
#      top-level node_modules is a symlink to the source checkout's; if not,
#      the job's own install step runs inside the staged tree. The staged build
#      must have written its OWN site — the source tree's src/.vuepress/dist
#      is removed before staging, as a CI checkout has none — an HTML file
#      per page, the 404 page and the scripts and stylesheet the pages name,
#      every page titled with the site's name;
#   3. serve the built Worker with `wrangler dev` and run the component's OWN
#      `smokeCommand` against it, verbatim — the check the real deploy ends
#      with — and then read every address the site promises, each answered as
#      Vercel answers it: the home page with the template's hero, features
#      and navbar, every script and stylesheet it names, the guide at its
#      folder address with or without the slash, its second page and the
#      config reference, each `.html` and `index.html` address served as it
#      is (not redirected), and a missing page, an extension-less page
#      address and a missing chunk each answered with VuePress's 404 page and
#      a 404 status.
#
# What it cannot do is the platform's half: create the repository, mint the
# brokered Cloudflare token, deploy for real and probe workers.dev. That is a
# bootstrap against a workspace (BOOTSTRAP.md); everything short of it is here.
#
# Needs: orun, node, pnpm, python3 (+PyYAML), git, curl, and the network for
# `pnpm install` (or a warm store). A few minutes: two installs and builds
# (the landing's checks over the site, and the stage lane's own in its staged
# tree).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
# shellcheck source=lib/bootstrap.sh
source "$here/lib/bootstrap.sh"

for bin in orun node pnpm python3 git curl; do
  command -v "$bin" >/dev/null || { echo "e2e.test.sh needs $bin on PATH" >&2; exit 1; }
done

scratch="$(mktemp -d)"
dev_pid=""
# wrangler dev runs under pnpm, node and two workerd processes; a TERM to the
# first does not reach the rest, and waiting on it then never returns. So it is
# started as its own process group (setsid) and the whole group is stopped.
cleanup() {
  if [ -n "$dev_pid" ]; then
    kill -TERM -- "-$dev_pid" 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do kill -0 -- "-$dev_pid" 2>/dev/null || break; sleep 0.5; done
    kill -KILL -- "-$dev_pid" 2>/dev/null || true
  fi
  rm -rf "$scratch"
}
trap cleanup EXIT
values="$here/fixtures/acme.json"
repo="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['reponame'])" "$values")"
export CI=1 WRANGLER_SEND_METRICS=false TURBO_TELEMETRY_DISABLED=1

# The landing's own checks, step for step, run here at once on the whole
# tree. A pull request in the site builds and dry-deploys it through ci.yml's
# lanes; the lint and the tests run here, and by hand before a push.
LANDING_CHECKS=(
  "pnpm install --frozen-lockfile"
  "pnpm run wire:fixture"
  "pnpm typecheck"
  "pnpm lint"
  "pnpm test"
  "pnpm build"
)
checks() { # DIR LOG
  local dir="$1" log="$2" cmd
  for cmd in "${LANDING_CHECKS[@]}"; do
    echo "   \$ $cmd" | tee -a "$log"
    if ! (cd "$dir" && bash -c "$cmd") >> "$log" 2>&1; then
      echo "FAIL: \`$cmd\` failed in $dir" >&2; tail -40 "$log" >&2; return 1
    fi
  done
}

echo "── the offline bootstrap (testing/lib/bootstrap.sh)"
tree="$scratch/$repo"
bootstrap_offline "$root" "$tree" "$values" "$scratch/logs" > "$scratch/bootstrap.log" 2>&1 || {
  echo "FAIL: the offline bootstrap stopped" >&2; tail -40 "$scratch/bootstrap.log" >&2; exit 1; }
echo "   2 phases placed and landed"

# ── 1. the finished site ───────────────────────────────────────────────────
echo "── the finished site: install, the fixture render, typecheck, lint, test, build"
checks "$tree" "$scratch/checks-site.log"

# ── 2. the deploy lane's steps, for stage ──────────────────────────────────
echo "── the stage lane: verify-app-structure, build-app, verify-build-output, deploy-dry-run"
# The 01-product landing over the repository's empty first commit: every file
# of the site changed, as on its pull request.
s00="$(git -C "$tree" rev-parse HEAD~2)"; s01="$(git -C "$tree" rev-parse HEAD~1)"
(cd "$tree" && orun plan --intent intent.yaml --trigger github-pull-request --changed \
   --base "$s00" --head "$s01" --env stage --output "$scratch/plan.json") > "$scratch/plan.log" 2>&1 \
  || { echo "FAIL: orun plan" >&2; tail -15 "$scratch/plan.log" >&2; exit 1; }
python3 - "$scratch/plan.json" "$scratch/steps" <<'PY'
import json, pathlib, sys
plan = json.load(open(sys.argv[1]))
out = pathlib.Path(sys.argv[2]); out.mkdir()
job = next(j for j in plan["jobs"] if j["component"] == "web" and j["environment"] == "stage")
for s in job["steps"]:
    if s["id"] in ("verify-app-structure", "build-app", "verify-build-output", "deploy-dry-run"):
        (out / f"{s['id']}.sh").write_text(s.get("run") or "")
    if s["id"] == "install-workspace-dependencies":
        (out / "install.sh").write_text(s.get("run") or "")
        (out / "install.wd").write_text(s.get("working-directory") or ".")
        (out / "install.scope").write_text(s.get("scope") or "job")
(out / "path").write_text(job.get("path") or "apps/web")
for k, v in (job.get("env") or {}).items():
    (out / "env").open("a").write(f"export {k}={json.dumps(v)}\n")
PY
# The job's private tree, staged as orun stages it. The source checkout
# carries no build output (a CI checkout has none, so the plain-tree build's is
# removed rather than copied in), and its dependencies are what the pinned
# composition says: a lane-scoped install ran once in the source tree (step 1
# ran the same command) and is linked in, or the job installs its own.
rm -rf "$tree/apps/web/src/.vuepress/dist" "$tree/apps/web/.wrangler"
work="$tree/.orun/runs/e2e/web.stage.verify-deploy/work"
[ -f "$scratch/steps/install.sh" ] || { echo "FAIL: the stage lane has no install step" >&2; exit 1; }
if [ "$(cat "$scratch/steps/install.scope")" = lane ]; then
  python3 "$here/lib/stage-job.py" "$tree" "$work" --shared-deps
  [ -L "$work/node_modules" ] || { echo "FAIL: the staged tree's node_modules is not the lane's symlink" >&2; exit 1; }
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: lane — node_modules → the source tree's"
else
  python3 "$here/lib/stage-job.py" "$tree" "$work"
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: job — installing inside it"
  echo "   ▸ install-workspace-dependencies"
  (cd "$work/$(cat "$scratch/steps/path")/$(cat "$scratch/steps/install.wd")" && bash -e "$scratch/steps/install.sh") \
    > "$scratch/install.log" 2>&1 || { echo "FAIL: the lane's install step" >&2; tail -30 "$scratch/install.log" >&2; exit 1; }
  [ -d "$work/node_modules" ] && [ ! -L "$work/node_modules" ] \
    || { echo "FAIL: the job's install did not land inside its own tree" >&2; exit 1; }
fi
for step in verify-app-structure build-app verify-build-output deploy-dry-run; do
  [ -f "$scratch/steps/$step.sh" ] || { echo "FAIL: the stage verify lane has no $step step" >&2; exit 1; }
  echo "   ▸ $step"
  # The runner's per-job environment: the job's env (intent environment
  # `env:`) and ORUN_ENVIRONMENT; the step runs in the component's directory.
  if ! (cd "$work/$(cat "$scratch/steps/path")" && \
        { [ -f "$scratch/steps/env" ] && source "$scratch/steps/env"; true; } && \
        export ORUN_ENVIRONMENT=stage && bash -e "$scratch/steps/$step.sh") > "$scratch/$step.log" 2>&1; then
    echo "FAIL: the deploy lane's $step step" >&2; tail -40 "$scratch/$step.log" >&2; exit 1
  fi
done
# What the staged build must have been: vuepress build, writing a site of
# its own (the source tree's was removed): an HTML file per page and the 404
# page, the scripts and stylesheet the pages name — and every page titled
# with the site's own name from .vuepress/config.js, the template's gone.
grep -q 'Generated static files in src/.vuepress/dist' "$scratch/build-app.log" \
  || { echo "FAIL: the staged build is not vuepress build" >&2; tail -20 "$scratch/build-app.log" >&2; exit 1; }
python3 - "$work/apps/web" "$values" <<'PY' || exit 1
import html, json, pathlib, re, sys
app, values = pathlib.Path(sys.argv[1]), json.load(open(sys.argv[2]))
out, name = app / "src/.vuepress/dist", values["productname"]
pages = {"index.html": name, "guide/index.html": f"Introduction | {name}",
         "guide/using-vue.html": f"Using Vue in Markdown | {name}", "config/index.html": f"Config | {name}"}
for page in (*pages, "404.html"):
    if not (out / page).is_file():
        sys.exit(f"FAIL: the staged build did not write src/.vuepress/dist/{page}")
files = set()
for page, want in pages.items():
    text = (out / page).read_text()
    got = html.unescape(re.search(r"<title>([^<]*)</title>", text).group(1))
    if got != want:
        sys.exit(f"FAIL: the staged {page} is titled {got!r}, not {want!r}")
    if "Vuepress Docs Boilerplate" in html.unescape(text):
        sys.exit(f"FAIL: the staged {page} still names the template")
    files |= set(re.findall(r'<script src="/([^"]+\.js)"', text))
    files |= set(re.findall(r'<link rel="stylesheet" href="/([^"]+\.css)"', text))
for f in sorted(files):
    if not (out / f).is_file():
        sys.exit(f"FAIL: a page names {f}, which the build did not write")
if not any(f.startswith("assets/js/app.") for f in files):
    sys.exit("FAIL: no page names the app's own script")
print(f"   the staged build wrote its own site: {len(pages)} pages and the 404 page, {len(files)} scripts and "
      f"stylesheets, every page titled {name!r}")
PY

# What the deploy would upload: the Worker bundled from its source entry, and
# the static site beside it as assets.
grep -q 'Total Upload' "$scratch/deploy-dry-run.log" || { echo "FAIL: the dry run listed no Worker upload" >&2; tail -20 "$scratch/deploy-dry-run.log" >&2; exit 1; }
grep -m1 'Total Upload' "$scratch/deploy-dry-run.log" | sed 's/^/   /'
cfg="$(python3 -c "import yaml,sys;print(yaml.safe_load(open(sys.argv[1]))['spec']['parameters']['wranglerConfig'])" "$tree/apps/web/component.yaml")"

# ── 3. serve it, and smoke it as the deploy does ───────────────────────────
echo "── wrangler dev over the built Worker ($cfg)"
port=$(python3 -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1]);s.close()")
(cd "$work/apps/web" && exec setsid pnpm exec wrangler dev --config "$cfg" --ip 127.0.0.1 --port "$port" \
   --name "$repo-web-stage" --show-interactive-dev-session=false) > "$scratch/dev.log" 2>&1 < /dev/null &
dev_pid=$!
url="http://127.0.0.1:$port"
for _ in $(seq 1 90); do
  curl -s -o /dev/null "$url/" && break
  kill -0 "$dev_pid" 2>/dev/null || { echo "FAIL: wrangler dev exited" >&2; tail -30 "$scratch/dev.log" >&2; exit 1; }
  sleep 1
done
curl -s -o /dev/null "$url/" || { echo "FAIL: wrangler dev never answered" >&2; tail -30 "$scratch/dev.log" >&2; exit 1; }

echo "   ▸ the component's own smokeCommand, DEPLOYED_URL=$url"
smoke="$(python3 -c "import yaml,sys;print(yaml.safe_load(open(sys.argv[1]))['spec']['parameters']['smokeCommand'])" "$tree/apps/web/component.yaml")"
DEPLOYED_URL="$url" bash -c "$smoke" || { echo "FAIL: the deploy's smoke refused the site" >&2; exit 1; }

echo "   ▸ every route the site promises"
python3 - "$url" "$values" <<'PY'
import html as htmllib, json, re, sys, urllib.error, urllib.parse, urllib.request
base, values = sys.argv[1], json.load(open(sys.argv[2]))
problems = []
def bad(m): problems.append(m)
class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *a, **k): return None
opener = urllib.request.build_opener(NoRedirect)
NAV = {"Sec-Fetch-Mode": "navigate", "Sec-Fetch-Dest": "document", "Accept": "text/html"}
def get(path, nav=False):
    req = urllib.request.Request(urllib.parse.urljoin(base + "/", path), headers=NAV if nav else {})
    try:
        with opener.open(req, timeout=30) as r:
            return r.status, r.headers, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.headers, e.read()
def ctype(h):
    return (h.get("content-type") or "").split(";")[0].strip()
def text(b):
    # Decoded, with React's text-node separators gone: what a reader sees.
    return htmllib.unescape(re.sub(r"<!-- -->", "", b.decode()))

name = values["productname"]
def title(b):
    m = re.search(r"<title>([^<]*)</title>", b.decode())
    return htmllib.unescape(m.group(1)) if m else None

# / — the template's home page, rendered at build time, titled with the
# site's name, under the restored navbar.
status, headers, body = get("/", nav=True)
home = text(body)
if status != 200 or ctype(headers) != "text/html":
    bad(f"/ answered {status} {ctype(headers)}")
if title(body) != name:
    bad(f"/ is titled {title(body)!r}, not the site's name {name!r}")
for want in ('<meta name="generator" content="VuePress 1.9.7">', '<img src="https://v1.vuepress.vuejs.org/hero.png" alt="hero">',
             "Quick Start →", "Feature 1 Title", "Feature 2 Description", "Feature 3 Title", "Made by  with ❤️",
             f'<span class="site-name">{name}</span>', 'href="/guide/"', 'href="/config/"',
             'href="https://v1.vuepress.vuejs.org"'):
    if want not in home:
        bad(f"/ does not carry {want!r}")
if "vercel.app" in home or "Vuepress Docs Boilerplate" in home:
    bad("/ still names the template or its Vercel demo host")

# Every script and stylesheet the home page names, served with its type.
files = re.findall(r'<script src="(/[^"]+\.js)"', home) + re.findall(r'<link rel="stylesheet" href="(/[^"]+\.css)"', home)
if not any(f.startswith("/assets/js/app.") for f in files):
    bad("/ names no app script")
for f in files:
    s, h, b = get(f)
    want = "text/javascript" if f.endswith(".js") else "text/css"
    if s != 200 or ctype(h) != want:
        bad(f"{f} answered {s} {ctype(h)}, not 200 {want}")

# Every page, at every address Vercel answers it on — a folder with and
# without its slash and at its index.html, a page at its .html — 200 and
# never a redirect.
for path, want in (("/index.html", name), ("/guide/", f"Introduction | {name}"), ("/guide", f"Introduction | {name}"),
                   ("/guide/index.html", f"Introduction | {name}"),
                   ("/guide/using-vue.html", f"Using Vue in Markdown | {name}"),
                   ("/config/", f"Config | {name}"), ("/config", f"Config | {name}")):
    s, h, b = get(path, nav=True)
    if s != 200 or title(b) != want:
        bad(f"{path} answered {s} {title(b)!r}, not 200 {want!r}")
s, h, b = get("/guide/", nav=True)
if 'href="/guide/using-vue.html"' not in b.decode() or "sidebar-heading" not in b.decode():
    bad("/guide/ has no sidebar linking its second page")
s, h, b = get("/config/", nav=True)
if 'href="/config/#foo"' not in b.decode():
    bad("/config/ has no sidebar built from its headings")

# A missing page — with or without a browser's navigation headers — a page's
# address without its .html (Vercel does not guess it either), a missing
# folder and a missing chunk: VuePress's 404 page, status 404.
for path, nav in (("/no-such-page", True), ("/no-such-page", False), ("/no-such-folder/", True), ("/a/b/c/d", True),
                  ("/guide/using-vue", True), ("/assets/js/missing.js", False), ("/no-such.css", False)):
    s, h, b = get(path, nav=nav)
    if s != 404 or "<h1>404</h1>" not in b.decode() or "Take me home." not in b.decode():
        bad(f"{path} ({'navigation' if nav else 'no navigation headers'}) answered {s}, not the 404 page")

if problems:
    for p in problems:
        print(f"  ✕ {p}", file=sys.stderr)
    sys.exit(1)
print(f"   /, its {len(files)} scripts and stylesheets, 7 page addresses served as they are named, and the 404 page "
      f"with a 404 for a missing page, an extension-less address, a folder and a chunk")
PY

echo "e2e.test.sh: ok"
