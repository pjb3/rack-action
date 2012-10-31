module Rack
  module Filters
    def before_filters
      @before_filters ||= if superclass.respond_to?(:before_filters)
        superclass.before_filters.dup
      else
        []
      end
    end

    def before_filter(method)
      unless before_filters.include?(method)
        before_filters << method
      end
    end

    def skip_before_filter(method)
      before_filters.delete(method)
    end

    def after_filters
      @after_filters ||= if superclass.respond_to?(:after_filters)
        superclass.after_filters.dup
      else
        []
      end
    end

    def after_filter(method)
      unless after_filters.include?(method)
        after_filters << method
      end
    end

    def skip_after_filter(method)
      after_filters.delete(method)
    end
  end
end

