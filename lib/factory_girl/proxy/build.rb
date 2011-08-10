module FactoryGirl
  class Proxy #:nodoc:
    class Build < Proxy #:nodoc:
      def initialize(klass)
        @instance = klass.new
      end

      def get(attribute)
        @instance.send(attribute)
      end

      def set(attribute, value)
        @instance.send(:"#{attribute}=", value)
      end

      def associate(name, factory_name, overrides)
        method = get_method(overrides)
        factory = FactoryGirl.factory_by_name(factory_name)
        set(name, factory.run(method, overrides))
      end

      def association(factory_name, overrides = {})
        method = get_method(overrides)
        factory = FactoryGirl.factory_by_name(factory_name)
        factory.run(method, overrides)
      end

      def result(to_create)
        run_callbacks(:after_build)
        @instance
      end

      def parse_method(overrides)
        method = overrides.delete(:method)
        method ||= :create
        if :build == method
          return Proxy::Build
        elsif :create == method
          return Proxy::Create
        else
          raise "unrecognized method #{method}"
        end
      end

      alias_method :get_method, :parse_method
    end
  end
end
