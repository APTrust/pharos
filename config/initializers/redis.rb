Redis.current = Redis.new(url:  ENV['REDIS_URL'] || 'redis://localhost',
                          port: ENV['REDIS_PORT'] || 6379,
                          db:   ENV['REDIS_DB'] || 0)
