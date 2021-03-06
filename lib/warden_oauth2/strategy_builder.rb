module Warden
  module OAuth2

    #
    # Handles the creation an registration of OAuth2 strategies based on configuration parameters
    # via the Warden::Manager.oauth2 method
    #
    module StrategyBuilder
      extend self


      #
      # Defines the user finder from the access_token for the strategy, receives a block
      # that will be invoked each time you want to find an user via an access_token in your
      # system.
      #
      # @param blk Block that recieves the access_token as a parameter and will return a user or nil
      # 
      def access_token_user_finder(&blk)
        define_method(:_find_user_by_access_token, &blk)
      end

      #
      # Manages the creation and registration of the OAuth2 strategy specified
      # on the keyword
      #
      # @param [Symbol] name of the oauth2 service
      # @param [Walruz::Config] configuration specified on the declaration of the oauth2 service
      #
      def build(keyword, config)
        strategy_class = self.create_oauth2_strategy_class(keyword)
        self.register_oauth2_strategy_class(keyword, strategy_class)
        self.set_oauth2_service_info(strategy_class, config)
        # adding the access_token_user_finder to the strategy
        if self.access_token_user_finders.include?(keyword)
          strategy_class.access_token_user_finder(&self.access_token_user_finders[keyword])
        end
      end

      #
      # Creates the OAuth2 Strategy class from the keyword specified on the declaration of the 
      # oauth2 service. This class will be namespaced inside Warden::OAuth2::Strategy
      #
      # @param [Symbol] name of the OAuth2 service 
      # @return [Class] The class representing the Warden strategy
      #
      # @example
      # 
      #   self.create_oauth2_strategy_class(:twitter) #=> Warden::OAuth2::Strategy::Twitter
      #   # will create a class Warden::OAuth2::Strategy::Twitter that extends from 
      #   # Warden::OAuth2::Strategy
      #
      def create_oauth2_strategy_class(keyword)
        class_name = Warden::OAuth2::Utils.camelize(keyword.to_s) 
        if self.const_defined?(class_name)
          self.const_get(class_name) 
        else
          self.const_set(class_name, Class.new(self))
        end
      end

      #
      # Registers the generated OAuth2 Strategy in the Warden::Strategies collection, the label
      # of the strategy will be the given oauth2 service name plus an '_oauth2' postfix
      #
      # @param [Symbol] name of the OAuth2 service
      #
      # @example
      #   manager.oauth2(:twitter) { |twitter| ... } # will register a strategy :twitter_oauth2
      #
      def register_oauth2_strategy_class(keyword, strategy_class)
        keyword_name = "%s_oauth2" % keyword.to_s
        if Warden::Strategies[keyword_name.to_sym].nil?
          Warden::Strategies.add(keyword_name.to_sym, strategy_class) 
        end
      end

      #
      # Defines a CONFIG constant in the generated class that will hold the configuration information 
      # (consumer_key, consumer_secret and options) of the oauth2 service.
      #
      # @param [Class] strategy class that will hold the configuration info
      # @param [Warden::OAuth2::Config] configuration info of the oauth2 service
      #
      def set_oauth2_service_info(strategy_class, config)
        strategy_class.const_set("CONFIG", config) unless strategy_class.const_defined?("CONFIG")
      end

      protected :create_oauth2_strategy_class,
                :register_oauth2_strategy_class,
                :set_oauth2_service_info

    end

  end
end
