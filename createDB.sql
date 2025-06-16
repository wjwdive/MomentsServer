-- 设置字符集和排序规则
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- 用户表
CREATE TABLE users (
    user_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL COMMENT '邮箱',
    password VARCHAR(255) NOT NULL COMMENT '密码（加密存储）',
    avatar_url VARCHAR(255),
    is_deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否删除：0-未删除，1-已删除',
    deleted_at TIMESTAMP NULL DEFAULT NULL COMMENT '删除时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_is_deleted (is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 朋友圈表
CREATE TABLE moments (
    moment_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    content TEXT,
    images JSON, -- 使用 MySQL 8.0 的 JSON 类型
    location VARCHAR(255),
    is_deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否删除：0-未删除，1-已删除',
    deleted_at TIMESTAMP NULL DEFAULT NULL COMMENT '删除时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    INDEX idx_created_at (created_at),
    INDEX idx_is_deleted (is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 点赞表
CREATE TABLE likes (
    like_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    moment_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    is_deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否删除：0-未删除，1-已删除',
    deleted_at TIMESTAMP NULL DEFAULT NULL COMMENT '删除时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (moment_id) REFERENCES moments(moment_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    UNIQUE KEY unique_like (moment_id, user_id),
    INDEX idx_is_deleted (is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 评论表
CREATE TABLE comments (
    comment_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    moment_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    content TEXT NOT NULL,
    parent_comment_id BIGINT UNSIGNED,
    is_deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否删除：0-未删除，1-已删除',
    deleted_at TIMESTAMP NULL DEFAULT NULL COMMENT '删除时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (moment_id) REFERENCES moments(moment_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (parent_comment_id) REFERENCES comments(comment_id),
    INDEX idx_moment_created (moment_id, created_at),
    INDEX idx_is_deleted (is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 创建视图：朋友圈列表视图
CREATE OR REPLACE VIEW v_moments_list AS
SELECT 
    m.moment_id,
    m.user_id,
    m.content,
    m.images,
    m.location,
    m.created_at,
    u.username,
    u.avatar_url,
    COUNT(DISTINCT CASE WHEN l.is_deleted = 0 THEN l.like_id END) as like_count,
    COUNT(DISTINCT CASE WHEN c.is_deleted = 0 THEN c.comment_id END) as comment_count
FROM moments m
LEFT JOIN users u ON m.user_id = u.user_id AND u.is_deleted = 0
LEFT JOIN likes l ON m.moment_id = l.moment_id
LEFT JOIN comments c ON m.moment_id = c.moment_id
WHERE m.is_deleted = 0
GROUP BY m.moment_id, m.user_id, m.content, m.images, m.location, m.created_at, u.username, u.avatar_url;

-- 创建视图：朋友圈详情视图
CREATE OR REPLACE VIEW v_moment_detail AS
SELECT 
    m.*,
    u.username,
    u.avatar_url,
    (SELECT COUNT(*) FROM likes WHERE moment_id = m.moment_id AND is_deleted = 0) as like_count,
    (SELECT COUNT(*) FROM comments WHERE moment_id = m.moment_id AND is_deleted = 0) as comment_count
FROM moments m
LEFT JOIN users u ON m.user_id = u.user_id AND u.is_deleted = 0
WHERE m.is_deleted = 0;

-- 创建物理删除的存储过程
DELIMITER //

-- 物理删除已标记删除的朋友圈及其相关数据
CREATE PROCEDURE sp_physical_delete_moments(IN days_ago INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '删除失败，已回滚';
    END;

    START TRANSACTION;
    
    -- 删除朋友圈相关的点赞
    DELETE FROM likes 
    WHERE moment_id IN (
        SELECT moment_id 
        FROM moments 
        WHERE is_deleted = 1 
        AND deleted_at < DATE_SUB(NOW(), INTERVAL days_ago DAY)
    );
    
    -- 删除朋友圈相关的评论
    DELETE FROM comments 
    WHERE moment_id IN (
        SELECT moment_id 
        FROM moments 
        WHERE is_deleted = 1 
        AND deleted_at < DATE_SUB(NOW(), INTERVAL days_ago DAY)
    );
    
    -- 删除朋友圈
    DELETE FROM moments 
    WHERE is_deleted = 1 
    AND deleted_at < DATE_SUB(NOW(), INTERVAL days_ago DAY);
    
    COMMIT;
END //

-- 物理删除已标记删除的评论
CREATE PROCEDURE sp_physical_delete_comments(IN days_ago INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '删除失败，已回滚';
    END;

    START TRANSACTION;
    
    -- 删除评论
    DELETE FROM comments 
    WHERE is_deleted = 1 
    AND deleted_at < DATE_SUB(NOW(), INTERVAL days_ago DAY);
    
    COMMIT;
END //

-- 物理删除已标记删除的点赞
CREATE PROCEDURE sp_physical_delete_likes(IN days_ago INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '删除失败，已回滚';
    END;

    START TRANSACTION;
    
    -- 删除点赞
    DELETE FROM likes 
    WHERE is_deleted = 1 
    AND deleted_at < DATE_SUB(NOW(), INTERVAL days_ago DAY);
    
    COMMIT;
END //

DELIMITER ;

-- 创建定时任务（需要MySQL 8.0.1或更高版本）
-- 每天凌晨2点执行物理删除，删除30天前标记删除的数据
CREATE EVENT IF NOT EXISTS event_physical_delete_data
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 2 HOUR
DO
BEGIN
    -- 删除朋友圈及其相关数据
    CALL sp_physical_delete_moments(30);
    -- 删除评论
    CALL sp_physical_delete_comments(30);
    -- 删除点赞
    CALL sp_physical_delete_likes(30);
END;

-- 示例查询：获取朋友圈列表
-- SELECT * FROM v_moments_list ORDER BY created_at DESC LIMIT 10;

-- 示例查询：获取朋友圈详情
-- SELECT * FROM v_moment_detail WHERE moment_id = ?;

-- 示例查询：获取朋友圈评论
-- SELECT 
--     c.*,
--     u.username,
--     u.avatar_url
-- FROM comments c
-- LEFT JOIN users u ON c.user_id = u.user_id AND u.is_deleted = 0
-- WHERE c.moment_id = ? AND c.is_deleted = 0
-- ORDER BY c.created_at ASC;

-- 示例：软删除朋友圈
-- UPDATE moments 
-- SET is_deleted = 1, deleted_at = CURRENT_TIMESTAMP 
-- WHERE moment_id = ?;

-- 示例：软删除评论
-- UPDATE comments 
-- SET is_deleted = 1, deleted_at = CURRENT_TIMESTAMP 
-- WHERE comment_id = ?;

-- 示例：软删除点赞
-- UPDATE likes 
-- SET is_deleted = 1, deleted_at = CURRENT_TIMESTAMP 
-- WHERE moment_id = ? AND user_id = ?;

-- 示例：手动执行物理删除（删除30天前的数据）
-- CALL sp_physical_delete_moments(30);
-- CALL sp_physical_delete_comments(30);
-- CALL sp_physical_delete_likes(30);

SET FOREIGN_KEY_CHECKS = 1;
