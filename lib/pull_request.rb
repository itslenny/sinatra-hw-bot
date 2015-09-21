require 'httparty'
require 'pry'

class PullRequest
  attr_accessor :title, :description, :errors, :commits, :url
  def initialize url=''
    # @id = id
    @url = url
    @title = ''
    @description = ''
    @commits = []
    if( !url.empty? )
      res = HTTParty.get(url + "?access_token=" + ENV['access_token'])
      @title = res['title']
      @author = res['user']['login']
      @description = res['body']
      @branch = res['base']['ref']
      commits = HTTParty.get(url + "/commits?access_token=" + ENV['access_token'])

      commits.each do |commit|
       url = commit['url'] + "?access_token=" + ENV['access_token']
       files = HTTParty.get( url )['files'].map{ |f| f['filename'] }
       @commits.push({ sha: commit['sha'], files: files})
     end
   end
 end
 def valid_changes?
  # puts @commits
  @commits.each do |c|
    c[:files].each do |f|
      # puts f
      if f !~ /^#{@author}/i
       return false
     end
   end
 end
 true
end
def valid_title?
  true if @title.match(/w[0-9]{2}d[0-9]{2}/i)
end
def comfort?
  true if @description.match(/comfort:(\s+)?[0-5]/i)
end
def completeness?
  true if @description.match(/completeness:(\s+)?[0-5]/i)
end

def valid_branch?
  true if @branch.casecmp(@author)==0
end

def errors?
  @errors = []
  # unless valid_branch?
  #   @errors << "You must commit to your own branch"
  # end
  unless valid_title?
    @errors << "Title must be in w##d## format."
  end
  unless comfort?
    @errors << "Description must contain comfort value (0-5)."
  end
  unless completeness?
    @errors << "Description must contain completeness value (0-5)."
  end
  unless valid_changes?
    @errors << "You have committed changes outside of your student folder."
  end
  @errors
end
end
