class CsrController < ApplicationController
  def create_csr
    details = params[:comment][:body].split("\n\n")
    csr_details = {}
    details.each do |detail|
    	value = detail.split(": ")
    	csr_details[value[0]] = value[1]
    end
    if csr_details["type"] == "CSR"
      csr_key = generate_csr(csr_details["common_name"], csr_details["organization"], csr_details["country"], csr_details["state"], csr_details["locality"], csr_details["san"], csr_details["department"], csr_details["email"])
      #csr_key = generate_csr(csr_details["name"], csr_details["organization"], csr_details["Location"], csr_details["state"], csr_details["locality"], csr_details["san"], csr_details["Org"], csr_details["email"])
      Rails.logger.error "Csr Key: #{csr_key.to_s}"
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
