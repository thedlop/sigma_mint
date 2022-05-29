require 'sigma'
require 'sigma_mint'

module SigmaMint
  # Simple Ergo Node Client for minting assets
  # 
  # Some ENV Variables are required:
  # - ERGO_NODE_API_KEY : API Key for node
  # - ERGO_NODE_URL     : Node url (ex: https://paidincrypto.io , http://127.0.0.1 )
  # - ERGO_NODE_WALLET_PASSWORD : Node wallet password
  class ErgoNodeClient
    class MissingEnvVarError < StandardError; end

    def initialize
      if ENV['ERGO_NODE_API_KEY'].nil?
        raise MissingEnvVarError.new("ERGO_NODE_API_KEY is blank, required for ErgoNodeClient")
      end

      if ENV['ERGO_NODE_URL'].nil?
        raise MissingEnvVarError.new("ERGO_NODE_URL is blank, required for ErgoNodeClient")
      end

      @conn = Faraday.new(
        url: ENV['ERGO_NODE_URL'],
        headers: {'api_key' => ENV['ERGO_NODE_API_KEY'],
                  'Accept' => 'application/json',
                  'Content-Type' => 'application/json'
                  },
      )
    end

    def unlock_wallet
      if ENV['ERGO_NODE_WALLET_PASSWORD'].nil?
        raise MissingEnvVarError.new("ERGO_NODE_WALLET_PASSWORD is blank, required for ErgoNodeClient")
      end

      params = {pass: ENV['ERGO_NODE_WALLET_PASSWORD']}
      @conn.post('/wallet/unlock', params.to_json)
    end

    def address_to_tree(address)
      @conn.get("/script/addressToTree/#{address}")
    end

    ErgoEncodedNFT = Struct.new(
      :royalty,
      :address_ergo_tree,
      :sha,
      :ipfs_link,
      keyword_init: :true,
    )

    def burn_assets(token_ids)
      assets = token_ids.map do |token_id|
        { tokenId: token_id,
          amount: 1}
      end
      params = {
        requests: [
          {
            assetsToBurn: assets,
          }
        ],
        fee: 1000000,
      }

      r = @conn.post('/wallet/transaction/send', params.to_json)
      puts r.body
      r
    end

    def send_nfts(to_address, token_ids)
      assets = token_ids.map do |token_id|
        { tokenId: token_id,
          amount: 1}
      end
      params = {
        requests: [
          {address: to_address,
           value: 100000 * token_ids.count,
           assets: assets,
          }
        ],
        fee: 1000000,
      }
      r = @conn.post('/wallet/transaction/send', params.to_json)
      puts r.body
      r
    end

    def send_transaction(ergo_transaction)
      @conn.post('/transactions', ergo_transaction.to_json)
    end

    def get_serialized_box_with_pool(box_id)
      @conn.get("/utxo/withPool/byIdBinary/#{box_id}", {})
    end

    def get_unspent_boxes(min_confirmations: 0, min_inclusion_height: 0)
      params = {
        minConfirmations: min_confirmations,
        minInclusionHeight: min_inclusion_height,
      }

      r = @conn.get('/wallet/boxes/unspent', params)
      return r
    end

    def mint_picture_nft(address, ergo_nft, royalty: 0, real: false, address_ergo_tree: nil)

      if address_ergo_tree.nil?
        r = address_to_tree(address)
        address_ergo_tree = JSON.parse(r.body)['tree']
      end

      # get encoded values
      encoded = get_encoded_values(ergo_nft, royalty: royalty, address_ergo_tree: address_ergo_tree)

      royalty_params = {
        requests: [],
        fee: Sigma::TxBuilder.suggested_tx_fee.to_i64,
      }

      royalty_request = {
        address: address,
        value: 2000000,
        registers: {
          R4: encoded.royalty,
          R5: encoded.address_ergo_tree,
        }
      }

      royalty_params[:requests] = [royalty_request]
    
      # generate royalty txn
      r = @conn.post('/wallet/transaction/generate', royalty_params.to_json)
      royalty_txn = JSON.parse(r.body)
      box_id = royalty_txn['outputs'][0]['boxId']
      puts "Royalty BoxID: #{box_id}"
      
      royalty_box_raw_bytes = nil

      # send royalty txn
      if real
        r = send_transaction(royalty_txn)

        # grab royalty box id
        waiting_for_box_count = 0 
        waiting_for_box_max = 5
        loop do
          if waiting_for_box_count > waiting_for_box_max
            raise 'Royalty Box never showed up #{box_id}'
          end
          r = get_serialized_box_with_pool(box_id)
          break if r.status == 200
          waiting_for_box_count += 1
          puts "Waiting for Royalty Box #{waiting_for_box_count}"
          sleep 1
        end

        royalty_box_raw_bytes = JSON.parse(r.body)['bytes']
        puts "Royalty Box Bytes: #{royalty_box_raw_bytes}"
      end

      nft_request = {
        address: address,
        amount: 1,
        name: ergo_nft.name,
        description: ergo_nft.description,
        decimals: 0,
        registers: {
          R7: "0e020101", # PICTURE NFT
          R8: encoded.sha,
          R9: encoded.ipfs_link,
        },
      }

      nft_params = {
        requests: [nft_request],
        fee: Sigma::TxBuilder.suggested_tx_fee.to_i64,
        inputsRaw: [royalty_box_raw_bytes],
      }

      if real
        # finally generate nft transaction with royalty box as input
        @conn.post('/wallet/transaction/generate', nft_params.to_json)
      else
        puts "NFT Mint dry run, would send: \n#{nft_params.inspect}"
      end
    end

    # @param ergo_nft [ErgoNft] 
    # @param royalty: [Integer] Default: 0
    def get_encoded_values(ergo_nft, royalty: 0, address_ergo_tree: nil)
      raise "address_ergo_tree required!" if address_ergo_tree.nil?
    
      # NOTE from EIP-24:  (Royalty) R4 of this box is an Int, showing 1000 * royalty percentage of the artwork. e.g, 20 for 2% royalty.
      ErgoEncodedNFT.new(
        ipfs_link: sigma_encode_str(ergo_nft.ipfs_link),
        royalty: Sigma::Constant.with_i32(royalty * 10).to_base16_string,
        sha: sigma_encode_str(ergo_nft.sha),
        address_ergo_tree: sigma_encode_str(address_ergo_tree), 
      ) 

      #ErgoEncodedNFT.new(
        #royalty: '04a001',
        #address_ergo_tree: '0e240008cd029c7a290a2ba90a0fd8fb9d4490cd915c2538e2c5e1836e7fa6003052cd40d72f',
        #sha: '0e20739aaaedd3822179ca2136160b4ec35d31ea50c37d8d2c914c9ad68377ea4cda',
        #ipfs_link: '0e5d68747470733a2f2f676174657761792e70696e6174612e636c6f75642f697066732f6261666b7265696474746b766f337534636566343475696a77637966753571323567687666627133357275776a63746532323262787032736d3369',
      #)
    end

    def sigma_encode_str(str)
      Sigma::Constant.with_bytes(
        str.each_byte.map { |b| b.to_s(8).to_i }
      ).to_base16_string
    end
  end
end
