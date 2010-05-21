require_dependency 'issue'
require_dependency 'issue_priority'

module IssuePatch
    def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
    end

    module ClassMethods
    end

    module InstanceMethods
        def whine_days
            return (Time.day.now - self.updated_on) + self.priority.whine_delay
        end
    end
end

module IssuePriorityPatch
    def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
    end

    module ClassMethods
    end

    module InstanceMethods
        def whine_delay
            delay = Setting.plugin_redmine_whining["delay_#{self.id}".intern]
            delay = Setting.plugin_redmine_whining[:delay_default] if not delay
            return Integer(delay)
        end
    end
end
