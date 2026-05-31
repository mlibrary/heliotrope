module ResqueWeb
  module FailuresHelper
    def each_failure(&block)
      Resque::Failure.each(failure_start_at, failure_per_page, params[:queue], params[:class], &block)
    end

    def failure_date_format
      "%Y/%m/%d %T %z"
    end

    def multiple_failure_queues?
      @multiple_failure_queues ||= Resque::Failure.queues.size > 1
    end

    def failure_queue
      multiple_failure_queues? ? params[:id] : 'failed'
    end

    def failure_queue_name
      @failure_queue_name ||= params[:queue] ? params[:queue] : 'Failed'
    end

    def failure_size
      @failure_size ||= Resque::Failure.count(params[:id], params[:class])
    end

    def failure_per_page
      @failures_per_page ||= params[:class] ? failure_size : 20
    end

    def failure_start_at
      params[:start].to_i
    end

    def failure_end_at
      if failure_start_at + failure_per_page > failure_size
        failure_size
      else
        failure_start_at + failure_per_page
      end
    end

    def failure_class_counts(queue = params[:id])
      classes = Hash.new(0)
      Resque::Failure.each(0, Resque::Failure.count(queue), queue) do |_, item|
        class_name = item['payload']['class'] if item['payload']
        class_name ||= "nil"
        classes[class_name] += 1
      end
      classes.sort_by { |name,_| name }
    end

    def job_arguments(job)
      return 'nil' unless job['payload']
      Array(job['payload']['args']).map { |arg| arg.inspect }.join("\n")
    end
  end
end
