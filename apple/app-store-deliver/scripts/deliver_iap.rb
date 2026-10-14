#!/usr/bin/env ruby
# deliver_iap.rb — deliver an In-App Purchase's per-locale text + review note to
# App Store Connect via the official ASC API (token auth). `fastlane deliver` does
# NOT manage IAPs and there is no ConnectAPI IAP model — this drives the raw
# endpoints (see references/iap-and-asc-api.md). Idempotent: create-or-update.
#
# Usage:
#   ruby deliver_iap.rb <slug> <product-id> <bundle-id> [--locales en-US,en-GB]
#                       [--iap-dir DIR] [--hub DIR]
#
#   <slug>        hub app folder (used to locate store/apple/iap/<product-id>)
#   <product-id>  the IAP product id (e.g. com.acme.app.pro)
#   <bundle-id>   the app bundle id
#   --locales     locales to write (default: every <locale>/ dir under the iap dir)
#   --iap-dir     override the hub iap dir (default $hub/<slug>/store/apple/iap/<product-id>)
#
# Reads display_name.txt + description.txt per locale and review/notes.txt.
# Sets price + reviewer screenshot is NOT done here (price is usually already set;
# the reviewer screenshot is uploaded by the deliver flow / app-store-metadata).
# Run with the ASC key in the hub DATA.md. Confirm with the user before running —
# this writes to App Store Connect.

require_relative "asc_common"

pos, opts = ASC.parse_args(ARGV)
slug, pid, bundle = pos
abort "usage: deliver_iap.rb <slug> <product-id> <bundle-id> [--locales a,b]" unless slug && pid && bundle

ASC.token!
rc = ASC.rc
iap_dir = opts[:iapdir] || opts[:"iap-dir"] || File.join(ASC.hub, slug, "store/apple/iap", pid)
abort "iap dir not found: #{iap_dir}" unless Dir.exist?(iap_dir)

locales = ASC.locales_arg(opts) ||
          Dir.children(iap_dir).select { |c| File.directory?(File.join(iap_dir, c)) && c =~ /-/ }
abort "no locales found under #{iap_dir}" if locales.empty?

app_id = ASC.app_id(bundle)
listing = ASC.body(rc.get("v1/apps/#{app_id}/inAppPurchasesV2", { limit: 200 }))["data"]
rec = listing.find { |p| p.dig("attributes", "productId") == pid }
abort "IAP #{pid} not found in ASC (create it first)" unless rec
iid = rec["id"]
puts "IAP #{pid} id=#{iid} state=#{rec.dig('attributes','state')}"

iap = ASC.body(rc.get("v2/inAppPurchases/#{iid}"))
loc_url = iap.dig("data", "relationships", "inAppPurchaseLocalizations", "links", "related")
              .sub("https://api.appstoreconnect.apple.com/", "")
existing = ASC.body(rc.get(loc_url))["data"] || []

locales.each do |loc|
  name = File.read(File.join(iap_dir, loc, "display_name.txt")).strip
  desc = File.read(File.join(iap_dir, loc, "description.txt")).strip
  if (m = existing.find { |x| x.dig("attributes", "locale") == loc })
    rc.patch("v1/inAppPurchaseLocalizations/#{m['id']}",
             { data: { type: "inAppPurchaseLocalizations", id: m["id"],
                       attributes: { name: name, description: desc } } })
    puts "  [#{loc}] updated localization"
  else
    rc.post("v1/inAppPurchaseLocalizations",
            { data: { type: "inAppPurchaseLocalizations",
                      attributes: { locale: loc, name: name, description: desc },
                      relationships: { inAppPurchaseV2: { data: { type: "inAppPurchases", id: iid } } } } })
    puts "  [#{loc}] created localization"
  end
end

notes_file = File.join(iap_dir, "review", "notes.txt")
if File.exist?(notes_file)
  rc.patch("v2/inAppPurchases/#{iid}",
           { data: { type: "inAppPurchases", id: iid,
                     attributes: { reviewNote: File.read(notes_file).strip } } })
  puts "  review note set"
end

state = ASC.body(rc.get("v2/inAppPurchases/#{iid}")).dig("data", "attributes", "state")
puts "IAP state now: #{state}"
puts "NOTE: a reviewer screenshot is REQUIRED before submission; it ships attached to the next app-version submission."
