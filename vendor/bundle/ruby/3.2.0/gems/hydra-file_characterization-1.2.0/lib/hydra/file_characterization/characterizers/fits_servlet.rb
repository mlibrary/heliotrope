# frozen_string_literal: true
require 'hydra/file_characterization/exceptions'
require 'hydra/file_characterization/characterizer'
require 'logger'
module Hydra::FileCharacterization::Characterizers
  class FitsServlet < Hydra::FileCharacterization::Characterizer
    protected

    def command
      "curl -s -k -F datafile=@'#{filename}' #{ENV['FITS_SERVLET_URL']}/examine"
    end
  end
end
