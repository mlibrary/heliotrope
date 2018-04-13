# frozen_string_literal: true

require_relative '../../api/lackey'

RSpec.describe Lackey do
  lackey = described_class.new([])

  products_initial_count = lackey.products.count
  lessees_initial_count = lackey.lessees.count
  n = 3
  products = []
  lessees = []

  before(:all) do
    n.times do |i|
      products << "product#{i}"
      lackey.find_or_create_product(identifier: products[i])
      lessees << "lessee#{i}@example.com"
      lackey.find_or_create_lessee(identifier: lessees[i])
    end
  end

  after(:all) do
    n.times do |i|
      n.times do |j|
        lackey.unlink(product_identifier: products[i], lessee_identifier: lessees[j])
      end
    end
    n.times do |i|
      lackey.delete_product(identifier: products[i])
      lackey.delete_lessee(identifier: lessees[i])
    end
  end

  it 'works' do
    expect(lackey.products.count).to eq(products_initial_count + n)
    expect(lackey.lessees.count).to eq(lessees_initial_count + n)

    n.times do |i|
      expect(lackey.product_lessees(product_identifier: products[i]).count).to eq(0)
      expect(lackey.lessee_products(lessee_identifier: lessees[i]).count).to eq(0)
    end

    n.times do |i|
      lackey.link(product_identifier: products[0], lessee_identifier: lessees[i])
    end
    expect(lackey.product_lessees(product_identifier: products[0]).count).to eq(n)

    n.times do |i|
      lackey.link(product_identifier: products[i], lessee_identifier: lessees[0])
    end
    expect(lackey.lessee_products(lessee_identifier: lessees[0]).count).to eq(n)

    n.times do |i|
      lackey.unlink(product_identifier: products[0], lessee_identifier: lessees[i])
      lackey.unlink(product_identifier: products[i], lessee_identifier: lessees[0])
    end
    expect(lackey.product_lessees(product_identifier: products[0]).count).to eq(0)
    expect(lackey.lessee_products(lessee_identifier: lessees[0]).count).to eq(0)
  end
end
