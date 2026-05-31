# -*- ruby encoding: utf-8 -*-

require "rubygems"
require "hoe"
require "rake/clean"

$LOAD_PATH.unshift("support")

Hoe.plugin :doofus
Hoe.plugin :gemspec2
Hoe.plugin :git2
Hoe.plugin :minitest
Hoe.plugin :rubygems
Hoe.plugin :deprecated_gem
Hoe.plugin :cov

Hoe.spec "minitar" do
  developer("Austin Ziegler", "halostatue@gmail.com")

  self.history_file = "History.md"
  self.readme_file = "README.rdoc"

  require_ruby_version ">= 1.8"

  # This is a hack because of an issue with Hoe 3.26, but I'm not sure which
  # hoe version introduced this issue or if it's a JRuby issue. This issue is
  # demonstrable in lib/hoe.rb at line 676, which is (reformatted for space):
  #
  # ```ruby
  # readme =
  #   input
  #     .lines
  #     .chunk { |l| l[/^(?:=+|#+)/] || "" } # # chunk is different somehow
  #     .map(&:last) # <-- HERE: "#" does not respond to #last
  #     .each_slice(2)
  #     .map { |k, v|
  #       kp = k.join
  #       kp = kp.strip.chomp(":").split.last.downcase if k.size == 1
  #       [kp, v.join.strip]
  #     }
  #     .to_h
  # ```
  #
  # We don't *ship* with JRuby, but use it in CI only, so this is here at least
  # temporarily.
  if RUBY_PLATFORM.match?(/java/)
    self.summary = self.description = "Description for testing"
    self.homepage = "https://github.com/KineticCafe/app-identity/tree/main/ruby/"
  end

  self.licenses = ["Ruby", "BSD-2-Clause"]

  self.post_install_message = <<-EOS
The `minitar` executable is no longer bundled with `minitar`. If you are
expecting this executable, make sure you also install `minitar-cli`.
  EOS

  spec_extras[:metadata] = ->(val) { val["rubygems_mfa_required"] = "true" }

  extra_dev_deps << ["base64", "~> 0.2"]
  extra_dev_deps << ["hoe", "~> 4.0"]
  extra_dev_deps << ["hoe-doofus", "~> 1.0"]
  extra_dev_deps << ["hoe-gemspec2", "~> 1.1"]
  extra_dev_deps << ["hoe-git2", "~> 1.7"]
  extra_dev_deps << ["hoe-rubygems", "~> 1.0"]
  extra_dev_deps << ["minitest", "~> 5.16"]
  extra_dev_deps << ["minitest-autotest", "~> 1.0"]
  extra_dev_deps << ["minitest-focus", "~> 1.0"]
  extra_dev_deps << ["rake", ">= 10.0", "< 14"]
  extra_dev_deps << ["rdoc", ">= 0.0"]
  extra_dev_deps << ["standard", "~> 1.0"]
end
