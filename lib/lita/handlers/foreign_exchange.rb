module Lita
  module Handlers
    class ForeignExchange < Handler
      # Almost copy&paste from https://github.com/webdestroya/lita-stocks/blob/master/lib/lita/handlers/stocks.rb

      route %r{^ex ([\w .-_]+)$}i, :foreign_exchange_info, help: {
        "ex <symbol>" => "Returns foreign exchange rate information about the provided ex symbol. ex) USDJPY"
      }

      def foreign_exchange_info(response)
        symbol = response.matches[0][0]
        data = get_foreign_exchange_data(symbol)
        response.reply format_response(symbol, data)
      rescue Exception => e
        Lita.logger.error("Foreign exchange information error: #{e.message}")
        response.reply "Sorry, but there was a problem retrieving foreign exchange information."
      end

      private

      def get_foreign_exchange_data(symbol)
        resp = http.get("https://www.google.com/finance?q=#{symbol}&infotype=infoquoteall")
        raise 'RequestFail' unless resp.status == 200
        parse_foreign_exchange_data(symbol, resp.body)
      end

      def parse_foreign_exchange_data(symbol, body)
        value = body.match(%r{<span class=bld>(.*)</span>})[1]
        rate, to = value.split(' ')
        {
          rate_s: rate,
          rate:   rate.to_f,
          from:   symbol[0..2],
          to:     symbol[3..5],
        }
      rescue => e
        { error: e }
      end

      def format_response(symbol, data)
        line = []
        line << "1 #{data[:from]}: #{data[:rate]} #{data[:to]}"
      end
    end

    Lita.register_handler(ForeignExchange)
  end
end
