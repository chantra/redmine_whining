# redMine - project management software
# Copyright (C) 2009  Emmanuel Bretelle
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

desc <<-END_DESC
Send reminders about issues that were not updated since X days.

Available options:
  * days     => number of days since last update (defaults to 7)
  * tracker  => id of tracker (defaults to all trackers)
  * project  => id or identifier of project (defaults to all projects)
  * debug    => If set, do not send email, just output what would be done

Example:
  rake redmine:send_whining days=7 RAILS_ENV="production"
END_DESC

require File.expand_path(File.dirname(__FILE__) + "/../../../../../config/environment")
require "mailer"
#require "actionmailer"

class WhiningMailer < Mailer
  def whining(user, nbissues, issues_by_project, days)
    set_language_if_valid user.language
    recipients user.mail
    subject l(:mail_subject_whining, :count => nbissues, :days => days )
    content_type "multipart/alternative"

    body = {
          :nbissues => nbissues,
          :issues_by_project => issues_by_project,
          :days => days,
          :issues_url => url_for(:controller => 'issues', :action => 'index', :set_filter => 1, :assigned_to_id => user.id, :sort_key => 'updated_on', :sort_order => 'asc')
    }
    #part :content_type => "text/plain", :body => render_message("whining.text.plain.rhtml", body)
    #part :content_type => "text/html", :body => render_message("whining.text.html.rhtml", body)
    render_multipart('whining', body)
  end

  def self.whinings(options={})
    days = options[:days] || 7
    debug = options[:debug] || 0
    project = options[:project] ? Project.find(options[:project]) : nil
    tracker = options[:tracker] ? Tracker.find(options[:tracker]) : nil

    s = ARCondition.new ["#{IssueStatus.table_name}.is_closed = ? AND #{Issue.table_name}.updated_on <= ? AND #{Issue.table_name}.assigned_to_id IS NOT NULL AND #{Project.table_name}.status=? AND #{User.table_name}.status=?", false, days.day.until.to_date,1,1]
    s << "#{Issue.table_name}.project_id = #{project.id}" if project
    s << "#{Issue.table_name}.tracker_id = #{tracker.id}" if tracker
    issues_by_assignee = Issue.find(:all, 
                                    :include => [:status, :assigned_to, :project, :tracker],
                                    :conditions => s.conditions
                                    ).group_by(&:assigned_to)
    issues_by_assignee.each do |assignee, issues|
      issues_by_project = issues.group_by { |p| p.project }.sort
      if debug != 0
        puts "Sending email to #{assignee.mail}\n"
        issues_by_project.each do | project |
          p = project[0]
          puts "Project: #{p.name}\n"
          project[1].each do | issue |
            puts "\t#{issue.id} - #{issue.subject}\n"
          end
        end
        #issues.each do | issue |
        #  puts "\t#{issue.id} - #{issue.subject}\n"
        #end
        puts "\n"
      else
        deliver_whining(assignee, issues.size, issues_by_project, days) unless assignee.nil?
      end
    end
  end
end

namespace :redmine do
  task :send_whining => :environment do
    options = {}
    options[:days] = ENV['days'].to_i if ENV['days']
    options[:debug] = ENV['debug'].to_i if ENV['debug']
    options[:project] = ENV['project'] if ENV['project']
    options[:tracker] = ENV['tracker'].to_i if ENV['tracker']
    
    WhiningMailer.whinings(options)
  end
end
