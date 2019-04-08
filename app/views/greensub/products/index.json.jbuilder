# frozen_string_literal: true

json.array! @products, partial: 'greensub/products/product', as: :product
