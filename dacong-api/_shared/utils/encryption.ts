/**
 * 加密工具类
 * 用途：提供数据加密/解密功能，保护敏感信息
 *
 * 安全原则：
 * 1. 使用 AES-256-GCM 加密算法
 * 2. 密钥从环境变量读取，永不硬编码
 * 3. 每次加密使用随机 IV（初始化向量）
 * 4. 加密结果包含 IV 和认证标签
 */

import crypto from 'crypto';

// 加密配置
const ALGORITHM = 'aes-256-gcm';
const KEY_LENGTH = 32; // 256 bits
const IV_LENGTH = 16; // 128 bits
const AUTH_TAG_LENGTH = 16; // 128 bits
const SALT_LENGTH = 64;

/**
 * 从环境变量获取加密密钥
 * 如果未设置，抛出错误（fail-fast 原则）
 */
function getEncryptionKey(): Buffer {
  const key = process.env.ENCRYPTION_KEY;

  if (!key) {
    throw new Error('ENCRYPTION_KEY 环境变量未设置');
  }

  // 使用 PBKDF2 从密钥派生固定长度的密钥
  const salt = process.env.ENCRYPTION_SALT || 'dacong-default-salt';
  return crypto.pbkdf2Sync(key, salt, 100000, KEY_LENGTH, 'sha256');
}

/**
 * 加密数据
 *
 * @param plaintext - 明文数据
 * @returns 加密后的数据（Base64 编码，包含 IV 和认证标签）
 *
 * 格式: iv:authTag:ciphertext (所有部分都是 Base64 编码)
 */
export function encryptData(plaintext: string): string {
  if (!plaintext) {
    throw new Error('明文数据不能为空');
  }

  try {
    const key = getEncryptionKey();
    const iv = crypto.randomBytes(IV_LENGTH);

    const cipher = crypto.createCipheriv(ALGORITHM, key, iv);

    let encrypted = cipher.update(plaintext, 'utf8', 'base64');
    encrypted += cipher.final('base64');

    const authTag = cipher.getAuthTag();

    // 格式: iv:authTag:ciphertext
    return `${iv.toString('base64')}:${authTag.toString('base64')}:${encrypted}`;
  } catch (error) {
    throw new Error(`加密失败: ${error instanceof Error ? error.message : '未知错误'}`);
  }
}

/**
 * 解密数据
 *
 * @param ciphertext - 加密后的数据（Base64 编码）
 * @returns 解密后的明文数据
 */
export function decryptData(ciphertext: string): string {
  if (!ciphertext) {
    throw new Error('密文数据不能为空');
  }

  try {
    const key = getEncryptionKey();

    // 解析格式: iv:authTag:ciphertext
    const parts = ciphertext.split(':');
    if (parts.length !== 3) {
      throw new Error('密文格式错误');
    }

    const iv = Buffer.from(parts[0], 'base64');
    const authTag = Buffer.from(parts[1], 'base64');
    const encrypted = parts[2];

    const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
    decipher.setAuthTag(authTag);

    let decrypted = decipher.update(encrypted, 'base64', 'utf8');
    decrypted += decipher.final('utf8');

    return decrypted;
  } catch (error) {
    throw new Error(`解密失败: ${error instanceof Error ? error.message : '未知错误'}`);
  }
}

/**
 * 生成随机密钥
 * 用于初始化或密钥轮换
 *
 * @param length - 密钥长度（字节）
 * @returns Base64 编码的随机密钥
 */
export function generateEncryptionKey(length: number = KEY_LENGTH): string {
  return crypto.randomBytes(length).toString('base64');
}

/**
 * 哈希敏感数据（用于索引和查找）
 * 注意：哈希是单向的，不可逆
 *
 * @param data - 要哈希的数据
 * @returns SHA-256 哈希值（十六进制）
 */
export function hashData(data: string): string {
  if (!data) {
    throw new Error('数据不能为空');
  }

  return crypto
    .createHash('sha256')
    .update(data)
    .digest('hex');
}

/**
 * 加密对象（JSON）
 *
 * @param obj - 要加密的对象
 * @returns 加密后的字符串
 */
export function encryptObject<T>(obj: T): string {
  const json = JSON.stringify(obj);
  return encryptData(json);
}

/**
 * 解密对象（JSON）
 *
 * @param ciphertext - 加密后的字符串
 * @returns 解密后的对象
 */
export function decryptObject<T>(ciphertext: string): T {
  const json = decryptData(ciphertext);
  return JSON.parse(json) as T;
}

/**
 * 掩码敏感数据（用于日志）
 *
 * @param data - 敏感数据
 * @param visibleChars - 可见字符数（前后各显示的字符数）
 * @returns 掩码后的数据
 *
 * 示例: maskSensitiveData('1234567890', 2) => '12******90'
 */
export function maskSensitiveData(data: string, visibleChars: number = 4): string {
  if (!data) {
    return '';
  }

  if (data.length <= visibleChars * 2) {
    return '*'.repeat(data.length);
  }

  const start = data.slice(0, visibleChars);
  const end = data.slice(-visibleChars);
  const masked = '*'.repeat(data.length - visibleChars * 2);

  return `${start}${masked}${end}`;
}

/**
 * 验证加密密钥强度
 *
 * @param key - 密钥
 * @returns 是否符合强度要求
 */
export function validateKeyStrength(key: string): boolean {
  // 最小长度 32 字符
  if (key.length < 32) {
    return false;
  }

  // 必须包含大小写字母、数字和特殊字符
  const hasUpperCase = /[A-Z]/.test(key);
  const hasLowerCase = /[a-z]/.test(key);
  const hasNumber = /[0-9]/.test(key);
  const hasSpecial = /[^A-Za-z0-9]/.test(key);

  return hasUpperCase && hasLowerCase && hasNumber && hasSpecial;
}

/**
 * 加密邮箱地址
 * 特殊处理：保留域名用于验证
 *
 * @param email - 邮箱地址
 * @returns 加密后的邮箱
 */
export function encryptEmail(email: string): string {
  if (!email || !email.includes('@')) {
    throw new Error('无效的邮箱地址');
  }

  return encryptData(email);
}

/**
 * 解密邮箱地址
 *
 * @param encryptedEmail - 加密后的邮箱
 * @returns 解密后的邮箱
 */
export function decryptEmail(encryptedEmail: string): string {
  return decryptData(encryptedEmail);
}

/**
 * 加密手机号
 *
 * @param phone - 手机号
 * @returns 加密后的手机号
 */
export function encryptPhone(phone: string): string {
  if (!phone) {
    throw new Error('手机号不能为空');
  }

  return encryptData(phone);
}

/**
 * 解密手机号
 *
 * @param encryptedPhone - 加密后的手机号
 * @returns 解密后的手机号
 */
export function decryptPhone(encryptedPhone: string): string {
  return decryptData(encryptedPhone);
}

/**
 * 密钥轮换辅助函数
 * 使用旧密钥解密，使用新密钥加密
 *
 * @param ciphertext - 使用旧密钥加密的数据
 * @param oldKey - 旧密钥
 * @param newKey - 新密钥
 * @returns 使用新密钥加密的数据
 */
export function rotateEncryption(
  ciphertext: string,
  oldKey: string,
  newKey: string
): string {
  // 临时设置旧密钥
  const originalKey = process.env.ENCRYPTION_KEY;

  try {
    // 使用旧密钥解密
    process.env.ENCRYPTION_KEY = oldKey;
    const plaintext = decryptData(ciphertext);

    // 使用新密钥加密
    process.env.ENCRYPTION_KEY = newKey;
    const newCiphertext = encryptData(plaintext);

    return newCiphertext;
  } finally {
    // 恢复原始密钥
    process.env.ENCRYPTION_KEY = originalKey;
  }
}

/**
 * 安全比较两个字符串（防止时序攻击）
 *
 * @param a - 字符串 A
 * @param b - 字符串 B
 * @returns 是否相等
 */
export function secureCompare(a: string, b: string): boolean {
  if (a.length !== b.length) {
    return false;
  }

  return crypto.timingSafeEqual(
    Buffer.from(a, 'utf8'),
    Buffer.from(b, 'utf8')
  );
}

// 导出类型
export interface EncryptionMetadata {
  keyVersion: number;
  encryptedAt: Date;
  algorithm: string;
}

/**
 * 带元数据的加密
 *
 * @param plaintext - 明文
 * @param keyVersion - 密钥版本
 * @returns 加密数据和元数据
 */
export function encryptWithMetadata(
  plaintext: string,
  keyVersion: number = 1
): { ciphertext: string; metadata: EncryptionMetadata } {
  const ciphertext = encryptData(plaintext);

  const metadata: EncryptionMetadata = {
    keyVersion,
    encryptedAt: new Date(),
    algorithm: ALGORITHM,
  };

  return { ciphertext, metadata };
}

/**
 * 验证加密配置
 * 启动时调用，确保加密系统正常工作
 */
export function validateEncryptionSetup(): void {
  try {
    // 检查环境变量
    const key = process.env.ENCRYPTION_KEY;
    if (!key) {
      throw new Error('ENCRYPTION_KEY 未设置');
    }

    // 检查密钥强度
    if (!validateKeyStrength(key)) {
      throw new Error('ENCRYPTION_KEY 强度不足（需要至少 32 字符，包含大小写字母、数字和特殊字符）');
    }

    // 测试加密/解密
    const testData = 'test-encryption-setup';
    const encrypted = encryptData(testData);
    const decrypted = decryptData(encrypted);

    if (decrypted !== testData) {
      throw new Error('加密/解密测试失败');
    }

    console.log('✓ 加密系统配置正确');
  } catch (error) {
    console.error('✗ 加密系统配置错误:', error);
    throw error;
  }
}
