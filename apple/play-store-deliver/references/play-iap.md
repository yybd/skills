# Delivering Google Play in-app products & subscriptions

`fastlane supply` delivers the **listing** but **not** in-app products. Play
monetization is delivered through the **Google Play Developer API**
(AndroidPublisher v3), authenticated with the **same service-account JSON** from
the hub `DATA.md`. Two resources:

- **Managed products** (one-time / consumable) → the `inappproducts` resource.
- **Subscriptions** → the `monetization.subscriptions` resource (base plans + offers).

## Hub layout (the source of truth)

Authored by `play-store-metadata` into the hub; this skill only uploads it:

```
~/Developer/app-hub/<slug>/store/play/iap/<product-id>/
  product.txt        # sku · purchaseType (managed | subscription) · status (active/inactive)
  price.txt          # default price: currency + amount  [+ optional per-region lines]
  <locale>/title.txt        # ≤55 chars
  <locale>/description.txt  # ≤200 chars
  # subscriptions only:
  base-plans.txt     # base plan ids + billing period + renewal type
```

## Field map — hub → AndroidPublisher v3

| Hub | API (managed product `inappproducts`) |
|-----|----------------------------------------|
| `product.txt` sku/status/purchaseType | `sku`, `status`, `purchaseType` |
| `price.txt` default | `defaultPrice` `{ currency, priceMicros }` (amount × 1e6) |
| `price.txt` per-region | `prices[region]` `{ currency, priceMicros }` |
| `<locale>/title.txt` + `description.txt` | `listings[locale]` `{ title, description }`, `defaultLanguage` |

Subscriptions use `monetization.subscriptions` instead: `productId`, per-locale
`listings` (title/description/benefits), and `basePlans` (id, billing period,
auto-renewing) + optional `offers`.

## Auth (service account — from DATA.md)

```ruby
require "google/apis/androidpublisher_v3"
require "googleauth"
AP = Google::Apis::AndroidpublisherV3
svc = AP::AndroidPublisherService.new
svc.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
  json_key_io: File.open("<service-account JSON path from DATA.md>"),
  scope: ["https://www.googleapis.com/auth/androidpublisher"]
)
```

## The lane (sketch — managed product, idempotent)

`inappproducts.update` is an upsert (insert if missing with `auto_convert_missing_prices`).
Run inside an edit is not required for `inappproducts` (it's outside the edits flow);
subscriptions (`monetization.*`) are also edit-free in v3.

```ruby
pkg = "<applicationId>"; pid = "<product-id>"; iap = "#{hub}/#{slug}/store/play/iap/#{pid}"

listings = {}
Dir.glob("#{iap}/*/title.txt").each do |t|
  loc = File.basename(File.dirname(t))
  listings[loc] = AP::InAppProductListing.new(
    title: File.read(t).strip,
    description: File.read("#{iap}/#{loc}/description.txt").strip)
end

product = AP::InAppProduct.new(
  package_name: pkg, sku: pid, status: "active", purchase_type: "managedUser",
  default_language: default_locale,
  default_price: AP::Price.new(currency: cur, price_micros: (amount * 1_000_000).to_i),
  listings: listings)

svc.update_in_app_product(pkg, pid, product, auto_convert_missing_prices: true)
```

For subscriptions, build `AP::Subscription` with `base_plans` + `listings` and call
the `monetization` subscription methods (verify exact method names against the
installed `google-apis-androidpublisher_v3` version).

## Rules
- **Verify before upload** — the same gate as the listing sync: if a product's
  `title`/`description`/`price` is missing in the hub, stop and point back to
  `play-store-metadata` (then `store-metadata-writer`) to fill it.
- **Confirm before publishing** — creating/activating products is outward-facing.
- **Never invent** prices or copy — everything traces to the hub.
- Some monetization changes still finalize on the **Play Console** (tax/compliance,
  some subscription settings) — tell the user what's left.
