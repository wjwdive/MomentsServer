const { encryptedEndpoints } = require('../config/encryption.config');
const { aesDecrypt, aesEncrypt, rsaDecrypt } = require('../utils/cryptoHelper');

function shouldEncrypt(url) {
  return encryptedEndpoints.some(endpoint => url.startsWith(endpoint));
}

module.exports = (req, res, next) => {
  if (!shouldEncrypt(req.path)) return next();

  let aesKey = null;

  // 解密请求体
  if (req.body && req.body.encryptedKey && req.body.encryptedData) {
    try {
      // 1. 用RSA私钥解密AES密钥
      aesKey = rsaDecrypt(req.body.encryptedKey);
      // 2. 用AES密钥解密数据
      const decrypted = aesDecrypt(req.body.encryptedData, aesKey);
      req.body = JSON.parse(decrypted);
      req._aesKey = aesKey; // 保存本次请求的AES密钥
    } catch (err) {
      return res.status(400).json({ message: '请求解密失败', error: err.message });
    }
  }

  // 劫持res.json，加密响应
  const oldJson = res.json;
  res.json = function (data) {
    if (!aesKey) return oldJson.call(this, data); // 未加密请求，原样返回
    try {
      const encrypted = aesEncrypt(JSON.stringify(data), aesKey);
      return oldJson.call(this, { encryptedData: encrypted });
    } catch (err) {
      return oldJson.call(this, { message: '响应加密失败', error: err.message });
    }
  };

  next();
};
