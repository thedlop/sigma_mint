# sigma_mint
Ergo assets utility library

### Installation
This library uses [sigma_rb](https://github.com/thedlop/sigma_rb) which has extra installation instructions, please ensure it installs correctly first.

Add to Gemfile
`gem 'sigma_mint', '0.1.1'`  

### Usage
In an effort to save time I will share code that called this lib below. This code is straight from my [two tens](https://twotens.art) project source.


#### PinataClient
We can use Pinata REST API to pin files on ipfs. This requires a Pinata account (free up to 1GB) and a corresponding JWT to use when making requests. The following ENV variables are required:
```
# Required for PinataClient
PINATA_JWT= 
```

For pinning images on ipfs via `PinataClient`:

```
pc = SigmaMint::PinataClient.new  
...
# png_path is a string path to the file we wish pin
# nft_config is a ruby hash (dictionary) that contains some metadata
# config is also a ruby hash (dictionary) that contains other metadata
r = pc.pin!(png_path, "#{nft_config[:name]}", metadata: {set: config[:name], number: nft_config[:set_number]})  

# you may need the ipfs_hash or sha later, it is a requirement for minting an nft picture in ErgoNodeClient  
ipfs_hash = JSON.parse(r.body)['IpfsHash']
```

#### ErgoNodeClient
We can utilize the Ergo Node API to mint a picture nft with royalty. Now this requires running your own node, or a node you have API access and wallet access to. The following ENV variables
are required, you set them by adding them to your `.env` file or adding them at runtime.
```
# Required for ErgoNodeClient                                                                                                                                  
ERGO_NODE_URL=
ERGO_NODE_API_KEY=
ERGO_NODE_WALLET_PASSWORD=
```
For minting a picture nft via `ErgoNodeClient` :

```
# require at top of file
require 'sigma_mint'
...

enc = SigmaMint::ErgoNodeClient.new  
# nft_config is a ruby hash (dictionary) that contains some metadata about this nft
# enft_description and enft_name are strings
# royalty is an integer
enft = SigmaMint::ErgoNft.new(name: enft_name, 
             description: enft_description, 
             royalty: royalty, 
             ipfs_hash: nft_config[:ipfs_hash], 
             sha: nft_config[:scaled_sha], 
             minted: false)  
             
# since we are making private calls to our node we must unlock it first  
enc.unlock_wallet  

# generate and sign nft tranasactions and send to node
# real can be set to false if you want to see the generated transaction without sending it to the node (default false)
# minting address is the node wallet address that will do the minting
# minting_address_ergo_tree is the ergo_tree representation of the minting address
#   you can get it view `ErgoNodeClient#address_to_tree`
 r = enc.mint_picture_nft(minting_address, enft, address_ergo_tree: minting_address_ergo_tree, real: real)
...
```
