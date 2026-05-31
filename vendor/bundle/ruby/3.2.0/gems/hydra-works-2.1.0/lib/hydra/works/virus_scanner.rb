# The default virus scanner for Hydra::Works
# If ClamAV is present, it will be used to check for the presence of a virus. If ClamAV is not
# installed or otherwise not available to your application, Hydra::Works does no virus checking
# add assumes files have no viruses.
#
# To use a virus checker other than ClamAV:
#   class MyScanner < Hydra::Works::VirusScanner
#     def infected?
#       my_result = Scanner.check_for_viruses(file)
#       [return true or false]
#     end
#   end
#
# Then set Hydra::Works to use your scanner either in a config file or initializer:
#   Hydra::Works.default_system_virus_scanner = MyScanner
module Hydra::Works
  class VirusScanner
    attr_reader :file

    # @api public
    # @param file [String]
    def self.infected?(file)
      new(file).infected?
    end

    def initialize(file)
      @file = file
    end

    # Override this method to use your own virus checking software
    # @return [Boolean]
    def infected?
      if defined?(Clamby)
        clamby_scanner
      elsif defined?(ClamAV)
        clam_av_scanner
      else
        null_scanner
      end
    end

    def clam_av_scanner
      Deprecation.warn(self, "The ClamAV has been replaced by Clamby " \
        "as the supported virus scanner for hydra-works. " \
        "ClamAV support will be removed in hydra-works 2.0 ")
      scan_result = ClamAV.instance.method(:scanfile).call(file)
      return false if scan_result == 0
      warning "A virus was found in #{file}: #{scan_result}"
      true
    end

    # @return [Boolean]
    def clamby_scanner
      scan_result = Clamby.virus?(file)
      warning("A virus was found in #{file}") if scan_result
      scan_result
    end

    # Always return zero if there's nothing available to check for viruses. This means that
    # we assume all files have no viruses because we can't conclusively say if they have or not.
    def null_scanner
      warning "Unable to check #{file} for viruses because no virus scanner is defined"
      false
    end

    private

      def warning(msg)
        ActiveFedora::Base.logger&.warn(msg)
      end
  end
end
