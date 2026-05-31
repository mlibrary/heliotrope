module ResqueWeb
  module StatsHelper
    def resque_info
      Resque.info.sort_by { |i| i[0].to_s }
    end

    def redis_info
      Resque.redis.redis.info.to_a.sort_by { |i| i[0].to_s }
    end

    def redis_key_type(key)
      Resque.redis.type(key)
    end

    def redis_key_size(key)
      # FIXME: there's a potential race in this method if a key is modified
      # "in flight". Not sure how to fix it, unfortunately :(
      case redis_key_type(key)
      when 'none'
        0
      when 'list'
        Resque.redis.llen(key)
      when 'set'
        Resque.redis.scard(key)
      when 'string'
        string = Resque.redis.get(key)
        string ? string.length : 0
      when 'zset'
        Resque.redis.zcard(key)
      end
    end

    def redis_get_array(key, start=0)
      case redis_key_type(key)
      when 'none'
        []
      when 'list'
        Resque.redis.lrange(key, start, start + 20)
      when 'set'
        Resque.redis.smembers(key)[start..(start + 20)]
      when 'string'
        [Resque.redis.get(key)]
      when 'zset'
        Resque.redis.zrange(key, start, start + 20)
      when 'hash'
        Resque.redis.hgetall(key)
      end
    end

    def current_subtab?(name)
      params[:action] == name.to_s
    end
  end
end
