const db = require('../config/db.config');

class Moment {
  static async getMoments(page = 1, pageSize = 10) {
    const offset = (page - 1) * pageSize;
    try {
      const [rows] = await db.query(
        `SELECT m.*, u.username, u.avatar_url 
         FROM moments m 
         LEFT JOIN users u ON m.user_id = u.user_id 
         ORDER BY m.created_at DESC 
         LIMIT ? OFFSET ?`,
        [pageSize, offset]
      );
      return rows;
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