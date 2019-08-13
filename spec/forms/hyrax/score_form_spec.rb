# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Score`
require 'rails_helper'

RSpec.describe Hyrax::ScoreForm do
  let(:press) { create(:press, subdomain: Services.score_press) }
  let(:admin) { create(:press_admin, press: press) }
  let(:ability) { Ability.new(admin) }
  let(:score) { Score.new }
  let(:form) { described_class.new(score, ability, Hyrax::ScoresController) }

  describe "#select_press" do
    # Currently only the single "score press" is allowed to make scores
    subject { form.select_press }

    let(:press2) { create(:press) }

    before do
      create(:role, resource: press2, user: admin, role: 'admin')
    end

    it 'contains only the score press' do
      expect(subject.count).to eq 1
      expect(subject[press.name]).to eq press.subdomain
    end
  end
end
