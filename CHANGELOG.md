# Changelog

## v2.0.0 — 2026-10-02

- New app from the latest web version, with two tabs:
  - **Market Rollercoaster** game: invest $200 a month from 25 to 65, pick a
    portfolio, and make decisions through crashes, hot tips, fees, and raises;
    compare with Steady Sam and Diversified Dana on a 40-year chart; Investor
    Behavior Score.
  - **My Investing Plan** calculator: portfolio mix, contributions, yearly
    raise, employer match, and fees, with bad-luck / typical / good-luck
    outcomes from 2,000 simulated futures, today's dollars, and a year-by-year
    table.
- Real app look: black launch screen with the big logo (no white box on
  Android 12+), new launcher icon on black (the old icon background was
  white), solid app bar, and About / Privacy / Credits panels.
- Android back button: planner → game, asks before quitting a game, results →
  start, and asks before exiting.
- Phones and tablets, portrait and landscape: rotates freely, smaller
  start-screen logo on landscape phones, compact planner table on narrow phones.
- Removed the social, fundraising, and "Play another game" links from the new
  web version; a content security policy blocks all network access.
- APK renamed to `WGRALGO-InvestmentPortfolioBuilder-v2.0.0.apk`, the same
  `WGRALGO-<AppName>-v<version>.apk` naming as every WGRALGO app.
- Version 2.0.0 (versionCode 200). Signed with a new key: uninstall v1.0.0
  before installing v2.0.0.
- Release signing can now come from `IPB_*` environment variables; added
  GitHub Actions debug builds, a signed release workflow,
  `tools/validate-release.sh`, and `tools/build-icons.py`.

## v1.0.0

- Initial GitHub-ready Android APK release.
- Added offline investment portfolio projection tool.
- Added eight portfolio selection cards with risk labels and educational annual-return assumptions.
- Added year-by-year growth projection with age, contributions, balance, and inflation-adjusted balance.
- Added 3% inflation-adjusted (real) balance estimate.
- Added nominal vs. real growth chart with contribution baseline.
- Added per-result money lesson and educational disclaimer.
- Added share/copy plain-text summary action.
- Removed website navigation, social media widget, GoFundMe bar, and WordPress menu clutter from the APK interface.
- Updated package name to `org.wgralgo.investmentportfoliobuilder`.
- Added GPLv3 license, privacy statement, contributors file, security policy, and README.
- Built with proper release signing.
- Hardened offline/privacy posture: APK does not declare `INTERNET` permission.
