# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Greensub do
  subject(:greensub) { described_class }

  let(:actor) { create(:user) }
  let(:individual) { create(:individual, identifier: actor.email) }
  let(:institutions) { [create(:institution), create(:institution)] }
  let(:products) { [create(:product), create(:product), create(:product)] }

  before do
    clear_grants_table
    allow(actor).to receive(:individual).and_return(individual)
    allow(actor).to receive(:institutions).and_return(institutions)
  end

  it { expect { greensub.actor_products(nil) }.to raise_error(NoMethodError) }

  it 'works' do
    expect(greensub.actor_products(actor)).to be_empty
    expect(greensub.subscriber_products(individual)).to be_empty
    expect(greensub.subscriber_products(institutions[0])).to be_empty
    expect(greensub.subscriber_products(institutions[1])).to be_empty
    expect(greensub.product_subscribers(products[0])).to be_empty
    expect(greensub.product_subscribers(products[1])).to be_empty
    expect(greensub.product_subscribers(products[2])).to be_empty

    greensub.subscribe(individual, products[0])
    expect(greensub.subscribed?(individual, products[0])).to be true
    expect(greensub.subscriber_products(individual)).to match_array([products[0]])
    expect(greensub.product_subscribers(products[0])).to match_array([individual])
    expect(greensub.actor_products(actor).count).to eq 1
    expect(greensub.actor_products(actor)).to match_array([products[0]])

    greensub.subscribe(institutions[0], products[1])
    expect(greensub.subscribed?(institutions[0], products[1])).to be true
    expect(greensub.subscriber_products(institutions[0])).to match_array([products[1]])
    expect(greensub.product_subscribers(products[1])).to match_array([institutions[0]])
    expect(greensub.actor_products(actor).count).to eq 2
    expect(greensub.actor_products(actor)).to match_array([products[0], products[1]])

    greensub.subscribe(institutions[1], products[2])
    expect(greensub.subscribed?(institutions[1], products[2])).to be true
    expect(greensub.subscriber_products(institutions[1])).to match_array([products[2]])
    expect(greensub.product_subscribers(products[2])).to match_array([institutions[1]])
    expect(greensub.actor_products(actor).count).to eq 3
    expect(greensub.actor_products(actor)).to match_array([products[0], products[1], products[2]])

    greensub.subscribe(individual, products[1])
    expect(greensub.subscribed?(individual, products[1])).to be true
    expect(greensub.subscriber_products(individual)).to match_array([products[0], products[1]])
    expect(greensub.product_subscribers(products[1])).to match_array([individual, institutions[0]])
    expect(greensub.actor_products(actor).count).to eq 3
    expect(greensub.actor_products(actor)).to match_array([products[0], products[1], products[2]])

    greensub.subscribe(institutions[0], products[0])
    expect(greensub.subscribed?(institutions[0], products[0])).to be true
    expect(greensub.subscriber_products(institutions[0])).to match_array([products[0], products[1]])
    expect(greensub.product_subscribers(products[0])).to match_array([individual, institutions[0]])
    expect(greensub.actor_products(actor).count).to eq 3
    expect(greensub.actor_products(actor)).to match_array([products[0], products[1], products[2]])

    greensub.unsubscribe(individual, products[0])
    expect(greensub.subscribed?(individual, products[0])).to be false
    expect(greensub.subscriber_products(individual)).to match_array([products[1]])
    expect(greensub.product_subscribers(products[0])).to match_array([institutions[0]])
    expect(greensub.actor_products(actor).count).to eq 3
    expect(greensub.actor_products(actor)).to match_array([products[0], products[1], products[2]])

    greensub.unsubscribe(institutions[0], products[0])
    expect(greensub.subscribed?(institutions[0], products[0])).to be false
    expect(greensub.subscriber_products(institutions[0])).to match_array([products[1]])
    expect(greensub.product_subscribers(products[0])).to be_empty
    expect(greensub.actor_products(actor).count).to eq 2
    expect(greensub.actor_products(actor)).to match_array([products[1], products[2]])

    greensub.unsubscribe(institutions[0], products[1])
    expect(greensub.subscribed?(institutions[0], products[1])).to be false
    expect(greensub.subscriber_products(institutions[0])).to be_empty
    expect(greensub.product_subscribers(products[1])).to match_array([individual])
    expect(greensub.actor_products(actor).count).to eq 2
    expect(greensub.actor_products(actor)).to match_array([products[1], products[2]])

    greensub.unsubscribe(individual, products[1])
    expect(greensub.subscribed?(individual, products[1])).to be false
    expect(greensub.subscriber_products(individual)).to be_empty
    expect(greensub.product_subscribers(products[1])).to be_empty
    expect(greensub.actor_products(actor).count).to eq 1
    expect(greensub.actor_products(actor)).to match_array([products[2]])

    greensub.unsubscribe(institutions[1], products[2])
    expect(greensub.subscribed?(institutions[1], products[2])).to be false
    expect(greensub.subscriber_products(institutions[1])).to be_empty
    expect(greensub.product_subscribers(products[2])).to be_empty
    expect(greensub.actor_products(actor).count).to eq 0
    expect(greensub.actor_products(actor)).to be_empty
  end
end
