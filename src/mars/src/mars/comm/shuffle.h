#pragma once
#include <cstdlib>
#include <iterator>
// [invictus-dart local fix -- do not sync back to upstream Tencent/mars]
// The vendored OpenSSL headers were removed; they come from the Dart build
// hooks' output include directory (see src/mars/src/README.md).
#include <openssl/rand.h>
#include <utility>

namespace mars {
namespace comm {
template <class RandomAccessIterator>
void random_shuffle(RandomAccessIterator first, RandomAccessIterator last) {
    typename std::iterator_traits<RandomAccessIterator>::difference_type i, n;
    n = (last - first);
    size_t seed = 0;
    for (i = n - 1; i > 0; --i) {
        RAND_bytes(reinterpret_cast<unsigned char*>(&seed), sizeof(seed));
        std::swap(first[i], first[seed % (i + 1)]);
    }
}

}  // namespace comm
}  // namespace mars
