# frozen_string_literal: true

require 'rails_helper'

describe PressHelper, type: :helper do
  describe "#press_presenter" do
    context "with a @press.subdomain" do
      let(:press) { create(:press, subdomain: 'blue') }

      it "is a PressPresenter" do
        @press = press
        expect(press_presenter.is_a?(PressPresenter)).to eq true
        expect(press_presenter.present?).to eq true
      end
    end

    context "with a @presenter.subdomain" do
      let(:press) { create(:press, subdomain: "blue") }
      let(:presenter) { double("presenter", subdomain: press.subdomain) }

      it "is a PressPresenter" do
        @presenter = presenter
        expect(press_presenter.is_a?(PressPresenter)).to eq true
        expect(press_presenter.present?).to eq true
      end
    end

    context "with a @presenter.parent.subdomain" do
      let(:press) { create(:press, subdomain: "blue") }
      let(:file_set_presenter) { double("presenter", parent: monograph_presenter) }
      let(:monograph_presenter) { double("presenter", subdomain: press.subdomain) }

      it "is a PressPresenter" do
        @presenter = file_set_presenter
        expect(press_presenter.is_a?(PressPresenter)).to eq true
        expect(press_presenter.present?).to eq true
      end
    end

    context "with no press" do
      it "is a PressPresenterNullObject" do
        expect(press_presenter.is_a?(PressPresenterNullObject)).to be true
      end

      it "responds to .present? with false" do
        expect(press_presenter.present?).to be false
      end
    end

    describe '#press_font_stylesheets' do
      it 'loads no press fonts without a press' do
        expect(press_font_stylesheets).to be_empty
      end

      it 'keeps the reader font available without a press' do
        expect(press_font_stylesheets(reader: true)).to eq(
          ['https://fonts.googleapis.com/css?family=Open+Sans:300,400,400i,600,600i,700']
        )
      end

      it 'loads only the active theme and configured kit' do
        @press = create(:press, subdomain: 'michigan', typekit: 'umv2ydc')

        expect(press_font_stylesheets).to eq(
          ['https://use.typekit.net/umv2ydc.css', 'https://use.typekit.net/hfw0vui.css']
        )
      end

      it 'deduplicates a configured kit shared by child and parent themes' do
        parent = create(:press, subdomain: 'michigan', typekit: 'hfw0vui')
        @press = create(:press, subdomain: 'michelt', parent: parent, typekit: '')

        expect(press_font_stylesheets).to eq(['https://use.typekit.net/hfw0vui.css'])
      end

      it 'preserves import order for child and parent fonts while honoring the child kit' do
        parent = create(:press, subdomain: 'mps', typekit: 'parentkit')
        @press = create(:press, subdomain: 'a2ru', parent: parent, typekit: 'childkit')

        expect(press_font_stylesheets).to eq(
          ['https://use.typekit.net/childkit.css',
           'https://fonts.googleapis.com/css2?family=Crimson+Text:ital,wght@0,400;0,700;1,400;1,700&family=Muli:ital,wght@0,400;0,700;1,400;1,700&display=swap',
           'https://fonts.googleapis.com/css?family=Rubik:300,400,400i,500,500i&display=swap']
        )
      end

      it 'keeps Gabii Lato available alongside its kit and inherited Michigan fonts' do
        parent = create(:press, subdomain: 'michigan')
        @press = create(:press, subdomain: 'gabii', parent: parent, typekit: 'kki1veq')

        expect(press_font_stylesheets).to eq(
          ['https://use.typekit.net/kki1veq.css',
           'https://fonts.googleapis.com/css?family=Cardo|Lato:300,400&display=swap',
           'https://use.typekit.net/hfw0vui.css']
        )
      end

      it 'keeps Frankel shared Proxima Nova and Muli dependencies without a parent' do
        @press = create(:press, subdomain: 'fia', typekit: '')

        expect(press_font_stylesheets).to eq(
          ['https://use.typekit.net/rqe4rki.css',
           'https://fonts.googleapis.com/css2?family=Crimson+Text:ital,wght@0,400;0,700;1,400;1,700&family=Muli:ital,wght@0,400;0,700;1,400;1,700&display=swap']
        )
      end

      it 'does not add a duplicate reader font for Rekihaku' do
        @press = create(:press, subdomain: 'rekihaku')

        expect(press_font_stylesheets(reader: true)).to eq(
          ['https://fonts.googleapis.com/css?family=Open+Sans:300,400,400i,600,600i,700',
           'https://fonts.googleapis.com/css?family=Roboto+Mono']
        )
      end
    end
  end
end
