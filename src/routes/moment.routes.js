const express = require('express');
const router = express.Router();
const Moment = require('../models/moment.model');

// 获取朋友圈列表
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const pageSize = parseInt(req.query.pageSize) || 10;
    const moments = await Moment.getMoments(page, pageSize);
    res.json({
      success: true,
      data: moments
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '获取朋友圈列表失败',
      error: error.message
    });
  }
});

// 获取单个朋友圈详情
router.get('/:id', async (req, res) => {
  try {
    const moment = await Moment.getMomentById(req.params.id);
    if (!moment) {
      return res.status(404).json({
        success: false,
        message: '朋友圈不存在'
      });
    }
    res.json({
      success: true,
      data: moment
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '获取朋友圈详情失败',
      error: error.message
    });
  }
});

module.exports = router; 