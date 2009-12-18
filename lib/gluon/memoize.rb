# -*- coding: utf-8 -*-

module Gluon
  # = memoization for class instances
  # usage:
  #   class Frac
  #     extend Gluon::Memoization
  #
  #     def call(n)
  #       if (n > 0) then
  #         n * call(n - 1)
  #       else
  #         1
  #       end
  #     end
  #
  #     memoize :call
  #   end
  #
  module Memoization
    def memoize(name, &cache_factory)
      cache_factory = proc{ Hash.new } unless cache_factory
      cache_ivar = "@__memoize_cache_#{name}".to_sym

      class_eval{
        orig_method = instance_method(name)
        remove_method(name)

        define_method(name) {|*args, &block|
          unless (cache = instance_variable_get(cache_ivar)) then
            cache = cache_factory.call
            instance_variable_set(cache_ivar, cache)
          end

          if (cache.key? args) then
            cache[args]
          else
            cache[args] = orig_method.bind(self).call(*args, &block)
          end
        }
      }

      nil
    end
    private :memoize
  end

  # = memoization for single instance
  # usage:
  #   class Frac
  #     def call(n)
  #       if (n > 0) then
  #         n * call(n - 1)
  #       else
  #         1
  #       end
  #     end
  #   end
  #
  #   f = Frac.new
  #   f.extend Gluon::SingleMemoization
  #   f.memoize :call
  #
  module SingleMemoization
    def memoize(name, cache={})
      m = Module.new
      m.module_eval{
        define_method(name) {|*args, &block|
          if (cache.key? args) then
            cache[args]
          else
            cache[args] = super(*args, &block)
          end
        }
      }
      extend(m)

      nil
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
