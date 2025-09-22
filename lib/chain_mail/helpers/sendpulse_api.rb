# frozen_string_literal: true

# Copyright 2015 SendPulse
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'net/http'
require 'json'
require 'base64'


#
# Sendpulse REST API Ruby class
#
# Documentation
# https://login.sendpulse.com/manual/rest-api/
# https://sendpulse.com/api
#
class SendpulseApi

  #
  # Sendpulse API constructor
  #
  # @param [Fixnum] user_id
  # @param [String] secret
  # @param [String] protocol
  # @param [String] token
  # @raise [Exception]
  #
  def initialize(user_id, secret, protocol = 'https', token = '')
    raise 'Empty ID or SECRET' if user_id.to_s.empty? || secret.to_s.empty?

    @url = "#{protocol}://api.sendpulse.com"
    @user_id = user_id
    @secret = secret
    @protocol = protocol
    @refresh_token = 0
    @token = token

    if @token.nil? || @token.empty?
      raise 'Could not connect to api, check your ID and SECRET' unless refresh_token
    end

  end

  #
  # Refresh token
  #
  # @return [Boolean]
  #
  def refresh_token
    @refresh_token += 1

    data = {
        grant_type: 'client_credentials',
        client_id: @user_id,
        client_secret: @secret
    }

    request_data = send_request('oauth/access_token', 'POST', data, false)

    if !request_data.nil? && request_data[:data]['access_token']
      @token = request_data[:data]['access_token']
      @refresh_token = 0
    else
      return false
    end

    true
  end
  private :refresh_token

  #
  # Get token
  #
  # @return [String]
  #
  def get_token
    @token
  end

  #
  # Get serialized string
  #
  # @param [Mixed] data
  # @return [String]
  #
  def serialize(data)
    JSON.generate(data)
  end
  private :serialize

  #
  # Get unserialized data
  #
  # @param [String] data
  # @return [Mixed]
  #
  def unserialize(data)
    JSON.parse(data)
  end
  private :unserialize

  #
  # Form and send request to API service
  #
  # @param [String] path
  # @param [String] method
  # @param [Hash] data
  # @param [Boolean] use_token
  # @return [Hash]
  #
  def send_request(path, method = 'GET', data = {}, use_token = true)

    request_data = {}

    uri = URI.parse("#{@url}/#{path}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if @protocol == 'https'

    token = {}
    token.merge!( 'authorization' => "Bearer #{@token}" ) if use_token

    case method
      when 'POST'
        request = Net::HTTP::Post.new(uri.request_uri, token)
        request.set_form_data(data)
      when 'PUT'
        request = Net::HTTP::Put.new(uri.request_uri, token)
        request.set_form_data(data)
      when 'DELETE'
        request = Net::HTTP::Delete.new(uri.request_uri, token)
        request.set_form_data(data)
      else
        request = Net::HTTP::Get.new(uri.request_uri, token)
    end

    begin
      response = http.request(request)
      if response.code.to_i == 401 && @refresh_token == 0
        refresh_token
        return send_request(path, method, data, use_token)
      else
        request_data[:data] = JSON.parse(response.body)
        request_data[:http_code] = response.code
      end
    rescue Exception => e
      puts "Exception \n  message: #{e.message} \n  backtrace: #{e.backtrace}"
    end

    handle_result(request_data)
  end
  private :send_request

  #
  # Process results
  #
  # @param [String] custom_message
  # @return [Hash]
  #
  def handle_error (custom_message = nil)
    data = { is_error: true }
    data[:message] = custom_message unless custom_message.nil?
    data
  end
  private :handle_error

  #
  # Process errors
  #
  # @param [Hash] data
  # @return [Hash]
  #
  def handle_result (data)
    unless data[:http_code].to_i == 200
      data[:is_error] = true
    end
    data
  end
  private :handle_result

  #
  # Create address book
  #
  # @param [String] book_name
  # @return [Hash]
  #
  def create_address_book(book_name)
    handle_error('Empty book name') if book_name.to_s.empty?
    data = { bookName: book_name }
    send_request('addressbooks', 'POST', data)
  end

  #
  # Edit address book name
  #
  # @param [Fixnum] id
  # @param [String] new_name
  # @return [Hash]
  #
  def edit_address_book(id, new_name)
    return handle_error('Empty new name or book id') if id.to_i <= 0 || new_name.to_s.empty?
    data = { name: new_name }
    send_request("addressbooks/#{id}", 'PUT', data)
  end

  #
  # Remove address book
  #
  # @param [Fixnum] id
  # @return [Hash]
  #
  def remove_address_book(id)
    return handle_error('Empty book id') unless id.to_i > 0
    send_request("addressbooks/#{id}", 'DELETE')
  end

  #
  # Get list of address books
  #
  # @param [Fixnum] limit
  # @param [Fixnum] offset
  # @return [Hash]
  #
  def list_address_books(limit = nil, offset = nil)
    data = {}
    data.merge!({limit: limit}) unless limit.nil?
    data.merge!({offset: offset}) unless offset.nil?
    send_request('addressbooks', 'GET', data)
  end

  #
  # Get information about book
  #
  # @param [Fixnum] id
  # @return [Hash]
  #
  def get_book_info(id)
    return handle_error('Empty book id') unless id.to_i > 0
    send_request("addressbooks/#{id}")
  end

  #
  # List email addresses from book
  #
  # @param [Fixnum] id
  # @return [Hash]
  #
  def get_emails_from_book(id)
    return handle_error('Empty book id') unless id.to_i > 0
    send_request("addressbooks/#{id}/emails")
  end

  #
  # Add new emails to address book
  #
  # @param [Fixnum] book_id
  # @param [Hash] emails
  # @return [Hash]
  #
  def add_emails(book_id, emails)
    return handle_error('Empty book id or emails') if book_id.to_i <= 0 || emails.empty?
    data = { emails: serialize(emails) }
    send_request("addressbooks/#{book_id}/emails", 'POST', data)
  end

  #
  # Remove email addresses from book
  #
  # @param [Fixnum] book_id
  # @param [Hash] emails
  # @return [Hash]
  #
  def remove_emails(book_id, emails)
    return handle_error('Empty book id or emails') if book_id.to_i <= 0 || emails.empty?
    data = { emails: serialize(emails) }
    send_request("addressbooks/#{book_id}/emails", 'DELETE', data)
  end

  #
  # Get information about email address from book
  #
  # @param [Fixnum] book_id
  # @param [String] email
  # @return [Hash]
  #
  def get_email_info(book_id, email)
    return handle_error('Empty book id or email') if book_id.to_i <= 0 || email.to_s.empty?
    send_request("addressbooks/#{book_id}/emails/#{email}")
  end

  #
  # Get cost of campaign based on address book
  #
  # @param [Fixnum] book_id
  # @return [Hash]
  #
  def campaign_cost(book_id)
    return handle_error('Empty book id') unless book_id.to_i > 0
    send_request("addressbooks/#{book_id}/cost")
  end

  #
  # Get list of campaigns
  #
  # @param [Fixnum] limit
  # @param [Fixnum] offset
  # @return [Hash]
  #
  def list_campaigns(limit = nil, offset = nil)
    data = {}
    data.merge!({limit: limit}) unless limit.nil?
    data.merge!({offset: offset}) unless offset.nil?
    send_request('campaigns', 'GET', data)
  end

  #
  # Get information about campaign
  #
  # @param [Fixnum] id
  # @return [Hash]
  #
  def get_campaign_info(id)
    return handle_error('Empty campaign id') unless id.to_i > 0
    send_request("campaigns/#{id}")
  end

  #
  # Get campaign statistic by countries
  #
  # @param [Fixnum] id
  # @return [Hash]
  #
  def campaign_stat_by_countries(id)
    return handle_error('Empty campaign id') unless id.to_i > 0
    send_request("campaigns/#{id}/countries")
  end

  #
  # Get campaign statistic by referrals
  #
  # @param [Fixnum] id
  # @return [Hash]
  #
  def campaign_stat_by_referrals(id)
    return handle_error('Empty campaign id') unless id.to_i > 0
    send_request("campaigns/#{id}/referrals")
  end

  #
  # Create new campaign
  #
  # @param [String] sender_name
  # @param [String] sender_email
  # @param [String] subject
  # @param [String] body
  # @param [Fixnum] book_id
  # @param [String] name
  # @param [String] attachments
  # @return [Hash]
  #
  def create_campaign(sender_name, sender_email, subject, body, book_id, name = '', attachments = '')
    if sender_name.empty? || sender_email.empty? || subject.empty? || body.empty? || book_id.to_i <= 0
      return handle_error('Not all data.')
    end
    attachments = serialize(attachments) unless attachments.empty?
    data = {
        sender_name: sender_name,
        sender_email: sender_email,
        subject: subject,
        body: Base64.encode64(body),
        list_id: book_id,
        name: name,
        attachments: attachments
    }
    send_request('campaigns', 'POST', data)
  end

  #
  # Cancel campaign
  #
  # @param [Fixnum] id
  # @return [Hash]
  #
  def cancel_campaign(id)
    return handle_error('Empty campaign id') unless id.to_i > 0
    send_request("campaigns/#{id}", 'DELETE')
  end

  #
  # List all senders
  #
  # @return [Hash]
  #
  def list_senders
    send_request('senders')
  end

  #
  # Cancel Add new sender
  #
  # @param [String] sender_name
  # @param [String] sender_email
  # @return [Hash]
  #
  def add_sender(sender_name, sender_email)
    return handle_error('Empty book sender name or sender email') if sender_name.to_s.empty? || sender_email.to_s.empty?
    data = {
        email: sender_email,
        name: sender_name
    }
    send_request('senders', 'POST', data)
  end

  #
  # Remove sender
  #
  # @param [String] email
  # @return [Hash]
  #
  def remove_sender(email)
    return handle_error('Empty email') if email.to_s.empty?
    data = { email: email }
    send_request('senders', 'DELETE', data)
  end

  #
  # Activate sender using code
  #
  # @param [String] email
  # @param [String] code
  # @return [Hash]
  #
  def activate_sender(email, code)
    return handle_error('Empty email or activation code') if email.to_s.empty? || code.to_s.empty?
    data = { code: code }
    send_request("senders/#{email}/code", 'POST', data)
  end

  #
  # Request mail with activation code
  #
  # @param [String] email
  # @return [Hash]
  #
  def get_sender_activation_mail(email)
    return handle_error('Empty email') if email.to_s.empty?
    send_request("senders/#{email}/code")
  end

  #
  # Get global information about email
  #
  # @param [String] email
  # @return [Hash]
  #
  def get_email_global_info(email)
    return handle_error('Empty email') if email.to_s.empty?
    send_request("emails/#{email}")
  end

  #
  # Remove email from all books
  #
  # @param [String] email
  # @return [Hash]
  #
  def remove_email_from_all_books(email)
    return handle_error('Empty email') if email.to_s.empty?
    send_request("emails/#{email}", 'DELETE')
  end

  #
  # Get email statistic by all campaigns
  #
  # @param [String] email
  # @return [Hash]
  #
  def email_stat_by_campaigns(email)
    return handle_error('Empty email') if email.to_s.empty?
    send_request("emails/#{email}/campaigns")
  end

  #
  # Get all emails from blacklist
  #
  # @return [Hash]
  #
  def get_black_list
    send_request('blacklist')
  end

  #
  # Add email to blacklist
  #
  # @param [String] emails
  # @param [String] comment
  # @return [Hash]
  #
  def add_to_black_list(emails, comment = '')
    return handle_error('Empty emails') if emails.to_s.empty?
    data = {
        emails: Base64.encode64(emails),
        comment: comment
    }
    send_request('blacklist', 'POST', data)
  end

  #
  # Remove emails from blacklist
  #
  # @param [String] emails
  # @return [Hash]
  #
  def remove_from_black_list(emails)
    return handle_error('Empty emails') if emails.to_s.empty?
    data = { emails: Base64.encode64(emails) }
    send_request('blacklist', 'DELETE', data)
  end

  #
  # Get balance
  #
  # @param [String] currency
  # @return [Hash]
  #
  def get_balance(currency = '')
    url = 'balance'
    url += '/' + currency.to_s.upcase unless currency.empty?
    send_request(url)
  end

  #
  # SMTP: get list of emails
  #
  # @param [Fixnum] limit
  # @param [Fixnum] offset
  # @param [String] from_date
  # @param [String] to_date
  # @param [String] sender
  # @param [String] recipient
  # @return [Hash]
  #
  def smtp_list_emails(limit = 0, offset = 0, from_date = '', to_date = '', sender = '', recipient = '')
    data = {
        limit: limit,
        offset: offset,
        from_date: from_date,
        to_date: to_date,
        sender: sender,
        recipient: recipient
    }
    send_request('/smtp/emails', 'GET', data)
  end

  #
  # SMTP: add emails to unsubscribe list
  #
  # @param [Fixnum] id
  # @return [Hash]
  #
  def smtp_get_email_info_by_id(id)
    return handle_error('Empty id') if id.to_s.empty?
    send_request("smtp/emails/#{id}")
  end

  #
  # SMTP: remove emails from unsubscribe list
  #
  # @param [Hash] emails
  # @return [Hash]
  #
  def smtp_unsubscribe_emails(emails)
    return handle_error('Empty emails') if emails.empty?
    data = { emails: serialize(emails) }
    send_request('smtp/unsubscribe', 'POST', data)
  end

  #
  # SMTP: remove emails from unsubscribe list
  #
  # @param [Hash] emails
  # @return [Hash]
  #
  def smtp_remove_from_unsubscribe(emails)
    return handle_error('Empty emails') if emails.empty?
    data = { emails: serialize(emails) }
    send_request('smtp/unsubscribe', 'DELETE', data)
  end

  #
  # SMTP: get list of IP
  #
  # @return [Hash]
  #
  def smtp_list_ip
    send_request('smtp/ips')
  end

  #
  # SMTP: get list of allowed domains
  #
  # @return [Hash]
  #
  def smtp_list_allowed_domains
    send_request('smtp/domains')
  end

  #
  # SMTP: add new domain
  #
  # @param [String] email
  # @return [Hash]
  #
  def smtp_add_domain(email)
    return handle_error('Empty email') if email.to_s.empty?
    data = { email: email }
    send_request('smtp/domains', 'POST', data)
  end

  #
  # SMTP: verify domain
  #
  # @param [String] email
  # @return [Hash]
  #
  def smtp_verify_domain(email)
    return handle_error('Empty email') if email.to_s.empty?
    send_request("smtp/domains/#{email}")
  end

  #
  # SMTP: send mail
  #
  # @param [Hash] email
  # @return [Hash]
  #
  def smtp_send_mail(email)
    return handle_error('Empty email') if email.empty?
    email[:html] = Base64.encode64(email[:html])
    data = { email: serialize(email) }
    send_request('smtp/emails', 'POST', data)
  end

end