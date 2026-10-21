#include <stddef.h>
#include <CommonCrypto/CommonDigest.h>

// OpenSSL 1.x 兼容入口：
// mars 静态库引用了裸 MD5() 符号（OpenSSL 风格），
// 当前 macOS SDK 已移除 libcrypto，此处用 CommonCrypto 实现等价语义。
unsigned char *MD5(const unsigned char *d, size_t n, unsigned char *md)
{
    CC_MD5(d, n, md);
    return md;
}
