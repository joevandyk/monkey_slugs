module MonkeySlugs
  ROUTE = { :id => /.*/ }

  def self.sluggify klass, options={}
    klass.send :include, MonkeySlugs::Slug
  end

  module Slug
    extend ActiveSupport::Concern

    included do
      before_create   :set_uuid_column
      class_attribute :uuid_column_name
      class_attribute :has_friendly_name

      self.uuid_column_name = :uuid
      self.has_friendly_name = true
    end

    def set_uuid_column
      self.uuid_column ||= SecureRandom.hex(5)
    end

    def to_param
      if self.class.has_friendly_name?
        "#{friendly_name}/#{uuid_column}"
      else
        send self.class.uuid_column_name
      end
    end

    def uuid_column
      send self.class.uuid_column_name
    end

    def uuid_column= value
      write_attribute self.class.uuid_column_name, value
    end

    def correct_friendly_name? id
      if self.class.has_friendly_name?
        self.class.extract_friendly_name(id) == friendly_name
      else
        uuid_column == id
      end
    end


    def friendly_name
      if respond_to?(:name)
        name
      elsif respond_to?(:title)
        title
      else
        to_s
      end
    end

    module ClassMethods
      # There's probably a better way to do this.
      def extract_uuid id
        if has_friendly_name?
          id.split('/').last
        else
          id
        end
      end

      def has_friendly_name?
        has_friendly_name.inspect
      end

      def extract_friendly_name id
        if has_friendly_name?
          id.split('/')[0..-2].join('/')
        else
          id
        end
      end

      def has_uuid? id
        !has_friendly_name? || id.include?('/')
      end

      # What's the correct way to do this?
      def find id, *args, &block
        if has_uuid?(id)
          uuid = extract_uuid(id)
          where(uuid_column_name => uuid).first || super
        else
          super
        end
      end
    end
  end
end
