const express = require('express');
const cors = require('cors');
const momentRoutes = require('./routes/moment.routes');

const app = express();
// 调试日志
console.log('正在初始化 Express 应用...');
console.log('路由模块:', momentRoutes);

// 中间件
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 路由
console.log('正在注册路由...');
app.use('/api/moments', momentRoutes);

// 错误处理中间件
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: '服务器内部错误',
    error: err.message
  });
});

// 404 处理
app.use((req, res, next) => {
    res.status(404).json({
      success: false,
      message: '请求的资源不存在'
    });
  });

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`服务器运行在端口 ${PORT}`);
}); 