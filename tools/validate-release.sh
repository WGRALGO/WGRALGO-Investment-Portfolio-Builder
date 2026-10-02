#!/usr/bin/env bash
# Investment Portfolio Builder — release validation.
# Usage: ./tools/validate-release.sh [path/to/app.apk]
# Exit non-zero if any check fails.
set -u
cd "$(dirname "$0")/.."

VERSION=$(node -p "require('./package.json').version")
CODE=$(echo "$VERSION" | awk -F. '{ print $1*100 + $2*10 + $3 }')

PASS=0
FAIL=0
ok()  { echo "  PASS  $1"; PASS=$((PASS+1)); }
bad() { echo "  FAIL  $1"; FAIL=$((FAIL+1)); }

echo "== Game data =="
OUT=$(node - <<'NODE'
const fs = require("fs");
const h = fs.readFileSync("www/index.html", "utf8");
const R = (ok, msg) => console.log((ok ? "PASS " : "FAIL ") + msg);
const grab = name => {
  const m = h.match(new RegExp("const " + name + " = \\[([\\s\\S]*?)\\n  \\];"));
  return m ? eval("[" + m[1] + "]") : null;
};
const mixes = grab("MIXES"), pfs = grab("GAME_PFS");
if (!mixes || !pfs) { console.log("FAIL game data not found"); process.exit(0); }
R(mixes.length >= 5 && mixes.every(m => m.id && m.name && m.desc && (m.stocks === null || (m.stocks >= 0 && m.stocks <= 1))),
  mixes.length + " planner mixes, each with a name, description, and stock share");
R(new Set(mixes.map(m => m.id)).size === mixes.length, "no duplicate planner mixes");
R(pfs.length >= 4 && pfs.every(p => p.id && p.name && p.desc && p.why && p.score >= 0 && p.score <= 10),
  pfs.length + " game portfolios, each explained and scored 0-10");
R(pfs.some(p => p.score === 10) && pfs.some(p => p.score <= 3), "game has strong and risky portfolio choices");
R(pfs.some(p => p.id === "td"), "game includes the target-date fund (Diversified Dana)");
for (const id of ["wgra-inv-p-age", "wgra-inv-p-ret", "wgra-inv-p-month", "wgra-inv-p-match", "wgra-inv-p-fee", "wgra-inv-p-go"])
  if (!h.includes('id="' + id + '"')) R(false, "planner field " + id + " missing");
R(true, "planner fields present");
R(/window\.onAndroidBack = function/.test(h), "Android back button hook present");
NODE
)
while IFS= read -r line; do
  case "$line" in
    PASS*) ok "${line#PASS }" ;;
    FAIL*) bad "${line#FAIL }" ;;
  esac
done <<< "$OUT"

echo "== Version $VERSION (code $CODE) =="
GR=android/app/build.gradle
grep -q "versionName \"$VERSION\"" $GR && ok "versionName $VERSION" || bad "versionName is not $VERSION"
grep -q "versionCode $CODE" $GR && ok "versionCode $CODE" || bad "versionCode is not $CODE"
grep -q "v$VERSION" www/index.html && ok "app shows v$VERSION" || bad "app does not show v$VERSION"
grep -q "$VERSION" README.md && ok "README mentions $VERSION" || bad "README missing $VERSION"
[ -f "release-notes/v$VERSION.md" ] && ok "release-notes/v$VERSION.md present" || bad "release-notes/v$VERSION.md missing"

echo "== Build config =="
grep -q 'applicationId "org.wgralgo.investmentportfoliobuilder"' $GR && ok "appId org.wgralgo.investmentportfoliobuilder" || bad "appId wrong"
grep -q 'debuggable false' $GR && ok "release debuggable false" || bad "release not debuggable false"
grep -q 'minifyEnabled true' $GR && ok "minify enabled" || bad "minify not enabled"
MAN=android/app/src/main/AndroidManifest.xml
grep -q 'android.permission.INTERNET" tools:node="remove"' $MAN && ok "INTERNET permission stripped" || bad "INTERNET permission not stripped"

echo "== Logo, icon, splash =="
RES=android/app/src/main/res
[ -f "$RES/drawable-nodpi/splash_icon.jpg" ] && ok "Android 12+ splash logo present" || bad "splash_icon.jpg missing"
grep -q 'windowSplashScreenAnimatedIcon">@drawable/splash_icon' $RES/values/styles.xml && ok "system splash uses the logo" || bad "system splash not set to the logo"
grep -q 'windowSplashScreenBackground">@android:color/black' $RES/values/styles.xml && ok "system splash background is black" || bad "system splash background not black"
grep -q '#000000' $RES/values/ic_launcher_background.xml && ok "icon background is black" || bad "icon background not black"
[ -f www/logo.jpg ] && ok "in-app logo present" || bad "in-app logo missing"

echo "== App privacy =="
IDX=www/index.html
grep -qi 'Content-Security-Policy' $IDX && ok "CSP present" || bad "CSP missing"
grep -Eqi 'href="(https?:)?//|href="/|src="https?://|@import' $IDX && bad "external link or resource in app" || ok "no external links or resources"
grep -Eqi 'gofundme\.com|facebook\.com|instagram\.com|tiktok\.com|youtube\.com' $IDX && bad "donation/social link in app" || ok "no donation or social links"
grep -Eqi 'google-analytics|googletagmanager|gtag\(|firebase|admob' $IDX && bad "analytics/ads reference" || ok "no analytics or ads"
grep -Eq 'localStorage|sessionStorage|indexedDB|document\.cookie' $IDX && bad "app stores data on device" || ok "no on-device storage"

echo "== License =="
grep -q '"license": "GPL-3.0-only"' package.json && ok "package.json license GPL-3.0-only" || bad "package.json license not GPL-3.0-only"
grep -q 'GNU GENERAL PUBLIC LICENSE' LICENSE && ok "LICENSE is GPLv3" || bad "LICENSE is not GPLv3"

echo "== Name and orientation =="
grep -q '<string name="app_name">WGRALGO' android/app/src/main/res/values/strings.xml && bad "app name under the icon starts with WGRALGO" || ok "app name under the icon has no WGRALGO prefix"
grep -q 'screenOrientation' android/app/src/main/AndroidManifest.xml && bad "orientation is locked" || ok "rotates freely (portrait and landscape)"
grep -q 'WGRALGO-[A-Za-z]*-v' .github/workflows/release.yml && ok "APK named WGRALGO-<AppName>-v<version>.apk" || bad "APK name not uniform"

if [ "${1:-}" != "" ] && [ -f "${1:-}" ]; then
  APK="$1"
  echo "== APK: $APK =="
  SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
  BT=$(ls -d "$SDK"/build-tools/* 2>/dev/null | sort -V | tail -1)
  if [ -x "$BT/aapt2" ]; then
    DUMP=$("$BT/aapt2" dump badging "$APK" 2>/dev/null)
    echo "$DUMP" | grep -q "versionName='$VERSION'" && ok "APK versionName $VERSION" || bad "APK versionName wrong"
    echo "$DUMP" | grep -q "versionCode='$CODE'" && ok "APK versionCode $CODE" || bad "APK versionCode wrong"
    echo "$DUMP" | grep -q "package: name='org.wgralgo.investmentportfoliobuilder'" && ok "APK package id" || bad "APK package id wrong"
    echo "$DUMP" | grep -q "uses-permission: name='android.permission.INTERNET'" && bad "APK declares INTERNET" || ok "APK has no INTERNET permission"
  else
    bad "aapt2 not found"
  fi
  if [ -x "$BT/apksigner" ]; then
    CERT=$("$BT/apksigner" verify --print-certs "$APK" 2>/dev/null)
    echo "$CERT" | grep -qi "CN=Android Debug" && bad "APK signed with debug cert" || ok "APK not signed with debug cert"
    "$BT/apksigner" verify "$APK" >/dev/null 2>&1 && ok "APK signature verifies" || bad "APK signature invalid/unsigned"
  else
    bad "apksigner not found"
  fi
else
  echo "== APK checks skipped (no APK path given) =="
fi

echo
echo "RESULT: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ]
