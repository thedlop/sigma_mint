module SigmaMint
  class ErgoNft
    attr_accessor :name, :description, :royalty, :sha, :ipfs_hash, :minted

    def initialize(name: nil,
                   description: nil,
                   royalty: 0,
                   ipfs_hash: nil,
                   sha: nil,
                   minted: true) 


      @name = name
      @description = description
      @royalty = royalty
      @sha = sha
      @ipfs_hash = ipfs_hash
      @minted = minted
    end

    def ipfs_link
      "https://gateway.pinata.cloud/ipfs/#{@ipfs_hash}"
    end
  end
end
