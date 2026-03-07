/**
 * 导演指令处理服务
 * 处理导演发送的各种指令，如设置群公告等
 */

import { WorkToolCallbackMessage } from '@/services/worktool/types';
import { sendTextMessage } from '@/services/worktool';
import { createLogger } from '../../src/utils/logger';

const logger = createLogger('Director-Command');

/**
 * 导演昵称列表（通过环境变量 DIRECTOR_NICKNAMES 配置，逗号分隔）
 */
export const DIRECTOR_NICKNAME: string[] = process.env.DIRECTOR_NICKNAMES
  ? process.env.DIRECTOR_NICKNAMES.split(',')
      .map((s) => s.trim())
      .filter(Boolean)
  : [];

/**
 * 客服群名称列表（通过环境变量 CUSTOMER_SERVICE_GROUPS 配置，逗号分隔）
 */
export const CUSTOMER_SERVICE_GROUP: string[] = process.env.CUSTOMER_SERVICE_GROUPS
  ? process.env.CUSTOMER_SERVICE_GROUPS.split(',')
      .map((s) => s.trim())
      .filter(Boolean)
  : [];

/**
 * 会员群名称列表（通过环境变量 MEMBER_GROUPS 配置，逗号分隔）
 */
export const MEMBER_GROUP: string[] = process.env.MEMBER_GROUPS
  ? process.env.MEMBER_GROUPS.split(',')
      .map((s) => s.trim())
      .filter(Boolean)
  : [];

/**
 * 解析 /a 指令（设置群公告）
 * 格式：
 * /a // {需要设置为群公告的内容}
 *
 * 注意：通过 // 分割指令和内容
 */
export function parseAnnouncementCommand(messageText: string): string | null {
  const parts = messageText
    .split('//')
    .map((part) => part.trim())
    .filter((part) => part);

  if (parts.length < 2) {
    return null;
  }

  // 第一部分必须是 /a
  if (parts[0].toLowerCase() !== '/a') {
    return null;
  }

  // 第二部分及之后的内容是群公告内容（用 // 重新连接，保留原始格式）
  const announcement = parts.slice(1).join('//').trim();
  if (!announcement) {
    return null;
  }

  return announcement;
}

/**
 * 设置群公告
 * 使用 WorkTool 的 sendRawMessage 接口，type=207 表示修改群信息（含设置群公告）
 * 文档: https://app.apifox.com/web/project/1035094/apis/api-23520590
 *
 * @param robotId 机器人ID
 * @param groupNames 群名称列表
 * @param announcement 公告内容
 * @returns 设置结果
 */
export async function setGroupAnnouncement(robotId: string, groupNames: string[], announcement: string): Promise<{ success: boolean; message?: string; failedGroups?: string[] }> {
  try {
    const { worktoolClient } = await import('@/services/worktool');

    // 为每个群名创建一个请求项
    const list = groupNames.map((groupName) => ({
      type: 207, // 修改群信息(含拉人等)
      groupName: groupName, // 待修改的群名（必须是 string）
      newGroupAnnouncement: announcement // 修改群公告
    }));

    const requestBody = {
      socketType: 2,
      list
    };

    const response = await worktoolClient.post<string>('/wework/sendRawMessage', requestBody, { params: { robotId } });

    if (response.code === 200) {
      return {
        success: true
      };
    } else {
      return {
        success: false,
        message: response.message || '设置群公告失败'
      };
    }
  } catch (error: any) {
    logger.error('设置群公告失败:', error);
    return {
      success: false,
      message: error.message || '设置群公告失败'
    };
  }
}

/**
 * 处理设置群公告指令
 */
export async function handleAnnouncementCommand(message: WorkToolCallbackMessage, robotId: string, announcement: string): Promise<void> {
  logger.info(`📢 处理设置群公告指令: ${announcement.substring(0, 50)}...`);

  // 设置群公告（允许通过私聊发送指令）
  const result = await setGroupAnnouncement(robotId, CUSTOMER_SERVICE_GROUP, announcement);

  if (result.success) {
    const successMessage = `✅ 群公告设置成功\n群名：${CUSTOMER_SERVICE_GROUP.join(',')}\n公告内容：\n${announcement}`;
    try {
      await sendTextMessage(robotId, {
        titleList: DIRECTOR_NICKNAME.filter((name) => name === message.receivedName),
        receivedContent: successMessage
      });
      logger.info(`✅ 群公告设置成功: ${CUSTOMER_SERVICE_GROUP.join(',')}`);
    } catch (error: any) {
      logger.error('发送成功消息失败:', error);
    }
  } else {
    const errorMessage = `❌ 群公告设置失败: ${result.message || '未知错误'}`;
    try {
      await sendTextMessage(robotId, {
        titleList: DIRECTOR_NICKNAME.filter((name) => name === message.receivedName),
        receivedContent: errorMessage
      });
      logger.error(`❌ 群公告设置失败: ${result.message}`);
    } catch (error: any) {
      logger.error('发送错误消息失败:', error);
    }
  }
}

/**
 * 检查是否是导演发送的消息
 */
export function isDirectorMessage(message: WorkToolCallbackMessage): boolean {
  return DIRECTOR_NICKNAME.includes(message.receivedName);
}
