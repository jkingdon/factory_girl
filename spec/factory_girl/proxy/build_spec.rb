require 'spec_helper'

describe FactoryGirl::Proxy::Build do
  before do
    @class       = Class.new
    @instance    = "built-instance"

    stub(@class).new { @instance }
    stub(@instance).attribute { 'value' }
    stub(@instance, :attribute=)
    stub(@instance, :owner=)

    @proxy = FactoryGirl::Proxy::Build.new(@class)
  end

  it "should instantiate the class" do
    @class.should have_received.new
  end

  describe "when asked to associate with another factory" do
    before do
      @association = "associated-instance"
      @associated_factory = "associated-factory"
      stub(FactoryGirl).factory_by_name { @associated_factory }
      stub(@associated_factory).run { @association }
      @overrides = { 'attr' => 'value' }
      @proxy.associate(:owner, :user, @overrides)
    end

    it "should create the associated instance" do
      @associated_factory.should have_received.run(FactoryGirl::Proxy::Create, @overrides)
    end

    it "should set the associated instance" do
      @instance.should have_received.method_missing(:owner=, @association)
    end
  end

  it "should run create when building an association" do
    association = "associated-instance"
    associated_factory = "associated-factory"
    stub(FactoryGirl).factory_by_name { associated_factory }
    stub(associated_factory).run { association }
    overrides = { 'attr' => 'value' }
    @proxy.association(:user, overrides).should == association
    associated_factory.should have_received.run(FactoryGirl::Proxy::Create, overrides)
  end

  context "when the association specifies :method => build" do
    before do
      @association = "associated-instance"
      @associated_factory = "associated-factory"
      stub(FactoryGirl).factory_by_name { @associated_factory }
      stub(@associated_factory).run { @association }
      @overrides = { 'attr' => 'value', :method => :build }
    end

    it "association should run build" do
      @proxy.association(:user, @overrides).should == @association
      @associated_factory.should have_received.
        run(FactoryGirl::Proxy::Build, { 'attr' => 'value'})
    end

    it "associate should run build" do
      @proxy.associate(:owner, :user, @overrides)
      @associated_factory.should have_received.
        run(FactoryGirl::Proxy::Build, { 'attr' => 'value'})
      @instance.should have_received.method_missing(:owner=, @association)
    end

    it "associate should run build even when run more than once" do
      @proxy.associate(:owner, :user, @overrides)
      @proxy.associate(:owner, :user, @overrides)
      @associated_factory.should have_received.
        run(FactoryGirl::Proxy::Build, { 'attr' => 'value'}).twice
      @associated_factory.should_not have_received.run(FactoryGirl::Proxy::Create, @overrides)
      @instance.should have_received.method_missing(:owner=, @association).twice
    end
  end

  describe "specifying method" do
    it "defaults to create" do
      @proxy.send(:get_method, nil).should == FactoryGirl::Proxy::Create
    end

    it "can specify create explicitly" do
      @proxy.send(:get_method, :create).should ==
        FactoryGirl::Proxy::Create
    end

    it "can specify build explicitly" do
      @proxy.send(:get_method, :build).should ==
        FactoryGirl::Proxy::Build
    end

    it "complains if method is unrecognized" do
      lambda { @proxy.send(:get_method, :froboznicate) }.
        should raise_error("unrecognized method froboznicate")
    end
  end

  it "should return the built instance when asked for the result" do
    @proxy.result(nil).should == @instance
  end

  it "should run the :after_build callback when retrieving the result" do
    spy = Object.new
    stub(spy).foo
    @proxy.add_callback(:after_build, proc{ spy.foo })
    @proxy.result(nil)
    spy.should have_received.foo
  end

  describe "when setting an attribute" do
    before do
      stub(@instance).attribute = 'value'
      @proxy.set(:attribute, 'value')
    end

    it "should set that value" do
      @instance.should have_received.method_missing(:attribute=, 'value')
    end
  end

  describe "when getting an attribute" do
    before do
      @result = @proxy.get(:attribute)
    end

    it "should ask the built class for the value" do
      @instance.should have_received.attribute
    end

    it "should return the value for that attribute" do
      @result.should == 'value'
    end
  end
end

