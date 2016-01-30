require 'spec_helper'

module SandthornDriverSequel
  describe "Configuration" do

    let(:driver) { SandthornDriverSequel.driver_from_connection connection: Sequel.sqlite }

    it "should respond_to save_events method" do
      expect(driver.respond_to?(:save_events)).to be_truthy
    end

    it "should have the default event_serializer" do
      expect(driver.event_serializer).to be_a Proc
    end

    it "should have the default event_deserializer" do
      expect(driver.event_deserializer).to be_a Proc
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
        expect(driver.event_serializer).to eql :serializater
      end

      it "should have a configuration event_deserializer" do
        expect(driver.event_deserializer).to eql :deserializater
      end

    end
  end
end