# frozen_string_literal: true

module CounterReporter
  class Counter4BookReport
    attr_reader :params

    def initialize(params)
      @params = params
    end

    # We're going to *temporarily* present a COUNTER4 BR2-ish report
    # See HELIO-2386
    # This report is going to work a little differently than the COUNTER5
    # reports.
    def report
      results = results_by_month
      items = []
      file_sets = presenters_for(Hyrax::FileSetPresenter, unique_noids(results))
      monographs = presenters_for(Hyrax::MonographPresenter, unique_parent_noids(results))

      # Don't include multimedia file_sets
      remove_multimedia(results, file_sets)
      # Reduce counts to title level, not item
      results_by_parent(results)

      # make the weird header
      header = []
      cols = 7 + results.keys.count
      header << ["Book Report 2 (R2)", "Number of Successful Section Requests by Month and Title"] + columns(cols - 2)
      header << [institution_name, "Section Type:"] + columns(cols - 2)
      header << ["", "Chapter, EReader"] + columns(cols - 2)
      header << ["Period covered by Report"] + columns(cols - 1)
      header << ["#{@params.start_date.year}-#{@params.start_date.month} to #{@params.end_date.year}-#{@params.end_date.month}"] + columns(cols - 1)
      header << ["Date run:"] + columns(cols - 1)
      header << [Time.zone.today.iso8601] + columns(cols - 1)
      header << ["", "Publisher", "Platform", "Book DOI", "Proprietary Identifier", "ISBN", "Reporing Period Total"] + results.keys

      # make the weird totals row
      totals = []
      totals << "Total for all titles"
      totals << ""
      totals << "Fulcrum/#{@params.press.name}"
      totals << ""
      totals << ""
      totals << ""
      totals << results.values.map { |r| r.map { |i| i[1] }.compact.sum }.sum
      results.values.each do |r|
        totals << r.map { |i| i[1] }.compact.sum
      end

      items << totals

      # finally make the title rows
      monographs.values.sort_by(&:page_title).each do |presenter|
        item = []
        item << presenter.page_title
        item << presenter.publisher.first
        item << "Fulcrum/#{@params.press.name}"
        item << presenter.citable_link
        item <<  presenter.id
        item <<  presenter.isbn.join("; ")
        item <<  results.values.map { |r| r[presenter.id] }.compact.sum
        results.each do |result|
          # item << result[1][presenter.id].presence || 0
          item << if result[1][presenter.id].present? # rubocop:disable Rails/Presence
                    result[1][presenter.id]
                  else
                    0
                  end
        end

        items << item
      end

      items = [[]] if items.empty?

      { header: header, items: items }
    end

    def columns(cols)
      Array.new(cols, "")
    end

    def institution_name
      if @params.institution == '*'
        "All Institutions"
      else
        Greensub::Institution.where(identifier: @params.institution).first&.name
      end
    end

    def remove_multimedia(results, file_sets)
      results.each do |k, v|
        v.keys.each do |ids|
          next if file_sets[ids[1]].blank?
          results[k].delete(ids) if file_sets[ids[1]].multimedia?
        end
      end
      results
    end

    def results_by_parent(results)
      results.clone.each do |k, v|
        v.clone.each do |ids, count|
          results[k][ids[0]] = if results[k][ids[0]].present?
                                 results[k][ids[0]] + count
                               else
                                 results[k][ids[0]] = count
                               end
          results[k].delete(ids)
        end
      end
      results
    end

    def results_by_month
      results = ActiveSupport::OrderedHash.new
      this_month = @params.start_date
      until this_month > @params.end_date
        item_month = this_month.strftime("%b") + "-" + this_month.year.to_s
        results[item_month] = {}
        results[item_month] = counter4_br2(this_month)
        this_month = this_month.next_month
      end
      results
    end

    def unique_noids(results)
      noids = []
      results.values.each do |result|
        noids.concat(result.keys.map { |r| r[1] })
      end
      noids.uniq
    end

    def unique_parent_noids(results)
      noids = []
      results.values.each do |result|
        noids.concat(result.keys.map { |r| r[0] })
      end
      noids.uniq
    end

    def presenters_for(hyrax_presenter, noids)
      presenters = {}
      until noids.empty?
        Hyrax::PresenterFactory.build_for(ids: noids.shift(999), presenter_class: hyrax_presenter, presenter_args: nil).map do |p|
          presenters[p.id] = p
        end
      end
      presenters
    end

    def counter4_br2(month, access_type = @params.access_types.first)
      CounterReport.institution(@params.institution)
                   .requests
                   .access_type(access_type)
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press)
                   .where(model: "FileSet")
                   .group('parent_noid', 'noid')
                   .count
    end
  end
end
