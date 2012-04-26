class MonkeySlugs
  ROUTE = { :id => /.*/ }

  class_attribute :to_param
  self.to_param = true

  def self.sluggify klass, options={}
    options = {
      :use_uuid             => true,
      :friendly_name_source => nil,
      :slug_column          => :uuid,
      :update_slug_on_save  => false
    }.merge!(options)

    klass.send :include, MonkeySlugs::Slug

    klass.use_uuid             = options[:use_uuid]
    klass.friendly_name_source = options[:friendly_name_source]
    klass.slug_column          = options[:slug_column]
  end

  module Slug
    extend ActiveSupport::Concern

    included do
      class_attribute :use_uuid
      class_attribute :friendly_name_source
      class_attribute :slug_column
      before_save :update_slug_column
    end

    def to_param
      if MonkeySlugs.to_param
        if self.class.use_uuid?
          "#{slug_value}/#{friendly_name}"
        else
          slug_value
        end
      else
        super
      end
    end

    def update_slug_column
      if use_uuid?
        if slug_value.blank?
          self.slug_value = generate_uuid
        end
      else
        f = friendly_name
        if slug_value != f
          self.slug_value = f
        end
      end
    end

    def generate_uuid
      SecureRandom.hex(5)
    end

    def slug_value
      send(slug_column)
    end

    def slug_value= value
      write_attribute self.slug_column, value
    end

    def correct_friendly_name? id
      if use_uuid?
        self.class.extract_friendly_name(id) == friendly_name
      else
        slug_value == id
      end
    end

    def friendly_name
      if friendly_name_source
        return send(friendly_name_source).parameterize
      end

      if respond_to?(:name)
        name
      elsif respond_to?(:title)
        title
      else
        to_s
      end.parameterize
    end

    module ClassMethods
      # There's probably a better way to do this.
      def extract_uuid id
        if use_uuid?
          id.split('/').first
        else
          id
        end
      end

      def extract_friendly_name id
        if use_uuid?
          id.split('/')[1..-1].join('/')
        else
          id
        end
      end

      # What's the correct way to do this?
      def find_by_slug id
        uuid = extract_uuid(id)
        result = where(slug_column => uuid)
        result.first || raise(ActiveRecord::RecordNotFound.new("couldn't find #{ id }"))
      end
    end
  end
end
