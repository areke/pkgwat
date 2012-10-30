require "pkgwat/version"
require 'net/https'
require 'json'

module Pkgwat
  require 'pkgwat/railtie' if defined?(Rails)

  F17 = "Fedora 17"
  F16 = "Fedora 16"
  F18 = "Fedora 18"
  EPEL6 = "Fedora EPEL 6"
  EPEL5 = "Fedora EPEL 5"
  DEFAULT_DISTROS = [F17, F16, EPEL6]
  PACKAGE_NAME = "rubygem-:gem"
  PACKAGES_URL = "https://apps.fedoraproject.org/packages/fcomm_connector/bodhi/query/query_active_releases"

  def self.check_gem(name, version, distros = DEFAULT_DISTROS, throw_ex = false)
    puts "Checking #{name} #{version}...\n"
    versions = get_versions(name)
    matches = []
    distros.each do |distro|
      dv = versions.detect { |v| v["release"] == distro }
      match = compare_versions(version, dv["stable_version"])
      matches << dv["release"] if match
    end
    puts "Its available in the following distros: #{matches.join(",")}"
  end

  def self.compare_versions(version, distro)
    distro.to_s.split("-").first == version.to_s
  end

  def self.get_versions(gem_name)
    uri = search_url(gem_name)
    response = submit_request(uri)
    raise "Could not connect to packages API (#{response.inspect})" unless response.code == "200"
    parse_results(response.body)
  end

  def self.package_name(gem)
    PACKAGE_NAME.gsub(":gem", gem)
  end

  def self.search_params(gem)
    filters = { :package => package_name(gem) }
    { :filters => filters }
  end

  def self.search_url(gem)
    query = search_params(gem)
    url = PACKAGES_URL + "/" + query.to_json
    URI.parse(URI.escape(url))
  end

  def self.submit_request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE #TODO: verify
    request = Net::HTTP::Get.new(uri.request_uri)
    http.request(request)
  end

  def self.parse_results(results)
    results = JSON.parse(results)
    results["rows"]
  end

end