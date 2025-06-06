const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// 动态读取密钥文件
const RSA_PRIVATE_KEY = fs.readFileSync(path.join(__dirname, '../keys/private.pem'), 'utf8');
const RSA_PUBLIC_KEY = fs.readFileSync(path.join(__dirname, '../keys/public.pem'), 'utf8');


function aesDecrypt(encrypted, key) {
  const iv = Buffer.from(encrypted.iv, 'base64');
  const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
  let decrypted = decipher.update(encrypted.data, 'base64', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

function aesEncrypt(data, key) {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
  let encrypted = cipher.update(data, 'utf8', 'base64');
  encrypted += cipher.final('base64');
  return {
    iv: iv.toString('base64'),
    data: encrypted
  };
}

function rsaDecrypt(encryptedKey) {
  return crypto.privateDecrypt(
    {
      key: RSA_PRIVATE_KEY,
      padding: crypto.constants.RSA_PKCS1_PADDING
    },
    Buffer.from(encryptedKey, 'base64')
  );
}

function rsaEncrypt(key) {
  return crypto.publicEncrypt(
    {
      key: RSA_PUBLIC_KEY,
      padding: crypto.constants.RSA_PKCS1_PADDING
    },
    Buffer.from(key)
  ).toString('base64');
}

module.exports = {
  aesDecrypt,
  aesEncrypt,
  rsaDecrypt,
  rsaEncrypt
};
