module MonkeySlugs
  ROUTE = { :id => /.*/ }

  def self.sluggify klass, options={}
    klass.send :include, MonkeySlugs::Slug
    klass.send :define_method, :friendly_name, options[:how]
    if options[:uuid].present?
      klass.send :define_method, :set_uuid, options[:uuid]
    end
  end

  module Slug
    extend ActiveSupport::Concern

    included do
      before_create :set_uuid
    end

    def set_uuid
      self.uuid ||= SecureRandom.hex(8)
    end

    def to_param
      "#{friendly_name}/#{uuid}"
    end

    def correct_friendly_name? id
      self.class.extract_friendly_name(id) == friendly_name
    end

    module ClassMethods
      # There's probably a better way to do this.
      def extract_uuid id
        id.split('/').last
      end

      def extract_friendly_name id
        id.split('/').first
      end

      def has_uuid? id
        id.include?('/')
      end

      def find id, *args, &block
        if has_uuid?(id)
          uuid = extract_uuid(id)
          where(:uuid => uuid).first || super
        else
          super
        end
      end
    end
  end
end
