require 'redmine'

Redmine::Plugin.register :redmine_whining do
  name 'Redmine Whining plugin'
  author 'Emmanuel Bretelle'
  description 'A plugin to send email alerts when an issue did not get udated since a certain amount of time. This plugin MUST be called from a cronjob.'
  version '0.0.3'

  settings :default => { :delay_default => 7 }, :partial => 'settings/whining_settings'
end
