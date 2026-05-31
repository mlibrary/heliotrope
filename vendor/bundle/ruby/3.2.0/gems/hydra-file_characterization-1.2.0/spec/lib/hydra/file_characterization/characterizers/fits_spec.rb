# frozen_string_literal: true
require 'spec_helper'
require 'hydra/file_characterization/characterizers/fits'

module Hydra::FileCharacterization::Characterizers
  describe Fits do
    let(:fits) { described_class.new(filename) }

    describe "#call", unless: ENV['TRAVIS'] do
      subject { fits.call }

      context 'validfile' do
        let(:filename) { fixture_file('brendan_behan.jpeg') }
        it { is_expected.to include(%(<identity format="JPEG File Interchange Format" mimetype="image/jpeg")) }
      end

      context 'invalidFile' do
        let(:filename) { fixture_file('nofile.pdf') }
        it "raises an error" do
          expect { subject }.to raise_error(Hydra::FileCharacterization::FileNotFoundError)
        end
      end

      context 'corruptFile' do
        let(:filename) { fixture_file('brendan_broken.dxxd') }
        it { is_expected.to include(%(<identity format="Unknown Binary" mimetype="application/octet-stream")) }
      end

      context 'zip file should be characterized not its contents' do
        let(:filename) { fixture_file('archive.zip') }
        it { is_expected.to include(%(<identity format="ZIP Format" mimetype="application/zip")) }
      end
    end

    context 'when JHOVE adds non-xml' do
      # https://github.com/harvard-lts/fits/issues/20
      subject { fits.call }

      before do
        expect(fits.logger).to receive(:warn)
        allow(fits).to receive(:internal_call).and_return(
          'READBOX seen=true
<?xml version="1.0" encoding="UTF-8"?>
<fits xmlns="http://hul.harvard.edu/ois/xml/ns/fits/fits_output" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://hul.harvard.edu/ois/xml/ns/fits/fits_output http://hul.harvard.edu/ois/xml/xsd/fits/fits_output.xsd" version="0.8.2" timestamp="15/09/14 10:00 AM">
<identification/></fits>'
        )
      end

      let(:filename) { fixture_file('brendan_behan.jpeg') }
      it { is_expected.not_to include('READBOX') }
    end

    context "when FITS itself adds non-xml" do
      # https://github.com/harvard-lts/fits/issues/46
      subject { fits.call }

      before do
        expect(fits.logger).to receive(:warn)
        allow(fits).to receive(:internal_call).and_return(
          '2015-10-15 17:14:25,761 ERROR [main] ToolBelt:79 - Thread 1 error initializing edu.harvard.hul.ois.fits.tools.droid.Droid: edu.harvard.hul.ois.fits.exceptions.FitsToolException  Message: DROID cannot run under Java 8
<?xml version="1.0" encoding="UTF-8"?>
<fits xmlns="http://hul.harvard.edu/ois/xml/ns/fits/fits_output" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://hul.harvard.edu/ois/xml/ns/fits/fits_output http://hul.harvard.edu/ois/xml/xsd/fits/fits_output.xsd" version="0.8.2" timestamp="15/09/14 10:00 AM">
<identification/></fits>'
        )
      end

      let(:filename) { fixture_file('brendan_behan.jpeg') }
      it { is_expected.not_to include('FitsToolException') }
    end
  end
end
