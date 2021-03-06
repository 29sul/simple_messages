module SimpleMessages
  module ActionView
    extend ActiveSupport::Concern

    def simple_messages(options = {})
      options.reverse_merge! flash_messages: true, validation_messages: true

      html = ''.html_safe

      html << simple_messages_flash(options) if options.delete(:flash_messages)

      html << simple_messages_validation(options) if options.delete(:validation_messages)

      html
    end

    def simple_messages_flash(options = {})
      html = flash.collect do |kind, content|
        builder = Builder.new options.reverse_merge(kind: kind, body: content)

        builder.to_html
      end

      flash.clear if flash.any?

      html.join.html_safe
    end

    def simple_messages_objects
      simple_messages_models.collect do |model_name|
        object = instance_variable_get("@#{model_name}")

        object if simple_messages_object_has_errors? object
      end.compact
    end

    def simple_messages_validation(options = {})
      simple_messages_objects.collect do |object|
        title = I18n.t('errors.template.header', count: object.errors.full_messages.count, model: object.class.model_name.human)

        builder = Builder.new options.reverse_merge(kind: :error, body: object.errors.full_messages, header: title)

        builder.to_html
      end.join.html_safe
    end

    def js_simple_messages
      "SimpleMessages.flash('#{j simple_messages}');".html_safe
    end

    def js_simple_messages_alert(messages = [])
      "SimpleMessages.alert(#{messages.to_json});".html_safe
    end

    private
    def simple_messages_object_has_errors?(object)
      object.present? and (
        (object.errors.respond_to? :any? and object.errors.any?) or
        (object.errors.respond_to? :empty? and !object.errors.empty?)
      )
    end

  end
end
