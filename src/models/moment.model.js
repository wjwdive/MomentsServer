const db = require('../config/db.config');

class Moment {
  static async getMoments(page = 1, pageSize = 10) {
    const offset = (page - 1) * pageSize;
    try {
      const [rows] = await db.query(
        `SELECT 
            m.*,
            u.user_id as user_id,
            u.username as username, 
            u.avatar_url as avatar_url
         FROM moments m 
         LEFT JOIN users u ON m.user_id = u.user_id 
         ORDER BY m.created_at DESC 
         LIMIT ? OFFSET ?`,
        [pageSize, offset]
      );
      if (rows.length === 0) {
        return null; // 如果没有找到记录，返回 null
      }
      const moment = rows[0];
        // 将发布者信息组装到一个单独的对象中
        const userDetail = {
            userId: moment.user_id,
            username: moment.username,
            avatar: moment.avatar_url,
        };

        // 删除原始的冗余字段
        delete moment.userId;
        delete moment.username;
        delete moment.avatar_url;

      return {
        moments: rows,
        userDetail: userDetail
      };
    } catch (error) {
      throw error;
    }
  }

  static async getMomentById(id) {
    try {
      const [rows] = await db.query(
        `SELECT m.*, u.username, u.avatar_url 
         FROM moments m 
         LEFT JOIN users u ON m.user_id = u.user_id 
         WHERE m.user_id = ?`,
        [id]
      );
      return rows[0];
    } catch (error) {
      throw error;
    }
  }
}

module.exports = Moment; 