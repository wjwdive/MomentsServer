/**
 * 统一响应格式
 * @param {Object} res - Express response 对象
 * @param {Number} statusCode - HTTP 状态码
 * @param {String} message - 响应消息
 * @param {Any} data - 响应数据
 */
function sendResponse(res, statusCode, message, data = null) {
  res.status(statusCode).json({
    statusCode,
    message,
    data
  });
}

module.exports = {
  sendResponse
};