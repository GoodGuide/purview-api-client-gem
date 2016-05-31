module SpecHelpers
  def temporary_name(name)
    "#{temporary_name_prefix}#{name}"
  end

  def temporary_name_prefix
    "test_only_delete_me__"
  end

  def clear_all_temporary_entities(entities)
    entities_to_remove = entities.select do |entity|
      size = temporary_name_prefix.size
      entity.name[0...size] == temporary_name_prefix
    end

    entities_to_remove.each(&:destroy!)
  end
end
