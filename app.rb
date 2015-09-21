## SETUP ##
#
# GENERATE A SECRET
#   ruby -rsecurerandom -e 'puts SecureRandom.hex(20)'
#
#
# GITHUB:
#   Create homework repo
#     - add .gitignore to the root or .DS_STORE modifications in
#       the project root will cause pull requests to be rejected
#       the .gitignore in this repo should work well.
#   Create an access token: https://github.com/settings/tokens
#   Create a webhook in the settings tab of your homework repo
#     - url = this app root
#     - content type = json
#     - secret = the one you generated
#     - events = "let me specify" > "Pull Requests"
#
#
# HEROKU CONFIG:
#   access_token=your_github_access_token_here
#   GIT_SECRET=your_github_webhook_secret_here
#
#

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require_relative 'lib/pull_request'

get '/' do
  "Hello World!"
end

post '/' do
  # puts "@" * 50
  begin
    body = request.body.read
    verify_signature(body)
    res = JSON.parse(body)
    if res['action'] == 'opened'
      return "no pull request" unless res.key?('pull_request') && res['pull_request'].key?('url')
      url = res['pull_request']['url']
      issue_url = res['pull_request']['issue_url']
      @pr = PullRequest.new(url)
      if @pr.errors? != []
        data = {
         state:'closed'
        }
        res = HTTParty.patch(url + '?access_token=' + ENV['access_token'], {
         body: data.to_json
        })
        comment = {
         body: @pr.errors?.join("\n\n")
        }
        res = HTTParty.post(issue_url + '/comments?access_token=' + ENV['access_token'], {
         body: comment.to_json
        })
        return "not merged"
      else
        msg = {
         commit_message: "Pull Request merged automatically."
        }
        res = HTTParty.put(url + '/merge?access_token=' + ENV['access_token'], {
         body: msg.to_json
        })
        return "merged"
      end
    else
      # puts "not opened"
      # puts res['action']
      return "not opened"
    end
  rescue Exception => e
    # puts "bad json"
    return "bad json"
  end
end

def verify_signature(payload_body)
  signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['GIT_SECRET'], payload_body)
  return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
end