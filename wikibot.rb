require 'grape'
require 'URI'
require 'net/http'
require 'json'
require 'Thread'

class WikiBot < Grape::API

  helpers do
    def webhook_url
      "https://hooks.slack.com/services/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"
    end
    def language
      "en"
    end
    def limit
      4
    end
  end

  resource :wikibot do
    params do
      requires :command, type: String
      requires :text, type: String
      requires :token, type: String
      requires :channel_id, type: String
      requires :user_name, type: String
    end
    get do
      text = params[:text]
      user_name = params[:user_name]
      user_id = params[:user_id]

      uri = URI("https://#{language}.wikipedia.org/w/api.php")
      params = { :action => :opensearch, :search => text, :format => :json, :limit => limit }
      uri.query = URI.encode_www_form(params)
      res = Net::HTTP.get_response(uri)
      return "Couldn't find anything for \"#{text}\"! Guru Meditation Code #{res.code}" unless res.is_a?(Net::HTTPSuccess)
      
      wiki_array = JSON.parse(res.body)
      wiki_array.shift

      return "Too bad! I couldn't find anything for for \"#{text}\"!" unless wiki_array.length

      message_text  = "<@#{user_id}|#{user_name}> searched for *#{text}*.\n"
      message_primary_title = wiki_array[0][0]
      message_primary_summary = wiki_array[1][0]
      message_primary_link = wiki_array[2][0]
      other_options = wiki_array[2];
      other_options.shift


      if wiki_array[1][0].index "may refer to:"
        message_text += "There are several possible results for *<#{message_primary_link}|#{text}>*.\n"
        message_text += "message_primary_link"
        message_other_title = "Here are some of the possibilities:"
      else
        message_text += "*<#{message_primary_link}|#{message_primary_title}>*\n";
        message_text += "#{message_primary_summary}\n";
        message_text += "#{message_primary_link}";
        message_other_title = "Here are a few other options:";
      end
      message_other_options = ""

      other_options.each do |value| 
        message_other_options += "#{value}\n"
      end

      data = {
        # :username => "Slackipedia",
        # :icon_url => params[:icon_url],
        :channel => params[:channel_id],
        :text => message_text,
        :mrkdwn => true,
        :attachments => [
          {
            :color => "#b0c4de",
            :fallback => message_text,
            :text => message_text,
            :mrkdwn_in => [
                "fallback",
                "text"
            ],
            :fields => [
              {
                  :title => message_other_title,
                  :value => message_other_options
              }
            ]
          }
        ]
      }

      webhook_uri = URI(webhook_url)
      webhook_res = Net::HTTP.post_form(webhook_uri, 'payload' => data.to_json)
      return
    end
  end

end
