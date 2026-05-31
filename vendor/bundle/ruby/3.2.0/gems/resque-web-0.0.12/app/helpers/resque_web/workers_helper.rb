module ResqueWeb
  module WorkersHelper
    def worker_hosts
      @worker_hosts ||= begin
        hosts = Hash.new { [] }

        Resque.workers.each do |worker|
          host, _ = worker.to_s.split(':')
          hosts[host] += [worker.to_s]
        end

        hosts
      end
    end
  end
end
