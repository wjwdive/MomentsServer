const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/db.config');
const { sendResponse } = require('../utils/responseHelper'); // 引入统一响应工具

// 注册接口
router.post('/register', async (req, res) => {
    try {
        const { username, password, email } = req.body;

        // 验证用户名、密码和邮箱
        if (!username || !password || !email) {
            return res.status(400).json({ message: '用户名、密码和邮箱不能为空' });
        }

        // 检查用户名是否已存在
        const [existingUsers] = await pool.query(
            'SELECT * FROM users WHERE username = ? AND is_deleted = 0',
            [username]
        );

        if (existingUsers.length > 0) {
            return res.status(400).json({ message: '用户名已存在' });
        }

        // 检查邮箱是否已存在
        const [existingEmails] = await pool.query(
            'SELECT * FROM users WHERE email = ? AND is_deleted = 0',
            [email]
        );
        if (existingEmails.length > 0) {
            return res.status(400).json({ message: '邮箱已被注册' });
        }

        // 加密密码
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // 创建新用户
        const [result] = await pool.query(
            'INSERT INTO users (username, password, email) VALUES (?, ?, ?)',
            [username, hashedPassword, email]
        );

        let data = {
            userId: result.insertId,
            username: username,
            email: email
        }
        //统一返回格式
        sendResponse(res, 200, '注册成功', data);
    } catch (error) {
        console.error('注册失败:', error);
        sendResponse(res, 500, '服务器错误', null);
    }
});

// 登录接口
router.post('/login', async (req, res) => {
    try {
        const { username, password } = req.body;

        // 验证用户名和密码
        if (!username || !password) {
            return res.status(400).json({ message: '用户名和密码不能为空' });
        }

        // 查找用户
        const [users] = await pool.query(
            'SELECT * FROM users WHERE username = ? AND is_deleted = 0',
            [username]
        );

        if (users.length === 0) {
            return res.status(401).json({ message: '用户名或密码错误' });
        }

        const user = users[0];

        // 验证密码
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).json({ message: '用户名或密码错误' });
        }

        // 生成 JWT token
        const token = jwt.sign(
            { userId: user.user_id, username: user.username },
            process.env.JWT_SECRET || 'your-secret-key',
            { expiresIn: '24h' }
        );

        let data = {
            userId: user.user_id,
            username: user.username,
            avatarUrl: user.avatar_url,
            token: token
        }
        
        //统一返回格式
        sendResponse(res, 200, '登录成功', data);
    } catch (error) {
        console.error('登录失败:', error);
        res.status(500).json({ message: '服务器错误' });
    }
});

module.exports = router;