module Agents
  class SinchAgent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!
    default_schedule "never"

    description do
      <<-MD
      The Sinch Agent sents sms with Sinch API..

      `debug` is used for verbose mode.

      `from_number` is the number of the sender.

      `to_number` is the number of the recipient.

      `token` is the bearer token for using the Sinch API.

       If `emit_events` is set to `true`, the server response will be emitted as an Event. No data processing
       will be attempted by this Agent, so the Event's "body" value will always be raw text.

      `body` is the payload (message).

      `service_plan_id` is for the auth.

      MD
    end

    event_description <<-MD
      Events look like this:

          {
          }
    MD

    def default_options
      {
        'from_number' => '',
        'to_number' => '',
        'service_plan_id' => '',
        'token' => '',
        'body' => '',
        'debug' => 'false',
        'emit_events' => 'false',
      }
    end

    form_configurable :debug, type: :boolean
    form_configurable :emit_events, type: :boolean
    form_configurable :from_number, type: :string
    form_configurable :to_number, type: :string
    form_configurable :service_plan_id, type: :string
    form_configurable :token, type: :string
    form_configurable :body, type: :string
    def validate_options
      unless options['token'].present?
        errors.add(:base, "token is a required field")
      end

      unless options['from_number'].present?
        errors.add(:base, "from_number is a required field")
      end

      unless options['to_number'].present?
        errors.add(:base, "to_number is a required field")
      end

      unless options['service_plan_id'].present?
        errors.add(:base, "service_plan_id is a required field")
      end

      unless options['body'].present?
        errors.add(:base, "body is a required field")
      end

      if options.has_key?('emit_events') && boolify(options['emit_events']).nil?
        errors.add(:base, "if provided, emit_events must be true or false")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end
    end

    def working?
      !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolate_with(event) do
          log event
          trigger_event
        end
      end
    end

    def check
      trigger_event
    end

    private

    def trigger_event
      uri = URI.parse("https://us.sms.api.sinch.com/xms/v1/#{interpolated['service_plan_id']}/batches")
      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/json"
      request["Authorization"] = "Bearer #{interpolated['token']}"
      request.body = JSON.dump({
        "from" => "#{interpolated['from_number']}",
        "to" => [
          "#{interpolated['to_number']}"
        ],
        "body" => "#{interpolated['body']}"
      })
      
      req_options = {
        use_ssl: uri.scheme == "https",
      }
      
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      

      log "request  status : #{response.code}"
  
      if interpolated['debug'] == 'true'
        log "response body : #{response.body}"
      end
  
      if interpolated['emit_events'] == 'true'
        create_event :payload => response.body 
      end
    end
  end
end
