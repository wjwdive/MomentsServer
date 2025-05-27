
-- 插入测试数据
-- 插入用户数据
INSERT INTO users (username, avatar_url) VALUES
('张三', 'https://example.com/avatars/zhangsan.jpg'),
('李四', 'https://example.com/avatars/lisi.jpg'),
('王五', 'https://example.com/avatars/wangwu.jpg'),
('赵六', 'https://example.com/avatars/zhaoliu.jpg'),
('孙七', 'https://example.com/avatars/sunqi.jpg');

-- 插入朋友圈数据
INSERT INTO moments (user_id, content, images, location) VALUES
(1, '今天天气真好，去公园散步了！', JSON_ARRAY('https://example.com/images/park1.jpg', 'https://example.com/images/park2.jpg'), '中央公园'),
(2, '新买的相机到了，拍了几张照片', JSON_ARRAY('https://example.com/images/camera1.jpg'), '家里'),
(3, '分享一个美食教程', JSON_ARRAY('https://example.com/images/food1.jpg', 'https://example.com/images/food2.jpg', 'https://example.com/images/food3.jpg'), '厨房'),
(1, '周末去爬山，风景真美', JSON_ARRAY('https://example.com/images/mountain1.jpg', 'https://example.com/images/mountain2.jpg'), '泰山'),
(4, '新工作第一天，加油！', NULL, '公司'),
(5, '分享一首好听的歌', NULL, '家里');

-- 插入点赞数据
INSERT INTO likes (moment_id, user_id) VALUES
(1, 2), (1, 3), (1, 4),  -- 第一条朋友圈有3个点赞
(2, 1), (2, 3),          -- 第二条朋友圈有2个点赞
(3, 1), (3, 2), (3, 4), (3, 5),  -- 第三条朋友圈有4个点赞
(4, 2), (4, 3),          -- 第四条朋友圈有2个点赞
(5, 1), (5, 3), (5, 5);  -- 第五条朋友圈有3个点赞

-- 插入评论数据
INSERT INTO comments (moment_id, user_id, content, parent_comment_id) VALUES
(1, 2, '天气确实不错！', NULL),
(1, 3, '公园的花开了吗？', NULL),
(1, 2, '开了，很漂亮！', 2),  -- 回复第2条评论
(2, 1, '相机型号是什么？', NULL),
(2, 2, '拍得真不错！', NULL),
(3, 4, '看起来好好吃！', NULL),
(3, 5, '求教程！', NULL),
(3, 3, '好的，我整理一下发给你', 7),  -- 回复第7条评论
(4, 1, '注意安全！', NULL),
(5, 2, '恭喜！', NULL),
(5, 4, '谢谢！', 10);  -- 回复第10条评论

-- 插入一些已删除的数据（用于测试软删除功能）
INSERT INTO moments (user_id, content, images, location, is_deleted, deleted_at) VALUES
(2, '这是一条已删除的朋友圈', JSON_ARRAY('https://example.com/images/deleted1.jpg'), '家里', 1, DATE_SUB(NOW(), INTERVAL 15 DAY));

INSERT INTO comments (moment_id, user_id, content, is_deleted, deleted_at) VALUES
(1, 4, '这是一条已删除的评论', 1, DATE_SUB(NOW(), INTERVAL 10 DAY));

INSERT INTO likes (moment_id, user_id, is_deleted, deleted_at) VALUES
(1, 5, 1, DATE_SUB(NOW(), INTERVAL 5 DAY));