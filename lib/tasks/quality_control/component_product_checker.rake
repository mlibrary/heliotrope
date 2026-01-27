# frozen_string_literal: true

desc 'output a report of books without components and/or are not in products'
namespace :heliotrope do
  task component_product_checker: :environment do
    Marc::DirectoryMapper.press_group_key.each do |press, group_key|
      products = Greensub::Product.where(group_key: group_key)

      if products.count.zero?
        p "Press: #{press} - No Products Found!"
      elsif products.count == 1
        # This press only has one product: amherst, leverpress, etc
        monograph_ids = published_not_forthcoming_monographs(press)
        components = products.first.components.pluck(:noid)
        missing_components = monograph_ids - components
        p "Press: #{press} - Product: #{products.first.name} - Missing Components: #{missing_components.count}"
        if missing_components.any?
          missing_components.each do |noid|
            p "  Missing Component Noid: #{noid}"
          end
        end
      else
        # These presses have multiple products: michigan, bar, etc
        # heb too because there's a heb_oa product.
        monograph_ids = published_not_forthcoming_monographs(press)
        missing_components = monograph_ids.dup
        products.each do |product|
          components = product.components.pluck(:noid)
          missing_components -= components
        end
        p "Press: #{press} - Multiple Products - Missing Components: #{missing_components.count}"
        if missing_components.any?
          missing_components.each do |noid|
            p "  Missing Component Noid: #{noid}"
          end
        end
      end
      p "-----------------------------------"
    end
  end
end

# We want books that are published and not forthcoming where forthcoming means the ebook is
# still in draft while the monograph is public.
# If a monograph has no epub or pdf_ebook, then we're going to skip it. This means books like
# "ESC" in michigan, which only has audio mp3 but actually IS in a product will be skipped.
# We will also skip forthcoming books, so public Monographs where the ebook is still draft or the
# ebook isn't a FeaturedRepresentative yet.
# Until we have a "proper" way to identify forthcoming books, this is the best we can do.
# Additionally, we're going to skip Monographs and ebooks that are tombstoned in the logic, even
# though, as of January 2026 we don't have consistent business rules whether it’s better for
# tombstoned items to remain in thir product(s), or get removed
def published_not_forthcoming_monographs(press)
  noids = []
  ActiveFedora::SolrService.query("press_sim:#{press} AND has_model_ssim:Monograph AND visibility_ssi:open AND -tombstone_ssim:yes", rows: 100_000).each do |doc|
    ebook_ids = FeaturedRepresentative.where(work_id: doc['id'], kind: ['epub', 'pdf_ebook']).pluck(:file_set_id)
    next if ebook_ids.empty?
    ebook_docs = ActiveFedora::SolrService.query("{!terms f=id}#{ebook_ids.join(',')}", fl: ['visibility_ssi', 'tombstone_ssim'], rows: 100_000)
    noids << doc['id'] if ebook_docs.any? { |ed| ed['visibility_ssi'] == 'open' && ed['tombstone_ssim']&.first != 'yes' }
  end
  noids
end
