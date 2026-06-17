# Delivering In-App Purchases via the official App Store Connect API

`fastlane deliver` handles the app listing but **not** in-app purchases. IAPs are
delivered through the **official App Store Connect API** (token-auth with the same
`.p8`), which fastlane exposes as `Spaceship::ConnectAPI`. This is the durable
path (vs the legacy `Spaceship::Tunes` web API) and uses the key already in the
hub `DATA.md`.

## Hub layout (the IAP source of truth)

Authored by **`app-store-metadata`** (orchestrated by `store-metadata-writer`) into
the hub; this skill only **syncs + uploads** it — it never writes this:

```
~/Developer/app-hub/<slug>/store/apple/iap/<product-id>/
  product.txt            # reference name · type (consumable / non-consumable / auto-renewable …)
  price.txt              # price point / tier, cleared-for-sale
  <locale>/display_name.txt    # the per-locale Display Name users see (≤30)
  <locale>/description.txt     # the per-locale Description (≤45 for promo / longer for review)
  review/screenshot.png        # REQUIRED reviewer screenshot
  review/notes.txt             # review notes for the App Review team
```

The `Pro:` line in the app's README / profile tells you a product exists and its
product id; the per-locale copy is lifted from the profile like all other copy.

## Field map — hub → ASC API

| Hub file | ASC API entity / field |
|----------|------------------------|
| `product.txt` (reference name, type) | `inAppPurchases` v2 — `name` (reference), `productId`, `inAppPurchaseType` |
| `<locale>/display_name.txt` | `inAppPurchaseLocalizations` — `name` |
| `<locale>/description.txt` | `inAppPurchaseLocalizations` — `description` |
| `price.txt` | `inAppPurchasePriceSchedules` / manual prices; `availableInAllTerritories` / cleared-for-sale |
| `review/notes.txt` | the IAP's `reviewNote` |
| `review/screenshot.png` | `inAppPurchaseAppStoreReviewScreenshot` (**required** before it can be submitted) |

## Auth (token, official — from DATA.md)

```ruby
require "spaceship"
token = Spaceship::ConnectAPI::Token.create(
  key_id:    "<Key ID from DATA.md>",
  issuer_id: "<Issuer ID from DATA.md>",
  filepath:  File.expand_path("<.p8 path from DATA.md>")
)
Spaceship::ConnectAPI.token = token
```

## The lane (sketch — one product, idempotent)

Create-or-find, set localizations + price + review material, attach the
screenshot, then submit. Method names track the ASC API v2 IAP endpoints; verify
against the installed `spaceship` version (`gem contents fastlane | grep -i in_app`).

```ruby
app = Spaceship::ConnectAPI::App.find("<bundle id>")
pid = "<product-id>"

iap = app.get_in_app_purchases.find { |p| p.product_id == pid } ||
      app.create_in_app_purchase(product_id: pid, name: ref_name, in_app_purchase_type: type)

# per-locale display name + description
locales.each do |loc|
  iap.upsert_localization(locale: loc,
    name:        File.read("#{iap_dir}/#{loc}/display_name.txt").strip,
    description: File.read("#{iap_dir}/#{loc}/description.txt").strip)
end

iap.set_price_schedule(price_point: price)          # or manual prices per territory
iap.update(review_note: File.read("#{iap_dir}/review/notes.txt").strip)
iap.upload_review_screenshot("#{iap_dir}/review/screenshot.png")   # required
iap.submit_for_review
```

If the installed spaceship lacks a ConnectAPI IAP helper for a step, fall back to
a direct `Spaceship::ConnectAPI.patch/post` against the documented endpoint, or
(last resort, fragile) the legacy `Spaceship::Tunes` `app.in_app_purchases` —
which also supports `versions=` (localizations), `pricing_intervals=`,
`review_notes`, and `review_screenshot`.

## Rules
- **The reviewer screenshot is mandatory** — a product without it can't be
  submitted. If `review/screenshot.png` is missing, stop and report it (same
  verify-or-block gate as the metadata sync).
- **Confirm before submitting** — creating/submitting IAPs is outward-facing.
- **Never invent copy or prices** — everything traces to the hub; missing → fill
  it in `store-metadata-writer`, then re-run.
