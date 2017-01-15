module PriceHelper
  def get_price(currency)
    @price = HTTParty.get("http://pub.bitstop.co/mobile/data/#{currency}")
    @price = JSON.parse(@price.body)
    @price.each do |object|
      if object['exchange'] == "Coinbase"
        return object['price']
      end
    end
  end
end
