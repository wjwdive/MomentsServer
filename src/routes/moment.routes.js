const express = require('express');
const router = express.Router();
const Moment = require('../models/moment.model');
const { sendResponse } = require('../utils/responseHelper'); // 引入统一响应工具

// 获取朋友圈列表
router.post('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const pageSize = parseInt(req.query.pageSize) || 10;
    const moments = await Moment.getMoments(page, pageSize);
    sendResponse(res, 200, '获取朋友圈列表成功', {
      moments
    });
  } catch (error) {
    sendResponse(res, 500, '获取朋友圈列表失败', { error: error.message });
  }
});

// 获取单个朋友圈详情
router.get('/:id', async (req, res) => {
  try {
    const moment = await Moment.getMomentById(req.params.id);
    if (!moment) {
      return sendResponse(res, 404, '朋友圈不存在');
    }
    sendResponse(res, 200, '获取朋友圈详情成功', moment);
  } catch (error) {
    sendResponse(res, 500, '获取朋友圈详情失败', { error: error.message });
  }
});

// 获取用户个人信息
router.post('/user', async (req, res) => {
  try {
    const { userId } = req.body;
    if (!userId) {
      return sendResponse(res, 400, '缺少用户ID');
    }
    const user = await Moment.getMomentById(userId);
    if (!user) {
      return sendResponse(res, 404, '用户不存在');
    }
    sendResponse(res, 200, '获取用户信息成功', user);
  } catch (error) {
    sendResponse(res, 500, '获取用户信息失败', { error: error.message });
  }
});

module.exports = router; 