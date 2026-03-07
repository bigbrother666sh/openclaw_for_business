// 情报小站配置

/**
 * 情报小站群信息
 */
export interface StationRoomType {
  room: {
    name: string;
    groupId: string;
  };
}

/**
 * 默认入群欢迎语模板
 * 支持变量：{name}（成员称呼）、{group_name}（群名称）
 * 可通过环境变量 STATION_WELCOME_MESSAGE 覆盖
 */
const DEFAULT_WELCOME_MESSAGE = `👋 {name}，欢迎加入 {group_name}！`;

const StationConfig = {
  welComeStation: process.env.STATION_WELCOME_MESSAGE || DEFAULT_WELCOME_MESSAGE
};

export default StationConfig;
