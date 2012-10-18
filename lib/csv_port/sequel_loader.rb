require 'sequel'

module CSVPort

  module SequelLoader

    # This module runs on top of the Sequel gem and provides several services.  It helps in the construction of databases.
    # The services provided are:
    #
    # - A method `load` that takes a model and attempts to load it into the database.  If a match
    # in the database is detected, the current record is updated to reflect the values passed in through
    # this model.  Otherwise, a new record is created. This function takes an array in the option :match_on,
    # what fields to use in attempting to find a match.  The default is `:all`.  This means that a new record
    # will be created unless all fields match.  If all fields match, then nothing happens.
    #
    # - A method `link` that takes an array of models and attempts to link them via a junction table.
    # This relies on a naming convention in which junction tables are named Table1Table2...TableNRel
    # where the tables are in alphabetical order.  The models must contain their primary keys in a field
    # called 'id'.  No other fields are used.
    #
    # - A method `direct_link` that performs a direct foreign key linking.  This takes two models and a symbol field name.
    # The first model, `many_model`, is at the many end of the foreign key link.  The second model, `one_model`, is at the
    # one end of the foreign key link.  The field name is the name in the many model that holds the key of the one model.
    # This method searches the table of the one model with for the first entry matching the contents of the one_model and
    # extracts its foreign key.  An exception is thrown if no match is present.
    
    class MissingModelError < StandardError
    end

    ### LOAD

    def load_model(model, opts={})  # :match_on is an array or :all
      match_fields = (opts[:match_on] or :all)
      model_to_match = get_model_to_match(model, match_fields)
      name = model.to_s
      table_name = model.class.to_s
      print "Attempting to add %s to %s..." % [name, table_name]
      existing_model = model.values.empty? ? nil : match(model_to_match)  # don't match an empty model
      if existing_model and match_fields == :all
        model = existing_model
        puts "already present"
      elsif existing_model
        existing_model.update(model.values)
        model = existing_model
        puts "match is present, record updated"
      else
        model = model.save
        puts "newly added"
      end
      return model
    end

    def get_model_to_match(model, match_fields)
      if match_fields == :all
        model
      elsif match_fields == :none
        nil
      else
        #binding.pry
        match_fields = [match_fields] unless match_fields.class == Array
        values = model.values.select { |field, value| match_fields.include?(field) }
        model.class.new(values)
      end
    end

    ### LINK

    # each model passed to link should already match exactly one model in the DB
    def link(*models)
      binding.pry if models.select{ |model| model.nil? }.any?
      properties = (models.last.class == Hash ? models.pop : {})
      models = fill_model_ids(models)
      link_model = create_link_model(models, properties)
      model_strs = models.map { |m| m.class.to_s + " " + m.id.to_s }
      print "Attempting to link " + model_strs.join(" to ") + "..." 
      if link_model.class[link_model.values]
        #binding.pry
        link_model = match(link_model)
        puts "link already present"
      else
        link_model = insert(link_model)
        puts "newly linked"
      end
      link_model
    end

    def fill_model_ids(models)
      models.map do |model|
        model.id ? model : match(model)
      end
    end

    def create_link_model(models, properties={})
      link_class = get_link_class(models)
      self_link = (models.first.class == models.last.class)
      model_id_pairs = models.map.with_index do |model, i|
        key = model.class.to_s + (self_link ? "#{i+1}_id" : "_id") 
        [key, model.id]
      end
      values = Hash[ model_id_pairs ]
      values.update(properties)
      link_model = link_class.new(values)
    end

    def get_link_class(models)
      binding.pry if models.first.class == Array
      link_class_str = models.map{|m| m.class.to_s}.join('') + 'Rel'
      link_class = eval(link_class_str)
    rescue Exception => e
      binding.pry
    end

    ### DIRECT LINK
    
    def direct_link(many_model, one_model, foreign_key_field)  # child is the foreign-key holder; parent has key primary id
      one_model = match(one_model)
      raise MissingModelError.new if not one_model
      child_model.update({foreign_key_field => one_model.id})
    end

    ### HELPERS
    
    def insert(model)
      model.save
    end

    def match(model)
      model.class[model.values]
    end

    #def get_model(klass, values, opts={})
      #match = opts[:match] or nil  # match will attempt to match to the DB and throw an exception if the record is not present
      #model = klass.new(values)
      #if match == :soft
        #model = match(model) or model
      #elsif match == :hard
        #model = match(model) or nil
      #end
      #return model
    #end

    #def update_model(klass, retrieval_values, update_values)
      #model = (klass[retrieval_values] or klass.new)
      #model.update
      #raise HippoDataError.new("missing_#{klass.to_s.downcase}_reference".to_sym, values) unless model
      #return model
    #rescue Sequel::InvalidValue => e
      #raise HippoDataError.new(:badly_formatted_field, message: e.inspect)
    #end

  end

end
