class CsrController < ApplicationController

  def create_csr
    details = params[:comment][:body].split("\n\n")
    csr_details = {}
    details.each do |detail|
    	value = detail.split(": ")
    	csr_details[value[0]] = value[1]
    end
    if csr_details["type"].present? && csr_details["type"] == "CSR"
      csr_details["common name"] = csr_details["common name"].split('|')[1].gsub(']','') if csr_details["common name"].present?
      csr_details["email"].split('mailto:')[1].gsub(']','') if csr_details["email"].present?
      sans = []
      if csr_details["san"].present?
        sans = []
        links = csr_details['san'].split(',')
        links.each do |link|
          sans << link.split('|')[0].gsub('[','')
        end
      end

      csr_key = generate_csr(csr_details["common name"], csr_details["organization"], csr_details["country"], csr_details["state"], csr_details["locality"], sans, csr_details["department"], csr_details["email"])
      #csr_key = generate_csr(csr_details["common_name"], csr_details["organization"], csr_details["Location"], csr_details["state"], csr_details["locality"], csr_details["san"], csr_details["Org"], csr_details["email"])
      Rails.logger.error "Csr Key: #{csr_key.to_s}"
      issue_id = params[:issue][:key]
      RestClient::Request.execute(:method=>:post,
                            :url=> "https://zeta-hackathon.atlassian.net/rest/api/2/issue/#{issue_id}/comment",
                            :headers=> {:content_type=>:json,
                                        :accept=> :json,
                                        :Authorization => "Basic dmltYXJzaF9rb3VsQHlhaG9vLmNvbTo1eHVvdlBmZVk5U1dBdUxLTVdDMDNBMkI="},
                            :payload=> {"body": "{code:title=CSR Key|borderStyle=solid}#{csr_key.to_s}{code}" }.to_json) { |response, request, result|

      if response.code.to_i >= 200 && response.code.to_i <= 299 # successful execution
        render json: {success: 'csr posted'}, status: :ok
        return
      else
        render json: { errors: "couldn't post the comment" }, status: :bad_request
      end
    }
    else
      Rails.logger.error "CSR not created: #{csr_details}"
      render json: { errors: "Not a CSR creation event" }, status: :bad_request
    end
  end

  def create_issue_in_another_account
    event_type = params[:webhookEvent]
    if event_type == "jira:issue_created"
      summary = params["issue"]["fields"]["summary"]
      description = params["changelog"]["items"].select{|item| item["field"] == "description"}.first["toString"]
      issue_type = params["issue"]["fields"]["issuetype"]["name"]
      response = RestClient.post "https://zeta-hackathon-2.atlassian.net/rest/api/2/issue/", { "fields": { "assignee": {"id": "557058:fa655e19-35e2-4dd7-9b7d-52aa362e8c16"}, "project": { "id": "10000" }, "summary": "#{summary}", "description": "#{description}", "issuetype": { "name": "#{issue_type}" } } }.to_json, {content_type: :json, accept: :json, authorization: "Basic c2hhbmsyN0BnbWFpbC5jb206ellhck5GOUV3UmlnSk1sRkw2cm9BMzY1" }
      if response.code.to_i >= 200 && response.code.to_i <= 299 # successful execution
        render json: {success: 'comment posted'}, status: :ok
        return
      else
        render json: { errors: "couldn't post the comment" }, status: :bad_request
      end
    else
      Rails.logger.error "Not a jira issue creation payload"
      render json: { errors: "Not a CSR creation event" }, status: :bad_request
      return
    end
  end


  private
  def generate_csr(common_name, organization, country, state_name, locality, domain_list, department, email)
    # create signing key
    signing_key = OpenSSL::PKey::RSA.new 2048

    # create certificate subject
    subject = OpenSSL::X509::Name.new [
      ['CN', common_name.to_s],
      ['O', organization.to_s],
      ['C', country.to_s],
      ['ST', state_name.to_s],
      ['L', locality.to_s],
      ['OU', department.to_s],
      ['emailAddress', email.to_s]

    ]

    # create CSR
    csr = OpenSSL::X509::Request.new
    csr.version = 0
    csr.subject = subject
    csr.public_key = signing_key.public_key

    # prepare SAN extension
    if domain_list.present?
      san_list = domain_list.map { |domain| "DNS:#{domain}" }
      extensions = [
        OpenSSL::X509::ExtensionFactory.new.create_extension('subjectAltName', san_list.join(','))
      ]
      # add SAN extension to the CSR
      attribute_values = OpenSSL::ASN1::Set [OpenSSL::ASN1::Sequence(extensions)]
      [
        OpenSSL::X509::Attribute.new('extReq', attribute_values),
        OpenSSL::X509::Attribute.new('msExtReq', attribute_values)
      ].each do |attribute|
        csr.add_attribute attribute
      end
    end

    # sign CSR with the signing key
    csr.sign signing_key, OpenSSL::Digest::SHA256.new

    return  csr
  end
end
