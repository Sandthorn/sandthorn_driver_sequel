require 'spec_helper'

module SandthornDriverSequel
  describe "Configuration" do

    context "default configuration" do

      let(:driver) { SandthornDriverSequel.driver_from_connection connection: Sequel.sqlite }

      it "should respond_to save_events method" do
        expect(driver.respond_to?(:save_events)).to be_truthy
      end

      it "should have the default event_serializer" do
        expect(driver.instance_variable_get "@event_serializer".to_sym).to be_a Proc
      end

      it "should have the default event_deserializer" do
        expect(driver.instance_variable_get "@event_deserializer".to_sym).to be_a Proc
      end

      context "change global configuration" do
        before do
          SandthornDriverSequel.configure { |conf|
            conf.event_serializer = :serializer_event_global
            conf.event_deserializer = :deserializer_event_global
          }
        end

        after do
          #Set the default configuration after test
          SandthornDriverSequel.configure { |conf|
            conf.event_serializer = -> (data) { YAML.dump(data) }
            conf.event_deserializer = -> (data) { YAML.load(data) }
          }
        end

        it "should have the new event_serializer" do
          expect(driver.instance_variable_get "@event_serializer".to_sym).to eql :serializer_event_global
        end

        it "should have the default event_deserializer" do
          expect(driver.instance_variable_get "@event_deserializer".to_sym).to eql :deserializer_event_global
        end

      end
    end

    context "session configuration" do
      let(:driver) do
        SandthornDriverSequel.driver_from_connection(connection: Sequel.sqlite) { |conf|
          conf.event_serializer = :event_serializer
          conf.event_deserializer = :event_deserializer
        }
      end

      it "should respond_to save_events method" do
        expect(driver.respond_to?(:save_events)).to be_truthy
      end

      it "should have a configuration event_serializer" do
        expect(driver.instance_variable_get "@event_serializer".to_sym).to eql :event_serializer
      end

      it "should have a configuration event_deserializer" do
        expect(driver.instance_variable_get "@event_deserializer".to_sym).to eql :event_deserializer
      end

    end


  end
end