# A Hoe plug-in to provide a second, linked gemspec, for a gem that has been
# deprecated in favour of a modern name. (The name is an artifact of Hoe's
# plugin loading.)
module Hoe::Deprecated_Gem # standard:disable Naming/ClassAndModuleCamelCase
  def linked_spec(spec)
    permitted_classes = %w[
      Symbol Time Date Gem::Dependency Gem::Platform Gem::Requirement
      Gem::Specification Gem::Version Gem::Version::Requirement
      YAML::Syck::DefaultKey Syck::DefaultKey
    ]
    permitted_symbols = %w[development runtime]
    atm = begin
      YAML.safe_load(
        YAML.dump(spec),
        :permitted_classes => permitted_classes,
        :permitted_symbols => permitted_symbols,
        :aliases => true
      )
    rescue
      YAML.safe_load(
        YAML.dump(spec), permitted_classes, permitted_symbols, true
      )
    end
    atm.name = "archive-tar-minitar"
    d = %('#{atm.name}' has been deprecated; just install '#{spec.name}'.)
    atm.description = "#{d} #{spec.description}"
    atm.summary = atm.post_install_message = d
    atm.files.delete_if do |f|
      f !~ %r{lib/archive-tar-minitar\.rb}
    end
    atm.extra_rdoc_files.clear
    atm.rdoc_options.clear
    atm.dependencies.clear

    version = Gem::Version.new(spec.version.segments.first(2).join("."))

    atm.add_dependency(spec.name, "~> #{version}")
    atm.add_dependency(%(#{spec.name}-cli), "~> #{version}")

    unless @include_all
      [:signing_key, :cert_chain].each { |name|
        atm.send(:"#{name}=", atm.default_value(name))
      }
    end

    atm
  end

  def define_deprecated_gem_tasks
    gemspec = spec.name + ".gemspec"
    atmspec = "archive-tar-minitar.gemspec"

    file atmspec => gemspec do
      File.open(atmspec, "w") { |f| f.write(linked_spec(spec).to_ruby) }
    end

    task :gemspec => atmspec

    Gem::PackageTask.new linked_spec(spec) do |pkg|
      pkg.need_tar = @need_tar
      pkg.need_zip = @need_zip
    end
  end
end
