import CryptoJS from '@ohos/crypto-js'


/**
 * MD5加密
 * @param str 传入的字符串
 * @returns 加密后的字符串
 */
export function encryptMD5(str:string){
  return CryptoJS.MD5(str).toString()

}