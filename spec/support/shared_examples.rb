# frozen_string_literal: true

RSpec.shared_examples "provider failover" do |fail_count|
  it "fails over #{fail_count} times before success" do
    doubles = (1..(fail_count + 1)).map { |i| class_double("Provider#{i}") }
    ChainMail.config.providers = doubles.each_with_index.map do |_d, i|
      { "provider#{i + 1}" => { api_key: "key#{i + 1}" } }
    end
    registry = doubles.each_with_index.to_h { |d, i| [:"provider#{i + 1}", d] }
    allow(ChainMail).to receive(:provider_registry).and_return(registry)
    doubles[0...fail_count].each_with_index do |d, i|
      expect(d).to receive(:deliver)
        .with(mail, { api_key: "key#{i + 1}" })
        .and_raise(StandardError.new("fail#{i + 1}"))
    end
    expect(doubles[fail_count]).to receive(:deliver).with(mail, { api_key: "key#{fail_count + 1}" })
                                                    .and_return({ success: true, error: nil,
                                                                  response: "ok" })
    ChainMail::Delivery.new.deliver!(mail)
  end
end
