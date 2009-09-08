# -*- coding: utf-8 -*-

require 'gluon/metainfo'

module Gluon
  # = memoization for class instances
  # usage:
  #   class Frac
  #     include Gluon::Memoization
  #
  #     def initialize
  #       # to initialize memoize-cache slots, need a call of `Gluon::Memoization#initialize'
  #       super
  #     end
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
    def initialize(*args)
      super

      cache = {}
      self.class.ancestors.reverse_each do |module_or_class|
        cache.update(module_or_class.gluon_metainfo[:memoize_cache])
      end

      for name, factory in cache
        instance_variable_set("@__memoize_cache_#{name}", factory.call)
      end
    end

    module Syntax
      def memoize(name, &cache_factory)
        gluon_metainfo[:memoize_cache][name] = cache_factory || proc{ Hash.new }
        cache_var = "@__memoize_cache_#{name}"
        class_eval(<<-EOF, "#{__FILE__}:MEMOIZE(#{self}\##{name})", __LINE__ + 1)
          alias __no_memoize_#{name} #{name}

          def #{name}(*args, &block)
            if (#{cache_var}.key? args) then
              #{cache_var}[args]
            else
              #{cache_var}[args] = __no_memoize_#{name}(*args, &block)
            end
          end
        EOF

        nil
      end
      private :memoize
    end

    def self.included(module_or_class)
      module_or_class.extend(Syntax)
      super
    end
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
      cache_var = "@__memoize_cache_#{name}"
      instance_variable_set(cache_var, cache)
      instance_eval(<<-EOF, "#{__FILE__}:SINGLE_MEMOIZE(#{self}.#{name})", __LINE__ + 1)
        class << self
          alias __no_memoize_#{name} #{name}

          def #{name}(*args, &block)
            if (#{cache_var}.key? args) then
              #{cache_var}[args]
            else
              #{cache_var}[args] = __no_memoize_#{name}(*args, &block)
            end
          end
        end
      EOF

      nil
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
