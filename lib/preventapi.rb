require 'openssl'
require 'base64'

module Preventapi
  def self.included(base)
    base.extend self
  end

  def cipher
    OpenSSL::Cipher.new('aes-256-cbc')  # ('aes-256-cbc')
  end

  def cipher_key
    'jai@tecorb!'
  end

  def decode_token(value)
    begin
      c = cipher.decrypt
      c.key = Digest::SHA256.digest(cipher_key)
      c.update(Base64.urlsafe_decode64(value.to_s)) + c.final
    rescue Exception=> e
      false
    end
  end

  def encode_token(value)
    c = cipher.encrypt
    c.key = Digest::SHA256.digest(cipher_key)
    Base64.urlsafe_encode64(c.update(value.to_s) + c.final)
  end
end