require 'dotenv/load'
require 'faraday'
require 'faraday/net_http'
require 'faraday/multipart'
Faraday.default_adapter = :net_http

module SigmaMint
  # Simple Pinata Client for pinning files to IPFS
  class PinataClient
    def initialize
      # https://docs.pinata.cloud/#connecting-to-the-api
      @conn = Faraday.new( 
        url: 'https://api.pinata.cloud',
        headers: {'Authorization' => "Bearer #{ENV['PINATA_JWT']}"},
        ) do |f|
          f.request  :multipart, {}
        end
    end

    # https://docs.pinata.cloud/api-pinning/pin-file
    def pin!(filepath, name, metadata: {}, cid_version: '1', mime_type: 'image/png')
      file = Faraday::Multipart::FilePart.new(filepath, mime_type)

      pinata_options = {
        cidVersion: cid_version,
        wrapWithDirectory: false,
        customPinPolicy: {
          regions: [
              {
                  id: 'FRA1',
                  desiredReplicationCount: 2
              },
              {
                  id: 'NYC1',
                  desiredReplicationCount: 2
              }]}
      }

      pinata_metadata = {
        name: name,
        keyvalues: metadata
      }

      params = {
        file: file,
        pinataOptions: pinata_options,
        pinataMetadata: pinata_metadata,
      }

      @conn.post('/pinning/pinFileToIPFS', params)
    end
  end
end

#pc = PinataClient.new
#testpng = "scratch/test_pngs/test_scaled_bf.png"
#puts pc.pin!(testpng, "pintest_1", metadata: {set: 'Alpha', number: '1'})
