# asc_common.rb — shared App Store Connect token auth + raw-request helpers for the
# app-store-deliver helper scripts. Reads the ASC API key from the hub DATA.md
# ("### key fastlane appstore": Issuer ID / key id / n8 = .p8 path).
#
#   require_relative "asc_common"
#   ASC.token!                       # authenticate (token from ~/Developer/app-hub/DATA.md)
#   rc = ASC.rc                      # raw client: rc.get/.post/.patch/.delete (paths "v1/..", "v2/..")
#   ASC.body(rc.get("v1/..."))       # parsed JSON hash
#
# Override the hub root with $APP_HUB.

require "spaceship"
require "json"

module ASC
  module_function

  def hub
    ENV["APP_HUB"] || File.expand_path("~/Developer/app-hub")
  end

  def token!
    data   = File.read(File.join(hub, "DATA.md"))
    key_id = data[/key id:\s*(\S+)/i, 1]
    issuer = data[/Issuer ID:\s*(\S+)/i, 1]
    p8     = data[/^\s*n8:\s*(\S+)/i, 1]
    raise "ASC key not found in #{hub}/DATA.md (need Issuer ID / key id / n8)" unless key_id && issuer && p8
    Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
      key_id: key_id, issuer_id: issuer, filepath: File.expand_path(p8)
    )
    Spaceship::ConnectAPI
  end

  def rc
    Spaceship::ConnectAPI.client.tunes_request_client
  end

  def body(resp)
    resp.body.is_a?(Hash) ? resp.body : JSON.parse(resp.body)
  end

  def app_id(bundle_id)
    app = Spaceship::ConnectAPI::App.find(bundle_id)
    raise "app not found for bundle #{bundle_id}" unless app
    app.id
  end

  # The editable App Store version for a platform + version string.
  def version(app_id, platform:, version:)
    v = body(rc.get("v1/apps/#{app_id}/appStoreVersions",
                    {"filter[platform]" => platform, "filter[versionString]" => version}))["data"]
    raise "version #{version} (#{platform}) not found" if v.nil? || v.empty?
    v.first
  end

  def localizations(version_id)
    body(rc.get("v1/appStoreVersions/#{version_id}/appStoreVersionLocalizations"))["data"]
  end

  # minimal --flag parser: returns [positionals, {flag => value}]
  def parse_args(argv)
    pos = []; opts = {}
    i = 0
    while i < argv.length
      a = argv[i]
      if a.start_with?("--")
        opts[a.sub(/^--/, "").to_sym] = argv[i + 1]; i += 2
      else
        pos << a; i += 1
      end
    end
    [pos, opts]
  end

  def locales_arg(opts, default = nil)
    (opts[:locales] || default)&.split(",")&.map(&:strip)
  end
end
