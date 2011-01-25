require 'redmine'

Redmine::Plugin.register :redmine_whining do
  name 'Redmine Whining plugin'
  author 'Emmanuel Bretelle'
  description 'A plugin to send email alerts when an issue did not get udated since a certain amount of time. This plugin MUST be called from a cronjob.'
  version '0.0.5'
end
