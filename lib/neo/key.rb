require 'openssl'

module Neo
  # Represents a Neo private/public key pair
  class Key
    ADDRESS_VERSION = '17'.freeze
    PUSHBYTES33 = '21'.freeze
    CHECKSIG = 'ac'.freeze
    WIF_PREFIX = '80'.freeze # MainNet
    WIF_SUFFIX = '01'.freeze # Compressed

    def initialize
      @key = OpenSSL::PKey::EC.new('prime256v1').generate_key
    end

    def private_hex
      @key.private_key.to_s(16).downcase
    end

    def public_key_encoded
      @key.public_key.to_bn(:compressed).to_s(16).downcase
    end

    def script
      PUSHBYTES33 + public_key_encoded + CHECKSIG
    end

    def script_hash
      bytes = [script].pack('H*')
      sha256 = Digest::SHA256.digest(bytes)
      Digest::RMD160.hexdigest(sha256)
    end

    def address
      Key.script_hash_to_address(script_hash)
    end

    def wif
      Key.private_key_to_wif(private_hex)
    end

    class << self
      def script_hash_to_address(script_hash)
        Utils::Base58.encode(with_checksum(ADDRESS_VERSION + script_hash).to_i(16))
      end

      def private_key_to_wif(private_key)
        Utils::Base58.encode(with_checksum(WIF_PREFIX + private_key + WIF_SUFFIX).to_i(16))
      end

      def with_checksum(hex)
        bytes = [hex].pack('H*')
        hash1 = Digest::SHA256.digest(bytes)
        hash2 = Digest::SHA256.hexdigest(hash1)
        hex + hash2.slice(0, 8)
      end
    end
  end
end