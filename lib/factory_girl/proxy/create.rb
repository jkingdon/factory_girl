module FactoryGirl
  class Proxy #:nodoc:
    class Create < Build #:nodoc:
      def result(to_create)
        run_callbacks(:after_build)
        if to_create
          to_create.call(@instance)
        else
          @instance.save!
        end
        run_callbacks(:after_create)
        @instance
      end

      private
      def get_strategy(overrides)
        overrides.delete(:build_create)
        Proxy::Create
      end
    end
  end
end
