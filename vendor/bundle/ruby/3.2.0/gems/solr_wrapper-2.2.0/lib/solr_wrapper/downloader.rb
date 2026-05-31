require 'ruby-progressbar'

module SolrWrapper
  class Downloader
    def self.fetch_with_progressbar(url, output)
      pbar = SafeProgressBar.new(title: File.basename(url), total: nil, format: '%t: |%B| %p%% (%e )')
      open(url, content_length_proc: ->(bytes) { pbar.total = bytes }, progress_proc: ->(bytes) { pbar.progress = bytes }) do |io|
        IO.copy_stream(io, output)
      end
    rescue OpenURI::HTTPError => e
      raise SolrWrapperError, "Unable to download solr from #{url}\n#{e.message}: #{e.io.read}"
    end

    class SafeProgressBar < ProgressBar::Base
      def progress=(new_progress)
        self.total = new_progress if total <= new_progress
        super
      end

      def total=(new_total)
        super if new_total && new_total > 0
      end
    end
  end
end
