require 'spec_helper'

module SandthornDriverSequel
  describe "Configuration" do

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

    context "serialization" do
      let(:driver) do
        SandthornDriverSequel.driver_from_connection(connection: Sequel.sqlite) { |conf|
          conf.event_serializer = :serializater
          conf.event_deserializer = :deserializater
        }
      end

      it "should respond_to save_events method" do
        expect(driver.respond_to?(:save_events)).to be_truthy
      end

      it "should have a configuration event_serializer" do
        expect(driver.instance_variable_get "@event_serializer".to_sym).to eql :serializater
      end

      it "should have a configuration event_deserializer" do
        expect(driver.instance_variable_get "@event_deserializer".to_sym).to eql :deserializater
      end

    end
  end
end